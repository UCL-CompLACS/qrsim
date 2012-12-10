% This script defines all the typical parameters of an AscTec pelican quadrotor
% 
% These paramters must be loaded using the function loadConfig and are then
% passed to the platform constructor, which will take care of propagating the correct 
% parameters to each of the objects part of a platform.  
%
% Example of use:
%
%  platform  = loadConfig('pelican_config');
%  n = Pelican(platform);
% 
% note: generally the loading is performed automatically by qrsim
%
%
% GENERAL NOTES:
% - if the on flag is zero, a NOISELESS version of the object is loaded instead
% - the parameter dt MUST be always specified even if on=0
%
if(~exist('params','var'))
    error('The platform parameters must be loaded after the global parameters');
end

% platforms %
c.dt = 0.02;
c.on = 1;
c.type = 'PelicanForTesting';

% max and min limits for each of the state variables, exceeding this limits
% makes the state invalid (i.e. 19x1 nan)
c.stateLimits =[params.environment.area.limits(1:2);params.environment.area.limits(3:4);...
    params.environment.area.limits(5:6);... % position limits defined by the area
    -pi,pi;-pi,pi;-10*pi,10*pi;... % attitude limits
    -15,15;-15,15;-15,15;... % linear velocity limits
    -2,2;-2,2;-2,2]; %rotational velocity limits
    
c.collisionDistance = 2; % two platforms colser than this distance are deemed in collision 
c.dynNoise = [0.1;0.1;0.1;0.1;0.1;0.1];

% GPS Receiver
c.sensors.gpsreceiver.on = 0; % if off the gps returns the noiseless position
c.sensors.gpsreceiver.type = 'GPSReceiverG';
c.sensors.gpsreceiver.minmaxnumsv=[10,13];        % max and min number of satellites 
c.sensors.gpsreceiver.R_SIGMA = 0.002;             % receiver noise standard deviation 
c.sensors.gpsreceiver.delay = 1;  % receiver delay in multiples of receiver's dt

% AHARS attitude-heading-altitude reference system (a.k.a. imu + altimeter)
% dt defined by the minimum dt of the sensors
c.sensors.ahars.on = 1;  % setting it to 0 is equivalent to disabling all the ones below
c.sensors.ahars.type = 'AHARSPelicanForTesting';

c.sensors.ahars.accelerometer.on = 1;  % if off the accelerometer returns the noiseless acceleration
c.sensors.ahars.accelerometer.type = 'AccelerometerG';
c.sensors.ahars.accelerometer.dt = 0.02;
c.sensors.ahars.accelerometer.SIGMA = [0.0025;0.0025;0.0025]; % noise standard deviation

c.sensors.ahars.gyroscope.on = 1; % if off the gyroscope returns the noiseless rotational velocity
c.sensors.ahars.gyroscope.type = 'GyroscopeG';
c.sensors.ahars.gyroscope.dt = 0.02;
c.sensors.ahars.gyroscope.SIGMA = [0.0002;0.0002;0.0002]; % noise standard deviation

c.sensors.ahars.orientationEstimator.on = 1; % if off the estimator returns the noiseless orientation
c.sensors.ahars.orientationEstimator.type = 'OrientationEstimatorGM';
c.sensors.ahars.orientationEstimator.dt = 0.02;
c.sensors.ahars.orientationEstimator.BETA = [1/100;1/100;1/100];       % noise time constant
c.sensors.ahars.orientationEstimator.SIGMA = [0.0005;0.0005;0.0005];   % noise standard deviation
   
c.sensors.ahars.altimeter.on = 1; % if off the altimeter returns the noiseless altitude
c.sensors.ahars.altimeter.type = 'AltimeterGM';
c.sensors.ahars.altimeter.dt = 0.02;
c.sensors.ahars.altimeter.TAU = 300;      % noise time constant
c.sensors.ahars.altimeter.SIGMA = 0.003;       % noise standard deviation

% Aerodynamic Turbulence
c.aerodynamicturbulence.on = 1;



% Graphics
 
c.graphics.type = 'PelicanGraphics';
c.graphics.trajectory = 1; % plot trajectory
c.graphics.AL = 0.4;       % arm length m
c.graphics.AT = 0.01;      % arm width m
c.graphics.AW = 0.02;      % arm thickness m
c.graphics.BW = 0.12;      % body width m
c.graphics.BT = 0.08;      % body thickness m
c.graphics.R = 0.08;       % rotor radius m 
c.graphics.DFT = 0.02;     % distance from truss m


