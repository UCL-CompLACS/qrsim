function [x a]= ruku2(state_eq, x, u, dt)
% RUKU2 Integrates the platform differential equation using the Runge-Kutta 2nd order method
%
%   Examples:
%
%      [newState,acelerations] = ruku2('pelicanODE',state,controls,timestep)
%

% Beginning of interval
[xdt a1] = feval(state_eq, x, u, dt);
rk1 = xdt*dt;

% End of interval
x1  = x + rk1;
[xdt a2] = feval(state_eq, x1, u, dt);
rk2 = xdt*dt;

x   = x + (rk1 + rk2)./2;
a = (a1 + a2)./2;

return
% end of subroutine
