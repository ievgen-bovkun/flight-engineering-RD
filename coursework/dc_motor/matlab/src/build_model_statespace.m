function [mdl,path]=build_model_statespace(p,modelDir)
%BUILD_MODEL_STATESPACE Same contract as the differential-equation plant.
if nargin<2, modelDir=fullfile(dc_project_root(),'matlab','models'); end
[mdl,path,sub]=init_motor_model('dc_motor_statespace',p,modelDir);
m=motor_models(p); ws=get_param(mdl,'ModelWorkspace');
assignin(ws,'A',m.A); assignin(ws,'B',[m.Bu,m.Bd]);
assignin(ws,'C',m.C); assignin(ws,'D',m.D);
add_block('simulink/Signal Routing/Mux',[sub '/Inputs'],'Inputs','2','Position',[105,95,110,245]);
add_block('simulink/Continuous/State-Space',[sub '/State space'],'A','A','B','B','C','C','D','D', ...
    'X0','x0','Position',[210,120,410,205]);
add_block('simulink/Signal Routing/Demux',[sub '/Outputs'],'Outputs','2','Position',[505,115,510,175]);
add_line(sub,'Vin/1','Inputs/1','autorouting','on');
add_line(sub,'TL/1','Inputs/2','autorouting','on');
add_line(sub,'Inputs/1','State space/1','autorouting','on');
add_line(sub,'State space/1','Outputs/1','autorouting','on');
add_line(sub,'Outputs/1','omega/1','autorouting','on');
add_line(sub,'Outputs/2','i/1','autorouting','on');
save_system(mdl,path);
end
