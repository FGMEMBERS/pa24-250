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
node = props.globals.getNode("/engines/engine/out-of-fuel",0);
node.setBoolValue(0);} 
 }
if(test == 2){
node = props.globals.getNode("/consumables/fuel/tank[1]/selected",0);
node.setBoolValue(1);
if(getprop("/consumables/fuel/tank[1]/level-gal_us")>0.01){
node = props.globals.getNode("/engines/engine/out-of-fuel",0);
node.setBoolValue(0);} 
 }
if(test == 3){
node = props.globals.getNode("/consumables/fuel/tank[2]/selected",0);
node.setBoolValue(1);
if(getprop("/consumables/fuel/tank[2]/level-gal_us")>0.01){
node = props.globals.getNode("/engines/engine/out-of-fuel",0);
node.setBoolValue(0);} 
 }
if(test == 4){
node = props.globals.getNode("/consumables/fuel/tank[3]/selected",0);
node.setBoolValue(1);
if(getprop("/consumables/fuel/tank[3]/level-gal_us")>0.01){
node = props.globals.getNode("/engines/engine/out-of-fuel",0);
node.setBoolValue(0);} 
 }
}
