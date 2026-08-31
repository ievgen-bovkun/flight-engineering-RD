function [Y,X] = simulate_discrete_ss(Ad,Bd,Cd,Dd,U,x0)
%SIMULATE_DISCRETE_SS Simulate x(k+1)=Ad*x(k)+Bd*u(k) on sample rows.
if isvector(U)
    U = U(:);
end
nSamples = size(U,1);
nStates = size(Ad,1);
assert(size(Ad,2)==nStates && size(Bd,1)==nStates && ...
    size(Cd,2)==nStates && size(U,2)==size(Bd,2), 'DSS:DimensionMismatch');
x = x0(:);
assert(numel(x)==nStates, 'DSS:InitialStateSizeMismatch');
X = zeros(nSamples,nStates);
Y = zeros(nSamples,size(Cd,1));
for k = 1:nSamples
    X(k,:) = x.';
    Y(k,:) = (Cd*x + Dd*U(k,:).').';
    if k < nSamples
        x = Ad*x + Bd*U(k,:).';
    end
end
end
