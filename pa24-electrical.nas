##
# pa24-250 electrical system.
# Edit of DHC-2 electrical system file using information from 
# PILOT'S OPERATING HANDBOOK AND AIRCRAFT INFORMATION MANUAL
# PA-24-250 COMANCHE
# 2900 POUNDS GROSS WEIGHT
# 1962 THRU 1964
# COPYRIGHT (C) 1990 DOUGLAS L. KILLOUGH
##

# Initialize internal values
#

battery = nil;
alternator = nil;

last_time = 0.0;

vcutoff = 8.0;
vbus_volts = 0.0;
ebus1_volts = 0.0;
ebus2_volts = 0.0;

fuel_pres_ave = 0.0;
oil_pres_ave = 0.0;
ammeter_ave = 0.0;
egt_ave = 0.0;
nose_gear_pos_norm = 0.0;
rudder_position = 0.0;
C = 0.0;
egt = 0.0;
BSW = 0.0;
OnGround = 0.0;

##
# Initialize the electrical system
##

init_electrical = func {
    battery = BatteryClass.new();
    alternator = AlternatorClass.new();

    setprop("/controls/electric/battery-switch", 0);
    setprop("/controls/electric/engine/generator", 0);
    setprop("/controls/engines/engine[0]/fuel-pump",0);
    setprop("/controls/switches/oat-switch", 0);
    setprop("/controls/switches/nav-lights", 0);    
    setprop("/controls/switches/panel-lights-factor", 0);    
    setprop("/controls/switches/landing-light", 0);
    setprop("/controls/switches/flashing-beacon",0);
    setprop("/instrumentation/turn-indicator/serviceable",0);
    setprop("/controls/switches/pitot-heat", 0);
    setprop("/controls/switches/starter", 0);
    setprop("/controls/switches/strobe-lights", 0);
    setprop("/controls/switches/master-avionics", 0);
    setprop("/controls/switches/map-lights",0);
    setprop("/controls/switches/cabin-lights",0);
    setprop("/systems/electrical/outputs/starter[0]", 0.0);
    setprop("/engines/engine/fuel-pressure-psi", 0.0);
    setprop("/engines/engine/oil-pressure-psi", 0.0);
    setprop("/systems/electrical/amps", 0.0);
    setprop("/systems/electrical/volts", 0.0);
    setprop("/systems/electrical/outputs/cabin-lights", 0.0);
    setprop("/systems/electrical/outputs/instr-ignition-switch", 0.0);
    setprop("/systems/electrical/outputs/fuel-pump", 0.0);
    setprop("/systems/electrical/outputs/landing-light", 0.0);
    setprop("/controls/lighting/landing-lights", 0);
    setprop("/systems/electrical/outputs/flashing-beacon", 0.0 );
    setprop("/controls/lighting/beacon", 0);
    setprop("/systems/electrical/outputs/strobe-lights", 0.0 );
    setprop("/controls/lighting/beacon", 0);
    setprop("/systems/electrical/outputs/flaps", 0.0);
    setprop("/systems/electrical/outputs/turn-coordinator", 0.0);
    setprop("/systems/electrical/outputs/nav-lights", 0.0);      
    setprop("/controls/lighting/nav-lights", 0);
    setprop("/systems/electrical/outputs/instrument-lights", 0.0);      
    setprop("/systems/electrical/outputs/pitot-heat", 0.0);
    setprop("/systems/electrical/outputs/landing-gear", 0.0);
    setprop("/systems/electrical/outputs/nav[0]", 0.0);
    setprop("/systems/electrical/outputs/comm[0]", 0.0);
    setprop("/systems/electrical/outputs/dme", 0.0);
    setprop("/systems/electrical/outputs/nav[1]", 0.0);
    setprop("/systems/electrical/outputs/comm[1]", 0.0);
    setprop("/systems/electrical/outputs/transponder", 0.0);
    setprop("/systems/electrical/outputs/autopilot", 0.0);
    setprop("/systems/electrical/outputs/adf", 0.0);
  
    setprop("/gear/gear[0]/theta0", 0.0);
    setprop("/gear/gear[1]/theta1", 0.0);
    setprop("/gear/gear[2]/theta2", 0.0);
    setprop("/gear/gear[0]/compression-m", 0.0); #Cheat since this was still nil after fdm-initialize
    setprop("/gear/gear[1]/compression-m", 0.0); #Cheat since this was still nil after fdm-initialize
    setprop("/gear/gear[2]/compression-m", 0.0); #Cheat since this was still nil after fdm-initialize
    setprop("engines/engine[0]/fuel-flow-gph", 0.0);
    setprop("/surface-positions/flap-pos-norm", 0.0);
    setprop("/instrumentation/airspeed-indicator/indicated-speed-kt", 0.0);

    setprop("/gear/gear[0]/position-norm", 0);   #Cheat since this was still nil after fdm-initialize
    setprop("/instrumentation/airspeed-indicator/pressure-alt-offset-deg", 0.0);
    setprop("/accelerations/pilot-g", 1.0);
    print("Nasal Electrical System Initialized");  

    # Request that the update fuction be called next frame
    settimer(update_electrical, 0);
}

BatteryClass = {};

BatteryClass.new = func {
    obj = { parents : [BatteryClass],
            ideal_volts : 12.0,
            ideal_amps : 35.0,
            amp_hours : 12.75,
            charge_percent : 1.0,
            charge_amps : 7.0 };
    return obj;
}


BatteryClass.apply_load = func( amps, dt ) {
    amphrs_used = amps * dt / 3600.0;
    percent_used = amphrs_used / me.amp_hours;
    me.charge_percent -= percent_used;
    if ( me.charge_percent < 0.0 ) {
        me.charge_percent = 0.0;
    } elsif ( me.charge_percent > 1.0 ) {
        me.charge_percent = 1.0;
    }
    # print( "battery percent = ", me.charge_percent);
    return me.amp_hours * me.charge_percent;
}


BatteryClass.get_output_volts = func {
    x = 1.0 - me.charge_percent;
    tmp = -(3.0 * x - 1.0);
    factor = (tmp*tmp*tmp*tmp*tmp + 32) / 32;
    return me.ideal_volts * factor;
}


BatteryClass.get_output_amps = func {
    x = 1.0 - me.charge_percent;
    tmp = -(3.0 * x - 1.0);
    factor = (tmp*tmp*tmp*tmp*tmp + 32) / 32;
    return me.ideal_amps * factor;
}


AlternatorClass = {};

AlternatorClass.new = func {
    obj = { parents : [AlternatorClass],
            rpm_source : "/engines/engine[0]/rpm",
            rpm_threshold : 600.0,
            ideal_volts : 14.0,
            ideal_amps : 50.0 };
    setprop( obj.rpm_source, 0.0 );
    return obj;
}


AlternatorClass.apply_load = func( amps, dt ) {
    # Scale alternator output for rpms < 600.  For rpms >= 600
    # give full output.  This is just a WAG, and probably not how
    # it really works but I'm keeping things "simple" to start.
    rpm = getprop( me.rpm_source );
    factor = rpm / me.rpm_threshold;
    if ( factor > 1.0 ) {
        factor = 1.0;
    }
    # print( "alternator amps = ", me.ideal_amps * factor );
    available_amps = me.ideal_amps * factor;
    return available_amps - amps;
}


AlternatorClass.get_output_volts = func {
    # scale alternator output for rpms < 600.  For rpms >= 600
    # give full output.  This is just a WAG, and probably not how
    # it really works but I'm keeping things "simple" to start.
    rpm = getprop( me.rpm_source );
    factor = rpm / me.rpm_threshold;
    if ( factor > 1.0 ) {
        factor = 1.0;
    }
    # print( "alternator volts = ", me.ideal_volts * factor );
    return me.ideal_volts * factor;
}


AlternatorClass.get_output_amps = func {
    # scale alternator output for rpms < 600.  For rpms >= 600
    # give full output.  This is just a WAG, and probably not how
    # it really works but I'm keeping things "simple" to start.
    rpm = getprop( me.rpm_source );
    factor = rpm / me.rpm_threshold;
    if ( factor > 1.0 ) {
        factor = 1.0;
    }
    # print( "alternator amps = ", ideal_amps * factor );
    return me.ideal_amps * factor;
}


update_electrical = func {
    time = getprop("/sim/time/elapsed-sec");
    dt = time - last_time;
    last_time = time;

    update_virtual_bus( dt );

    # Request that the update fuction be called again next frame
    settimer(update_electrical, 0);
}



update_virtual_bus = func( dt ) {
    battery_volts = battery.get_output_volts();
    alternator_volts = alternator.get_output_volts();
    external_volts = 0.0;
    load = 0.0;
    fuel_pres = 0.0;
    oil_pres = 0.0;

    # switch state
    master_bat = getprop("/controls/electric/battery-switch");
#
# Comanche has only one master switch which connects both the battery 
# and the alternator via a voltage regulator to the bus.
#
    if ( master_bat ) {
        setprop("/controls/electric/engine/generator",1);
    }

    master_alt = master_bat;

    # determine power source
    bus_volts = 0.0;
    power_source = nil;
    if ( master_bat ) {
        bus_volts = battery_volts;
        power_source = "battery";
    }

    if ( master_alt and (alternator_volts > bus_volts) ) {
        bus_volts = alternator_volts;
        power_source = "alternator";
    }

    if ( external_volts > bus_volts ) {
        bus_volts = external_volts;
        power_source = "external";
    }
    # print( "virtual bus volts = ", bus_volts );

    # starter motor
    starter_switch = getprop("/controls/switches/starter");
    starter_volts = 0.0;
    if ( starter_switch ) {
        starter_volts = bus_volts;
        load += 12;
    }
    setprop("/systems/electrical/outputs/starter[0]", starter_volts);
    if (starter_volts > vcutoff) {
    setprop("/controls/engines/engine[0]/starter",1);
    setprop("/controls/engines/engine[0]/magnetos",3);
    } else {
    setprop("/controls/engines/engine[0]/starter",0);
    }

    # bus network (1. these must be called in the right order, 2. the
    # bus routine itself determines where it draws power from.)
    load += electrical_bus_1();
    load += electrical_bus_2();
    load += cross_feed_bus();
    load += avionics_bus_1();
    load += avionics_bus_2();

    # system loads and ammeter gauge
    ammeter = 0.0;
    if ( bus_volts > 1.0 ) {
        # normal load
        load += 15.0;

        # ammeter gauge
        if ( power_source == "battery" ) {
            ammeter = -load;
        } else {
            ammeter = battery.charge_amps;
        }
    }
    # print( "ammeter = ", ammeter );

    # charge/discharge the battery
    if ( power_source == "battery" ) {
        battery.apply_load( load, dt );
    } elsif ( bus_volts > battery_volts ) {
        battery.apply_load( -battery.charge_amps, dt );
    }

    # filter ammeter needle pos
    ammeter_ave = 0.8 * ammeter_ave + 0.2 * ammeter;

##
#  This is a convenient cludge to model fuel pressure and oil pressure
##
    rpm = getprop("/engines/engine/rpm");
    if (rpm > 600.0) {
    fuel_pres = 3.2;
    oil_pres = 41.5;
    }
    if (getprop("/controls/engines/engine/fuel-pump")) {
    fuel_pres += 3.1;
    }
    # filter both presures
    fuel_pres_ave = 0.8 * fuel_pres_ave + 0.2 * fuel_pres;
    oil_pres_ave = 0.8 * oil_pres_ave + 0.2 * oil_pres;
# print( " rpm = ", rpm, " fuel pres = ", fuel_pres_ave, " oil pres = ", oil_pres_ave ); 

##
#  Save a factor used to make the prop disc disapear as rpm increases
##
    factor = 1.0 - rpm/2400;
    if ( factor < 0.0 ) {
        factor = 0.0;
    }

##
#  Stall Warning
##
    ias = getprop("/instrumentation/airspeed-indicator/indicated-speed-kt");
    flaps = getprop("/surface-positions/flap-pos-norm");
    gforce = getprop("/accelerations/pilot-g");
#    print("ias = ", ias, "  flaps = ", flaps);
#  pa24-250 Vs = 65 knots,  warn at 67
    stall = 65 - 7*flaps + 20*(gforce - 1.0);

    BSW = getprop("/controls/electric/battery-switch");
    OnGround = ( getprop("/gear/gear[0]/wow") );

    node = props.globals.getNode("/sim/alarms/stall-warning",1);
                      
    if ( BSW and ( ias < stall ) and !OnGround ) {
      node.setBoolValue(1);
    } else {
      node.setBoolValue(0);
    }
   
##
#  Simulate egt from pilot's perspective using fuel flow and rpm
##
    fuel_flow = getprop("engines/engine[0]/fuel-flow-gph");
    egt = 325 - abs(fuel_flow - 12)*20;
    if (egt < 20) {egt = 20; }
    egt = egt*(rpm/2400)*(rpm/2400);
#   Smooth and add some lag
    egt_ave = 0.995*egt_ave + 0.005*egt;
##
#  Are we on the ground?  If yes, compute the scissor link angles due to strut compression
##

    theta0 = 0.0;
    theta1 = 0.0;
    theta2 = 0.0;

    # Compute the angle the nose gear scissor rotates due to nose gear strut compression

    H = 0.205048;  # Nose gear oleo strut extended length in m
    L = 0.107564;  # Nose gear scissor length in m
    phi = 1.2673;
    C = getprop("gear/gear[0]/compression-m");
    if (C > 0.0) {
      theta0 = scissor_angle(H,C,L,phi);
    }
    setprop("/gear/gear[0]/theta0", theta0);

    # Compute the angle the right gear scissor rotates due to right gear strut compression
      
    H = 0.205048;  # Right gear oleo strut extended length in m
    L = 0.107564;  # Right gear scissor length in m
    phi = 1.2673;
    C = getprop("gear/gear[1]/compression-m");
    if (C > 0.0) {
      theta1 = scissor_angle(H,C,L,phi);
    }
    setprop("/gear/gear[1]/theta1", theta1);

    # Compute the angle the left gear scissor rotates due to left gear strut compression

    H = 0.205048;  # Left gear oleo strut extended length in m
    L = 0.107564;  # Left gear scissor length in m
    phi = 1.2673;
    C = getprop("gear/gear[2]/compression-m");
    if (C > 0.0) {
      theta2 = scissor_angle(H,C,L,phi);
    }
    setprop("/gear/gear[2]/theta2", theta2);

##
#  Disengage nose wheel steering from the rudder pedals if not locked down
##
#    nose_gear_pos_norm = getprop("gear/gear[0]/position-norm");

    if ( getprop("gear/gear[0]/position-norm") < 1) {
        rudder_position = 0.0;
    } else {
        rudder_position = getprop("surface-positions/rudder-pos-norm");
    }

    # outputs

    setprop("/engines/engine[0]/egt-degf-fix", egt_ave);
    setprop("/gear/gear[0]/turn-pos-norm", rudder_position);
    setprop("/sim/models/materials/propdisc/factor", factor);  
    setprop("/engines/engine/fuel-pressure-psi", fuel_pres_ave);
    setprop("/engines/engine/oil-pressure-psi", oil_pres_ave);
    setprop("/systems/electrical/amps", ammeter_ave);
    setprop("/systems/electrical/volts", bus_volts);
    vbus_volts = bus_volts;

    return load;
}

scissor_angle = func(H,C,L,phi) {
    a = (H - C)/2/L;
    # Use 2 iterates of Newton's method and 4th order Taylor series to 
    # approximate theta where sin(phi - theta) = a
    theta = phi - 2*a/3 - a/3/(1-a*a/2);
    return theta;
}

electrical_bus_1 = func() {
    # we are fed from the "virtual" bus
    bus_volts = vbus_volts;
    load = 0.0;
    
    # Cabin Lights Power
    if ( getprop("/controls/switches/cabin-lights") ) {
        setprop("/systems/electrical/outputs/cabin-lights", bus_volts);
    } else {
        setprop("/systems/electrical/outputs/cabin-lights", 0.0);
    }
    if ( getprop("/systems/electrical/outputs/cabin-lights") > vcutoff)
    {
        setprop("/controls/lighting/cabin-lights", 1);
        load += 0.2;
    } else {
        setprop("/controls/lighting/cabin-lights", 0);
    }

   # Map Lights Power
    if ( getprop("/controls/switches/map-lights") ) {
        setprop("/systems/electrical/outputs/map-lights", bus_volts);
    } else {
        setprop("/systems/electrical/outputs/map-lights", 0.0);
    }
    if ( getprop("/systems/electrical/outputs/map-lights") > vcutoff)
    {
        setprop("/controls/lighting/map-lights", 1);
        load += 0.2;
    } else {
        setprop("/controls/lighting/map-lights", 0);
    }
    # Instrument Power
    setprop("/systems/electrical/outputs/instr-ignition-switch", bus_volts);
    if (bus_volts > vcutoff) {
    load += 0.3;
    }

    # Fuel Pump Power
    if ( getprop("/controls/engines/engine[0]/fuel-pump") ) {
        setprop("/systems/electrical/outputs/fuel-pump", bus_volts);
        load += 0.1;
    } else {
        setprop("/systems/electrical/outputs/fuel-pump", 0.0);
    }

    # Landing Light Power
    if ( getprop("/controls/switches/landing-light") ) {
        setprop("/systems/electrical/outputs/landing-light", bus_volts);
    } else {
        setprop("/systems/electrical/outputs/landing-light", 0.0 );
    }
    if ( getprop("/systems/electrical/outputs/landing-light") > vcutoff)
    {
        setprop("/controls/lighting/landing-lights", 1);
        load += 3.2;
    } else {
        setprop("/controls/lighting/landing-lights", 0);
    }
    # Flashing Beacon Power
    if ( getprop("/controls/switches/flashing-beacon") ) {
        setprop("/systems/electrical/outputs/flashing-beacon", bus_volts);
    } else {
        setprop("/systems/electrical/outputs/flashing-beacon", 0.0 );
    }
    if ( getprop("/systems/electrical/outputs/flashing-beacon") > vcutoff )
    {
        setprop("/controls/lighting/beacon", 1);
        load += 1.2;
    } else {
        setprop("/controls/lighting/beacon", 0);
    }

    # Strobe Power
    if ( getprop("/controls/switches/strobe-lights") ) {
        setprop("/systems/electrical/outputs/strobe-lights", bus_volts);
    } else {
        setprop("/systems/electrical/outputs/strobe-lights", 0.0 );
    }
    if ( getprop("/systems/electrical/outputs/strobe-lights") > vcutoff ) 
    {
        setprop("/controls/lighting/strobe", 1);
        load += 1.2;
    } else {
        setprop("/controls/lighting/strobe", 0);
    }


    # Flaps Power
    setprop("/systems/electrical/outputs/flaps", bus_volts);

    # register bus voltage
    ebus1_volts = bus_volts;

    # return cumulative load
    return load;
}


electrical_bus_2 = func() {
    # we are fed from the "virtual" bus
    bus_volts = vbus_volts;
    load = 0.0;

    # Turn Coordinator Power
    setprop("/systems/electrical/outputs/turn-coordinator", bus_volts);
  
    # Nav Lights Power
    if ( getprop("/controls/switches/nav-lights" ) ) {
        setprop("/systems/electrical/outputs/nav-lights", bus_volts);
    } else {
        setprop("/systems/electrical/outputs/nav-lights", 0.0);      
    }

    if ( getprop("/systems/electrical/outputs/nav-lights") > vcutoff ) 
    {
        setprop("/controls/lighting/nav-lights", 1);
        load += 1.4;
    } else {
        setprop("/controls/lighting/nav-lights", 0);
    }

    # Instrument Lights Power controlled by nav-lights switch on pa24
    factor = getprop("/controls/switches/panel-lights-factor" );
    if ( getprop("/controls/switches/nav-lights" ) ) {
       setprop("/systems/electrical/outputs/instrument-lights", bus_volts);
       # Normalize factor by 1/14 = 0.071428571 for max bus_volts
       setprop("/sim/model/material/instruments/factor", bus_volts * 0.071428571 * (1.0 - factor));
       setprop("/controls/lighting/panel-norm", bus_volts * 0.071428571 * (1.0 - factor));
    } else {
       setprop("/systems/electrical/outputs/instrument-lights", 0.0);
       setprop("/sim/model/material/instruments/factor", 0.0);
       setprop("/controls/lighting/panel-norm", 0.0);
    }




    # Pitot Heat Power
    if ( getprop("/controls/anti-ice/pitot-heat" ) ) {
        setprop("/systems/electrical/outputs/pitot-heat", bus_volts);
        if (bus_volts > vcutoff) {load += 12.8; }
    } else {
        setprop("/systems/electrical/outputs/pitot-heat", 0.0);
    }
  
    # Landing Gear Power
    setprop("/systems/electrical/outputs/landing-gear", bus_volts);

    # register bus voltage
    ebus2_volts = bus_volts;

    # return cumulative load
    return load;
}


cross_feed_bus = func() {
    # we are fed from either of the electrical bus 1 or 2
    if ( ebus1_volts > ebus2_volts ) {
        bus_volts = ebus1_volts;
    } else {
        bus_volts = ebus2_volts;
    }

    load = 0.0;

    setprop("/systems/electrical/outputs/annunciators", bus_volts);

    # return cumulative load
    return load;
}


avionics_bus_1 = func() {
    master_av = getprop("/controls/switches/master-avionics");
    if (master_av){
    bus_volts = ebus1_volts;
    } else {
    bus_volts = 0.0;
    }
   load = 0.0;

    # Nav 1 Power
    setprop("/systems/electrical/outputs/nav[0]", bus_volts);
        if (bus_volts > vcutoff) {load += 0.8; }
    # Com 1 Power
    setprop("/systems/electrical/outputs/comm[0]", bus_volts);
        if (bus_volts > vcutoff) {load += 0.8; }
    # DME
    setprop("/systems/electrical/outputs/dme", bus_volts);
        if (bus_volts > vcutoff) {load += 0.6; }
    # return cumulative load
    return load;
}


avionics_bus_2 = func() {
    master_av = getprop("/controls/switches/master-avionics");
    if (master_av){
    bus_volts = ebus2_volts;
    } else {
    bus_volts = 0.0;
    }
    load = 0.0;

    # Nav 2 Power
    setprop("/systems/electrical/outputs/nav[1]", bus_volts);
        if (bus_volts > vcutoff) {load += 0.8; }
    # Com 2 Power
    setprop("/systems/electrical/outputs/comm[1]", bus_volts);
        if (bus_volts > vcutoff) {load += 0.8; }


    # Transponder Power
    setprop("/systems/electrical/outputs/transponder", bus_volts);
        if (bus_volts > vcutoff) {load += 0.6; }

    # Autopilot Power
    setprop("/systems/electrical/outputs/autopilot", bus_volts);
        if (bus_volts > vcutoff) {load += 0.8; }

    # ADF Power
    setprop("/systems/electrical/outputs/adf", bus_volts);
        if (bus_volts > vcutoff) {load += 0.8; }

    # return cumulative load
    return load;
}


# Setup listener call to initialize the electrical system once the fdm is initialized
# 
setlistener("/sim/signals/fdm-initialized", init_electrical);  


