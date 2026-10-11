function R=disturbance_recovery(t,deviation,eventTime,band)
%DISTURBANCE_RECOVERY Last band exit, including explicit no-recovery status.
t=t(:); deviation=deviation(:); idx=find(t>=eventTime);
if isempty(idx), error('dc_motor:InvalidTrace','Load event is outside recorded interval.'); end
R.dip=max(abs(deviation(idx))); bad=find(abs(deviation(idx))>band,1,'last');
R.recovered=true; R.recoveryTime=0;
if ~isempty(bad)
    last=idx(bad);
    if last==numel(t), R.recoveryTime=Inf; R.recovered=false;
    else, R.recoveryTime=t(last+1)-eventTime; end
end
R.additionalIAE=trapz(t(idx),abs(deviation(idx)));
end
