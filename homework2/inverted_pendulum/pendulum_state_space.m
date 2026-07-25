function [sys, P] = pendulum_state_space()
%PENDULUM_STATE_SPACE Return the continuous-time CTMS upright pendulum model.

P = pendulum_params();
sys = ss(P.A, P.B, P.C, P.D);
end
