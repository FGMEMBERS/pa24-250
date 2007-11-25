##
#  action-sim.nas   Updates various simulated features including:
#                    egt, fuel pressure, oil pressure, prop visibility, 
#                    stall warning, gear scissors angles, etc. every frame
##

#   Initialize local variables
var rpm = nil;
var fuel_pres = 0.0;
var oil_pres = 0.0;
var fuel_pres_ave = 0.0;
var oil_pres_ave = 0.0;
var factor = nil;
var ias = nil;
var flaps = nil;
var gforce = nil;
var stall = nil;
var bsw = nil;
var node = nil;
var OnGround = nil;
var fuel_flow = nil;
var egt = nil;
var egt_ave = 0.0;
var H = nil;
var L = nil;
var phi = nil;
var C = nil;
var rudder_position = nil;

var init_actions = func {
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

    # Request that the update fuction be called next frame
    settimer(update_actions, 0);
}


var update_actions = func {
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
#  Compute the scissor link angles due to strut compression
##

    var theta0 = 0.0;
    var theta1 = 0.0;
    var theta2 = 0.0;

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

    settimer(update_actions, 0);
}

var scissor_angle = func(H,C,L,phi) {
    var a = (H - C)/2/L;
    # Use 2 iterates of Newton's method and 4th order Taylor series to 
    # approximate theta where sin(phi - theta) = a
    var theta = phi - 2*a/3 - a/3/(1-a*a/2);
    return theta;
}

# Setup listener call to start update loop once the fdm is initialized
# 
setlistener("/sim/signals/fdm-initialized", init_actions);  



