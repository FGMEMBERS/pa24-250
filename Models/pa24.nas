fswitch = nil;
INIT = func {
    fswitch = props.globals.getNode("/controls[1]/fuel/switch-position");
}

fuel_switch = func {
node = props.globals.getNode("/consumables/fuel/tank[0]/selected",0);
node.setBoolValue(0);
node = props.globals.getNode("/consumables/fuel/tank[1]/selected",0);
node.setBoolValue(0);
node = props.globals.getNode("/consumables/fuel/tank[2]/selected",0);
node.setBoolValue(0);
node = props.globals.getNode("/consumables/fuel/tank[3]/selected",0);
node.setBoolValue(0);

val = getprop("/controls[1]/fuel/switch-position");
      test = 1 + val;
      if(test > 4){test=0};
setprop("/controls[1]/fuel/switch-position",test);
if(test == 1){
node = props.globals.getNode("/consumables/fuel/tank[0]/selected",0);
node.setBoolValue(1);
if(getprop("/consumables/fuel/tank[0]/level-gal_us")>0.01){
node = props.globals.getNode("/engines/engine/out-of-fuel",1);
node.setBoolValue(0);} 
 }
if(test == 2){
node = props.globals.getNode("/consumables/fuel/tank[1]/selected",0);
node.setBoolValue(1);
if(getprop("/consumables/fuel/tank[1]/level-gal_us")>0.01){
node = props.globals.getNode("/engines/engine/out-of-fuel",1);
node.setBoolValue(0);} 
 }
if(test == 3){
node = props.globals.getNode("/consumables/fuel/tank[2]/selected",0);
node.setBoolValue(1);
if(getprop("/consumables/fuel/tank[2]/level-gal_us")>0.01){
node = props.globals.getNode("/engines/engine/out-of-fuel",1);
node.setBoolValue(0);} 
 }
if(test == 4){
node = props.globals.getNode("/consumables/fuel/tank[3]/selected",0);
node.setBoolValue(1);
if(getprop("/consumables/fuel/tank[3]/level-gal_us")>0.01){
node = props.globals.getNode("/engines/engine/out-of-fuel",1);
node.setBoolValue(0);} 
 }
}

master_switch = func {
toggle=getprop("/controls/electric/battery-switch");
toggle=1-toggle;
setprop("/controls/electric/battery-switch",toggle);
}

f_pump_switch = func {
toggle=getprop("/controls/engines/engine/fuel-pump");
toggle=1-toggle;
setprop("/controls/engines/engine/fuel-pump",toggle);
}

nav_light_switch = func {
toggle=getprop("/controls/switches/nav-lights");
toggle=1-toggle;
setprop("/controls/switches/nav-lights",toggle);
}

landing_light_switch = func {
toggle=getprop("/controls/switches/landing-light");
toggle=1-toggle;
setprop("/controls/switches/landing-light",toggle);
}

turn_bank_switch = func {
toggle = getprop("/instrumentation/turn-indicator/serviceable");
toggle=1-toggle;
setprop("/instrumentation/turn-indicator/serviceable",toggle);
}

rot_beacon_switch = func {
toggle=getprop("/controls/switches/flashing-beacon");
toggle=1-toggle;
setprop("/controls/switches/flashing-beacon",toggle);
}

pitot_heat_switch = func {
toggle=getprop("/controls/anti-ice/pitot-heat");
toggle=1-toggle;
setprop("/controls/anti-ice/pitot-heat",toggle);
}

strobe_light_switch = func {
toggle=getprop("/controls/switches/strobe-lights");
toggle=1-toggle;
setprop("/controls/switches/strobe-lights",toggle);
}

avionics_master_switch = func {
toggle=getprop("/controls/switches/master-avionics");
toggle=1-toggle;
setprop("/controls/switches/master-avionics",toggle);
}

carb_heat = func {
toggle=getprop("/controls/anti-ice/engine/carb-heat");
toggle=1-toggle;
setprop("/controls/anti-ice/engine/carb-heat",toggle);
}

primer = func {
toggle=getprop("/controls/engines/engine/primer-pump");
toggle=1-toggle;
setprop("/controls/engines/engine/primer-pump",toggle);
}

##
#  Substitute controls.flapsDown taken from b29.nas.  Gives smooth flap motion
#  as long as the flap switch is closed.
##

controls.flapsDown = func {
    setprop("/controls/switches/flaps", arg[0]);
#    print("arg[0] = ", arg[0]);
    if(getprop("/systems/electrical/outputs/flaps") < 8.0) { return; }
    if (arg[0] == 1) {
        if ( getprop('/controls/flight/flaps') < 1 ) {
            interpolate('/controls/flight/flaps', 1, (5*(1-getprop('/controls/flight/flaps'))));
        # } else {
            # check for motor burnout
        }
    } elsif (arg[0] == -1) {
        if ( getprop('/controls/flight/flaps') > 0 ) {
            interpolate('/controls/flight/flaps', 0, (5*getprop('/controls/flight/flaps')));
        # } else {
            # check for motor burnout
        }
    } else {
        interpolate('/controls/flight/flaps');
    }
}

controls.gearDown = func {
    if(getprop("/systems/electrical/outputs/landing-gear") < 8.0) {return; }
    if (arg[0] < 0) {
      setprop("/controls/gear/gear-down", 0);
    } elsif (arg[0] > 0) {
      setprop("/controls/gear/gear-down", 1);
    }
}
