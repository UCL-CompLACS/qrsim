function U = joy2input( axes )
%JOY2INPUT
% converts joystick input to an imput suitable to the
% Pelican dynamic model, battery is set to 10
% the scaling factors are the input limits, see Pelican.m
%
% Note:
%   This function requires the vr toolbox
%

U(1:2,1) = -0.89*[axes(2);axes(1)];
U(3,1) = 0.5*(1+axes(3));
U(4,1) = -5.1*axes(5);
U(5,1) = 10;

end

