function R=live_visualization(p,K,opt)
%LIVE_VISUALIZATION CLI-launched plot updated while the solver integrates.
if nargin<3, opt=struct(); end
if ~isfield(opt,'visible'), opt.visible=false; end
if ~isfield(opt,'realTime'), opt.realTime=false; end
if ~isfield(opt,'outputDir'), opt.outputDir=fullfile(dc_project_root(),'results','live'); end
if ~isfolder(opt.outputDir), mkdir(opt.outputDir); end
settings=pid_settings(p,K,opt); ctrl=settings.opt;
visibility='off'; if opt.visible, visibility='on'; end
f=figure('Visible',visibility,'Position',[100,100,950,650]); cleanup=onCleanup(@() close(f));
tiledlayout(2,1); nexttile; speedLine=animatedline('LineWidth',1.5); grid on;
xlabel('Час, с'); ylabel('Кутова швидкість, рад/с');
nexttile; voltageLine=animatedline('LineWidth',1.5); grid on;
xlabel('Час, с'); ylabel('Напруга, В');
updates=0; lastExport=-Inf; wall=tic;
opt.OutputFcn=@update;
out=simulate_disturbance(p,K,opt);
exportgraphics(f,fullfile(opt.outputDir,'latest.png'),'Resolution',90);
R=struct('out',out,'updateCount',updates);

    function stop=update(t,x,flag)
        stop=0;
        if ~isempty(flag), return; end
        volt=zeros(size(t));
        for q=1:numel(t), [~,volt(q)]=pid_output(x(:,q),K,settings.Tf,ctrl); end
        addpoints(speedLine,t,x(2,:)); addpoints(voltageLine,t,volt);
        if opt.realTime
            delay=t(end)-toc(wall); if delay>0, pause(min(delay,.1)); end
        end
        if t(end)-lastExport>=.1 || t(end)>=ctrl.Tend
            updates=updates+1; lastExport=t(end); drawnow limitrate;
            exportgraphics(f,fullfile(opt.outputDir,'latest.png'),'Resolution',90);
            fid=fopen(fullfile(opt.outputDir,'progress.json'),'w','n','UTF-8');
            fileCleanup=onCleanup(@() fclose(fid));
            fprintf(fid,'%s\n',jsonencode(struct('time_s',t(end),'omega_rad_s',x(2,end),'voltage_V',volt(end),'updates',updates)));
            clear fileCleanup
        end
    end
end
