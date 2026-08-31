function yNext = rk4_step(rhs, t, y, h)
%RK4_STEP Advance a scalar or vector ODE by one classical RK4 step.
validateattributes(h, {'numeric'}, {'scalar','real','finite','positive'});
y = y(:);
k1 = rhs(t, y);                  k1 = k1(:);
k2 = rhs(t + h/2, y + h*k1/2);  k2 = k2(:);
k3 = rhs(t + h/2, y + h*k2/2);  k3 = k3(:);
k4 = rhs(t + h,   y + h*k3);    k4 = k4(:);
assert(isequal(size(k1), size(y)) && isequal(size(k2), size(y)) && ...
    isequal(size(k3), size(y)) && isequal(size(k4), size(y)), ...
    'RK4:StateSizeMismatch');
yNext = y + h*(k1 + 2*k2 + 2*k3 + k4)/6;
end
