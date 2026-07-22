function x0 = quadrotor_initial_state(P)
%QUADROTOR_INITIAL_STATE Hover at 10 m above the NED reference origin.

x0 = zeros(16, 1);
x0(3) = -10;
x0(13:16) = P.Omega0;
end
