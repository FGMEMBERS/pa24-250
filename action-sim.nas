##
#  action-sim.nas   Updates various simulated features including:
#                    egt, fuel pressure, oil pressure, prop visibility, 
#                    stall warning, gear scissors angles, etc. every frame
##

#   Initialize local variables
var rpm = nil;
var fuel_pres = 0.0;
var oil_pres = 0.0;
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
var H = nil;
var L = nil;
var phi = nil;
var C = nil;
var rudder_position = nil;
var fuel_pump_volume = nil;
var aileron = nil;
var elevator = nil;

# set up filters for these actions

var fuel_pres_lowpass = aircraft.lowpass.new(0.5);
var oil_pres_lowpass = aircraft.lowpass.new(0.5);
var egt_lowpass = aircraft.lowpass.new(0.95);
var cdi0_lowpass = aircraft.lowpass.new(0.5);
var cdi1_lowpass = aircraft.lowpass.new(0.5);
var gs0_lowpass = aircraft.lowpass.new(0.5);
var gs1_lowpass = aircraft.lowpass.new(0.5);

# Properties

var propGear0 = props.globals.getNode("gear/gear[0]", 1);
var propGear1 = props.globals.getNode("gear/gear[1]", 1);
var propGear2 = props.globals.getNode("gear/gear[2]", 1);
var propLandingLights = props.globals.getNode("sim/model/material/LandingLight", 1);
var propFlightControls = props.globals.getNode("controls/flight", 1);
var propEngine = props.globals.getNode("engines/engine[0]", 1);
var propNav0 = props.globals.getNode("instrumentation/nav[0]", 1);
var propNav1 = props.globals.getNode("instrumentation/nav[1]", 1);
var propAirspeedIndicator = props.globals.getNode("instrumentation/airspeed-indicator", 1);
var propSurfacePositions = props.globals.getNode("surface-positions", 1);
var propCentury2bControls = props.globals.getNode("autopilot/CENTURYIIB/controls", 1);
var propCentury3Controls = props.globals.getNode("autopilot/CENTURYIII/controls", 1);

# Associate Nodes

var theta0N = propGear0.getNode("theta0", 1);
var theta1N = propGear1.getNode("theta1", 1);
var theta2N = propGear2.getNode("theta2", 1);
var gear0Compression = propGear0.getNode("compression-m", 1);
var gear1Compression = propGear1.getNode("compression-m", 1);
var gear2Compression = propGear2.getNode("compression-m", 1);
var leftLandingLightFactor = propLandingLights.getNode("factor-L", 1);
var rightLandingLightFactor = propLandingLights.getNode("factor-R", 1);
var leftLandingLightFactorAGL  = propLandingLights.getNode("factorAGL-L", 1);
var rightLandingLightFactorAGL = propLandingLights.getNode("factorAGL-R", 1);
var fuelFlowGph = propEngine.getNode("fuel-flow-gph", 1);
var fuelPressure = propEngine.getNode("fuel-pressure-psi", 1);
var oilPressure = propEngine.getNode("oil-pressure-psi", 1);
var engineRPM = propEngine.getNode("rpm", 1);
var fixEGT = propEngine.getNode("egt-degf-fix", 1);
var flapPosition = propSurfacePositions.getNode("flap-pos-norm", 1);
var rudderPosition = propSurfacePositions.getNode("rudder-pos-norm", 1);
var indicatedAirSpeedKnots = propAirspeedIndicator.getNode("indicated-speed-kt", 1);
var noseGearPosition = propGear0.getNode("position-norm", 1);
var noseGearTurnPosition = propGear0.getNode("turn-pos-norm", 1);
var presssureAltOffsetDeg = propAirspeedIndicator.getNode("pressure-alt-offset-deg", 1);
var pilotGs = props.globals.getNode("accelerations/pilot-g", 1);
var aileronAP  = propFlightControls.getNode("AP_aileron", 1);
var elevatorAP = propFlightControls.getNode("AP_elevator", 1);
var aileronIN = propFlightControls.getNode("aileron_in", 1);
var elevatorIN = propFlightControls.getNode("elevator_in", 1);
var aileronJS = propFlightControls.getNode("aileron", 1);
var elevatorJS = propFlightControls.getNode("elevator", 1);
var pitchC3 = propCentury3Controls.getNode("pitch", 1);
var rollC3  = propCentury3Controls.getNode("roll", 1);
var rollC2b = propCentury2bControls.getNode("roll", 1);
var cdiNAV0 = propNav0.getNode("heading-needle-deflection", 1);
var cdiNAV1 = propNav1.getNode("heading-needle-deflection", 1);
var gsNAV0  = propNav0.getNode("gs-needle-deflection-norm", 1);
var gsNAV1  = propNav1.getNode("gs-needle-deflection-norm", 1);
var filteredCDI0 = propNav0.getNode("filtered-cdiNAV0-deflection", 1);
var filteredCDI1 = propNav1.getNode("filtered-cdiNAV1-deflection", 1);
var filteredGS0  = propNav0.getNode("filtered-gsNAV0-deflection", 1);
var filteredGS1  = propNav1.getNode("filtered-gsNAV1-deflection", 1);
var batterySwitch = props.globals.getNode("controls/electric/battery-switch", 1);
var noseGearWow = propGear0.getNode("wow", 1);
var aglFt = props.globals.getNode("position/altitude-agl-ft", 1);
var propDiskFactor = props.globals.getNode("sim/model/material/propdisc/factor", 1);
var fuelPump = props.globals.getNode("controls/engines/engine/fuel-pump", 1);
var fuelPumpVolume = props.globals.getNode("sim/sound/fuel_pump_volume", 1);


var init_actions = func {
    theta0N.setDoubleValue(0.0);
    theta1N.setDoubleValue(0.0);
    theta2N.setDoubleValue(0.0);
    gear0Compression.setDoubleValue(0.0);
    gear1Compression.setDoubleValue(0.0);
    gear2Compression.setDoubleValue(0.0);
    leftLandingLightFactor.setDoubleValue(0.0);
    rightLandingLightFactor.setDoubleValue(0.0);
    fuelFlowGph.setDoubleValue(0.0);
    flapPosition.setDoubleValue(0.0);
    indicatedAirSpeedKnots.setDoubleValue(0.0);
    noseGearPosition.setDoubleValue(0.0);
    presssureAltOffsetDeg.setDoubleValue(0.0);
    pilotGs.setDoubleValue(0.0);
    aileronIN.setDoubleValue(0.0);
    elevatorIN.setDoubleValue(0.0);
    filteredCDI0.setDoubleValue(0.0);
    filteredCDI1.setDoubleValue(0.0);
    filteredGS0.setDoubleValue(0.0);
    filteredGS1.setDoubleValue(0.0);

    # Request that the update fuction be called next frame
    settimer(update_actions, 0);
}


var update_actions = func {
##
#  This is a convenient cludge to model fuel pressure and oil pressure
##
    rpm = engineRPM.getValue();
    if (rpm > 600.0) {
       fuel_pres = 6.8-3000/rpm;
       oil_pres = 62-12600/rpm;
    } else {
       fuel_pres = 0.0;
       oil_pres = 0.0;
    }

    if ( fuelPump.getValue() ) {
    fuel_pres += 1.5;
    }

##
#  reduce fuel pump sound volume as rpm increases
##
   if (rpm < 1200) {
     fuel_pump_volume = 0.3/(0.002*rpm+1)
   } else {
     fuel_pump_volume = 0.0
   }

##
#  Save a factor used to make the prop disc disapear as rpm increases
##
    factor = 1.0 - rpm/2750;
    if ( factor < 0.0 ) {
        factor = 0.0;
    }

##
#  Stall Warning
##
    ias = indicatedAirSpeedKnots.getValue();
    flaps = flapPosition.getValue();
    gforce = pilotGs.getValue();
#  pa24-250 Vs = 65 knots,  warn at 67
    stall = 65 - 7*flaps + 20*(gforce - 1.0);

    BSW = batterySwitch.getValue();
    OnGround = ( noseGearWow.getValue() );

    node = props.globals.getNode("sim/alarms/stall-warning",1);
                      
    if ( BSW and ( ias < stall ) and !OnGround ) {
      node.setBoolValue(1);
    } else {
      node.setBoolValue(0);
    }
   
##
#  Simulate egt from pilot's perspective using fuel flow and rpm
##
    fuel_flow = fuelFlowGph.getValue();
    egt = 325 - abs(fuel_flow - 12)*20;
    if (egt < 20) {egt = 20; }
    egt = egt*(rpm/2400)*(rpm/2400);

##
#  Simulate landing light ground illumination fall-off with increased agl distance
##
    var factorL = leftLandingLightFactor.getValue();
    var factorR = rightLandingLightFactor.getValue();
    var agl = aglFt.getValue();
    var aglFactor = 16/(agl*agl);
    var factorAGL_L = factorL;
    var factorAGL_R = factorR;
    if (agl > 4) { 
       factorAGL_L = factorL*aglFactor;
       factorAGL_R = factorR*aglFactor;
    }

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
    C = gear0Compression.getValue();
    if (C > 0.0) {
      theta0 = scissor_angle(H,C,L,phi);
    }

    # Compute the angle the right gear scissor rotates due to right gear strut compression
      
    H = 0.205048;  # Right gear oleo strut extended length in m
    L = 0.107564;  # Right gear scissor length in m
    phi = 1.2673;
    C = gear1Compression.getValue();
    if (C > 0.0) {
      theta1 = scissor_angle(H,C,L,phi);
    }

    # Compute the angle the left gear scissor rotates due to left gear strut compression

    H = 0.205048;  # Left gear oleo strut extended length in m
    L = 0.107564;  # Left gear scissor length in m
    phi = 1.2673;
    C = gear2Compression.getValue();
    if (C > 0.0) {
      theta2 = scissor_angle(H,C,L,phi);
    }

##
#  Disengage nose wheel steering from the rudder pedals if not locked down
##

    if ( noseGearPosition.getValue() < 1) {
        rudder_position = 0.0;
    } else {
        rudder_position = rudderPosition.getValue();
    }

##
#  Disengage Joystick aileron if autopilot is controlling roll
##

  if ( rollC3.getValue() ) { 
      aileron = aileronAP.getValue();
  } 
  elsif ( rollC2b.getValue() ) {
      aileron = aileronAP.getValue();
  } 
  else {
      aileron = aileronJS.getValue();
  }

##
#  Disengage Joystick elevator if autopilot is controlling pitch
##

  if ( pitchC3.getValue() ) {
      elevator = elevatorAP.getValue();
  }
  else {
      elevator = elevatorJS.getValue();
  }

  # outputs
    theta0N.setDoubleValue(theta0);
    theta1N.setDoubleValue(theta1);
    theta2N.setDoubleValue(theta2);
    aileronIN.setDoubleValue(aileron);
    elevatorIN.setDoubleValue(elevator);
    filteredCDI0.setDoubleValue( cdi0_lowpass.filter(cdiNAV0.getValue()));
    filteredCDI1.setDoubleValue(cdi1_lowpass.filter(cdiNAV1.getValue()));
    filteredGS0.setDoubleValue(gs0_lowpass.filter(gsNAV0.getValue()));
    filteredGS1.setDoubleValue(gs1_lowpass.filter(gsNAV1.getValue()));
    fixEGT.setDoubleValue(egt_lowpass.filter(egt));
    leftLandingLightFactorAGL.setDoubleValue(factorAGL_L);
    rightLandingLightFactorAGL.setDoubleValue(factorAGL_R);
    noseGearTurnPosition.setDoubleValue(rudder_position);
    propDiskFactor.setDoubleValue(factor);
    fuelPressure.setDoubleValue(fuel_pres_lowpass.filter(fuel_pres));
    oilPressure.setDoubleValue(oil_pres_lowpass.filter(oil_pres));
    fuelPumpVolume.setDoubleValue(fuel_pump_volume);

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
setlistener("sim/signals/fdm-initialized", init_actions);  



