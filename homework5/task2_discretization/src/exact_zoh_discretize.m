function [Ad,Bd,Cd,Dd] = exact_zoh_discretize(A,B,C,D,Ts)
%EXACT_ZOH_DISCRETIZE Exact zero-order hold discretization via expm.
validateattributes(Ts, {'numeric'}, {'scalar','real','finite','positive'});
n = size(A,1);
assert(isequal(size(A),[n n]) && size(B,1)==n && size(C,2)==n, ...
    'ZOH:DimensionMismatch');
m = size(B,2);
augmented = [A B; zeros(m,n+m)];
transition = expm(augmented*Ts);
Ad = transition(1:n,1:n);
Bd = transition(1:n,n+1:n+m);
Cd = C;
Dd = D;
end
