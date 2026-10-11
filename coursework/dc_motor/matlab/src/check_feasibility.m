function info=check_feasibility(p,m,Vlist)
%CHECK_FEASIBILITY First-touch lower bound, explicitly distinct from settling.
if nargin<3, Vlist=[24,48]; end
rates=sort(-real(m.poles)); a=rates(1); b=rates(2);
y=@(t) m.Kdc*(1-(b*exp(-a*t)-a*exp(-b*t))/(b-a));
info.V=Vlist(:); info.t_reach=Inf(size(info.V));
for j=1:numel(Vlist)
    if Vlist(j)*m.Kdc>p.w_ref
        info.t_reach(j)=fzero(@(t) Vlist(j)*y(t)-p.w_ref,[0,1000]);
    end
end
info.V_ss=p.w_ref/m.Kdc; info.V_min_touch=p.w_ref/y(p.ts_spec);
end
