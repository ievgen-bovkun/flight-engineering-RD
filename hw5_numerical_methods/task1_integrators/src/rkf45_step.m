function [y4,y5,errorVector] = rkf45_step(rhs, t, y, h)
%RKF45_STEP Perform one classical Fehlberg embedded 4(5) trial step.
validateattributes(h, {'numeric'}, {'scalar','real','finite','positive'});
y = y(:);
k1 = rhs(t, y); k1 = k1(:);
k2 = rhs(t+h/4, y+h*k1/4); k2 = k2(:);
k3 = rhs(t+3*h/8, y+h*(3*k1/32+9*k2/32)); k3 = k3(:);
k4 = rhs(t+12*h/13, y+h*(1932*k1/2197-7200*k2/2197+7296*k3/2197)); k4 = k4(:);
k5 = rhs(t+h, y+h*(439*k1/216-8*k2+3680*k3/513-845*k4/4104)); k5 = k5(:);
k6 = rhs(t+h/2, y+h*(-8*k1/27+2*k2-3544*k3/2565+1859*k4/4104-11*k5/40)); k6 = k6(:);
assert(isequal(size(k1),size(y)) && isequal(size(k2),size(y)) && ...
    isequal(size(k3),size(y)) && isequal(size(k4),size(y)) && ...
    isequal(size(k5),size(y)) && isequal(size(k6),size(y)), ...
    'RKF45:StateSizeMismatch');
y4 = y+h*(25*k1/216+1408*k3/2565+2197*k4/4104-k5/5);
y5 = y+h*(16*k1/135+6656*k3/12825+28561*k4/56430-9*k5/50+2*k6/55);
errorVector = y5-y4;
end
