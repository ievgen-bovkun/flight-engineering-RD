function [mdl,path]=build_model_diffeq(p,modelDir)
%BUILD_MODEL_DIFFEQ Kirchhoff and shaft dynamics using Sum/Gain/Integrator.
if nargin<2, modelDir=fullfile(dc_project_root(),'matlab','models'); end
[mdl,path,sub]=init_motor_model('dc_motor_diffeq',p,modelDir);
add_block('simulink/Math Operations/Sum',[sub '/Voltage balance'],'Inputs','+--','Position',[95,70,115,120]);
add_block('simulink/Math Operations/Gain',[sub '/Inverse inductance'],'Gain','1/p.La','Position',[155,80,215,110]);
add_block('simulink/Continuous/Integrator',[sub '/Current'],'InitialCondition','x0(1)','Position',[255,80,285,110]);
add_block('simulink/Math Operations/Gain',[sub '/Torque constant'],'Gain','p.Kt','Position',[325,80,385,110]);
add_block('simulink/Math Operations/Sum',[sub '/Torque balance'],'Inputs','+--','Position',[425,70,445,120]);
add_block('simulink/Math Operations/Gain',[sub '/Inverse inertia'],'Gain','1/p.J','Position',[480,80,540,110]);
add_block('simulink/Continuous/Integrator',[sub '/Speed'],'InitialCondition','x0(2)','Position',[585,80,615,110]);
add_block('simulink/Math Operations/Gain',[sub '/Armature resistance'],'Gain','p.Ra','Orientation','left','Position',[255,185,315,215]);
add_block('simulink/Math Operations/Gain',[sub '/Back EMF'],'Gain','p.Ke','Orientation','left','Position',[255,305,315,335]);
add_block('simulink/Math Operations/Gain',[sub '/Damping'],'Gain','p.B','Orientation','left','Position',[505,185,565,215]);
links={'Vin/1','Voltage balance/1';'Voltage balance/1','Inverse inductance/1'; ...
 'Inverse inductance/1','Current/1';'Current/1','Torque constant/1'; ...
 'Torque constant/1','Torque balance/1';'Torque balance/1','Inverse inertia/1'; ...
 'Inverse inertia/1','Speed/1';'Speed/1','omega/1';'Current/1','i/1'; ...
 'Current/1','Armature resistance/1';'Armature resistance/1','Voltage balance/2'; ...
 'Speed/1','Back EMF/1';'Back EMF/1','Voltage balance/3'; ...
 'Speed/1','Damping/1';'Damping/1','Torque balance/2';'TL/1','Torque balance/3'};
for k=1:size(links,1), add_line(sub,links{k,1},links{k,2},'autorouting','on'); end
save_system(mdl,path);
end
