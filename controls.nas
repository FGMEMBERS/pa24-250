##
# Wrapper around stepProps() which emulates the "old" flap behavior for
# configurations that aren't using the new mechanism.

flapsDown = func {
    setprop("/controls/switches/flaps", arg[0]);
#    print("arg[0] = ", arg[0]);
    if((arg[0] == 0) or (getprop("/systems/electrical/outputs/flaps") < 8.0)) { return; }
    if(props.globals.getNode("/sim/flaps") != nil) {
        stepProps("/controls/flight/flaps", "/sim/flaps", arg[0]);
        return;
    }
    # Hard-coded flaps movement in 3 equal steps:
    val = 0.3333334 * arg[0] + getprop("/controls/flight/flaps");
    if(val > 1) { val = 1 } elsif(val < 0) { val = 0 }
    setprop("/controls/flight/flaps", val);
}

FlapsDown = func {
    setprop("/controls/switches/flaps", arg[0]);
    if((arg[0] == 0) or (getprop("/systems/electrical/outputs/flaps") < 8.0)) { return; }
    val = 0.03125 * arg[0] + getprop("/controls/flight/flaps");
    # step in 1 deg incriments while flap switch is closed
    if(val > 1) { val = 1 } elsif(val < 0) { val = 0 }
    setprop("/controls/flight/flaps", val);
}

gearDown = func {
    if(getprop("/systems/electrical/outputs/landing-gear") < 8.0) {return; }
    if (arg[0] < 0) {
      setprop("/controls/gear/gear-down", 0);
    } elsif (arg[0] > 0) {
      setprop("/controls/gear/gear-down", 1);
    }
}
