function [T,Y] = rk4_integrate(rhs, tspan, y0, h)
%RK4_INTEGRATE Integrate with fixed steps and a shortened final step.
validateattributes(tspan, {'numeric'}, {'vector','numel',2,'real','finite'});
validateattributes(h, {'numeric'}, {'scalar','real','finite','positive'});
t0 = tspan(1); tf = tspan(2);
assert(tf > t0, 'RK4:InvalidTimeSpan');
t = t0;
y = y0(:);
T = t;
Y = y.';
while t < tf
    hStep = min(h, tf-t);
    y = rk4_step(rhs, t, y, hStep);
    t = t + hStep;
    if abs(tf-t) <= 10*eps(max(1,abs(tf)))
        t = tf;
    end
    T(end+1,1) = t; %#ok<AGROW>
    Y(end+1,:) = y.'; %#ok<AGROW>
end
end
