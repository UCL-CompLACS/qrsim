% MEXIFY compile mex functions present in the simulator project
% Note: this script must be run from the root folder of the simulator'
%
% Example:
%   mexify()
%

if(~exist('functions','dir')||~exist('classes/platforms/','dir'))
    error('you need to run this script from the root folder of the simulator');
end

cd ./functions

mex ecef2lla.c
mex ecef2ned.c
mex lla2ecef.c
mex lla2utm.c
mex ned2ecef.c
mex polyval.c
mex utm2lla.c

%%$ compile helicopeter ODE function
cd ../classes/platforms/
mex pelicanODE.c

%%% back to base
cd ../../..