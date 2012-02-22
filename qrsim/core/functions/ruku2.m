function [x a]= ruku2(state_eq, x, uaug, dt)
% RUKU2 Integrates the platform differential equation using the Runge-Kutta 2nd order method
%
%   Example:
%
%      [newState,accelerations] = ruku2('pelicanODE',state,augmented_controls,timestep)
%

% Beginning of interval
[xdt a1] = feval(state_eq, x, uaug, dt);
rk1 = xdt*dt;

% End of interval
x1  = x + rk1;
[xdt a2] = feval(state_eq, x1, uaug, dt);
rk2 = xdt*dt;

x   = x + (rk1 + rk2)./2;
a = (a1 + a2)./2;

return
% end of subroutine
