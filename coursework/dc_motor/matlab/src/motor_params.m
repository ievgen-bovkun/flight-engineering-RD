function p=motor_params(configPath)
%MOTOR_PARAMS Assignment constants and explicitly declared design choices.
if nargin<1, configPath=fullfile(dc_project_root(),'config','parameters.json'); end
config=jsondecode(fileread(configPath));
p=config.physical;
p.J=p.Jm+p.JL; p.B=p.Bm;
p.w_ref=config.control.reference;
p.Vmin=config.control.Vmin; p.Vmax=config.control.Vmax;
p.beta=config.control.beta; p.gamma=config.control.gamma;
p.derivativeRatio=config.control.derivativeRatio;
p.minimumFilterTime=config.control.minimumFilterTime;
p.ts_spec=config.chosenTargets.settlingTime;
p.os_spec=config.chosenTargets.overshootPercent;
p.ess_spec=config.chosenTargets.steadyError;
p.band=config.chosenTargets.settlingBand;
p.dt=config.numerics.outputStep;
p.RelTol=config.numerics.relativeTolerance; p.AbsTol=config.numerics.absoluteTolerance;
p.seed=config.numerics.seed;
p.Tsim=5; p.Tsim_ol=30; p.TL_step=.05; p.TL_time=1;
p.config=config;
motor_models(p); % Reject invalid physical values before simulation.
end
