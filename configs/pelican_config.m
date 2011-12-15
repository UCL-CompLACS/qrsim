% This script defines all the typical parameters of an AscTec pelican quadrotor
% 
% These paramters must be loaded using the function loadConfig and are then
% passed to the platform constructor, which will take care of propagating the correct 
% parameters to each of the objects part of a platform.  
%
% Example:
%
%  platform  = loadConfig('pelican_config');
%  n = Pelican(platform);
%

% simulator %
c.DT = params.DT;

% platforms %
c.dt = 0.02;
c.on = 1;
c.type = 'Pelican';

% GPS Receiver
c.sensors.gpsreceiver.on = 1; % if off the gps returns the noiseless position
c.sensors.gpsreceiver.type = 'GPSReceiverG';
c.sensors.gpsreceiver.dt = 0.2;
c.sensors.gpsreceiver.seed = 10; %set to zero to have random seed
c.sensors.gpsreceiver.minmaxnumsv=[10,13];        % max and min number of satellites 
c.sensors.gpsreceiver.R_SIGMA = 0.02;             % receiver noise standard deviation 
c.sensors.gpsreceiver.tnsv  = length(params.environment.gpsspacesegment.svs);
c.sensors.gpsreceiver.originutmcoords = params.environment.area.originutmcoords;
c.sensors.gpsreceiver.DT = params.DT;

% AHARS attitude-heading-altitude reference system (a.k.a. imu + altimeter)
% dt defined by the minimum dt of the sensors
c.sensors.ahars.on = 1;  % setting it to 0 is equivalent to disabling all the ones below
c.sensors.ahars.type = 'AHARSPelican';
c.sensors.ahars.DT = params.DT;

c.sensors.ahars.accelerometer.on = 1;  % if off the accelerometer returns the noiseless acceleration
c.sensors.ahars.accelerometer.type = 'AccelerometerG';
c.sensors.ahars.accelerometer.dt = 0.02;
c.sensors.ahars.accelerometer.seed = 0;% 123456; %set to zero to have random seed
c.sensors.ahars.accelerometer.SIGMA = [0.0005;0.0005;0.0005]; % noise standard deviation
c.sensors.ahars.accelerometer.DT = params.DT;

c.sensors.ahars.gyroscope.on = 1; % if off the gyroscope returns the noiseless rotational velocity
c.sensors.ahars.gyroscope.type = 'GyroscopeG';
c.sensors.ahars.gyroscope.dt = 0.02;
c.sensors.ahars.gyroscope.seed = 0;% 123456; %set to zero to have random seed
c.sensors.ahars.gyroscope.SIGMA = [0.0005;0.0005;0.0005]; % noise standard deviation
c.sensors.ahars.gyroscope.DT = params.DT;

c.sensors.ahars.orientationEstimator.on = 1; % if off the estimator returns the noiseless orientation
c.sensors.ahars.orientationEstimator.type = 'OrientationEstimatorGM';
c.sensors.ahars.orientationEstimator.dt = 0.02;
c.sensors.ahars.orientationEstimator.seed = 0;% 123456; %set to zero to have random seed
c.sensors.ahars.orientationEstimator.BETA = [1/100;1/100;1/100];       % noise time constant
c.sensors.ahars.orientationEstimator.SIGMA = [0.0005;0.0005;0.0005];   % noise standard deviation
c.sensors.ahars.orientationEstimator.DT = params.DT;
   
c.sensors.ahars.altimeter.on = 1; % if off the altimeter returns the noiseless altitude
c.sensors.ahars.altimeter.type = 'AltimeterGM';
c.sensors.ahars.altimeter.dt = 0.02;
c.sensors.ahars.altimeter.seed = 0;% 123456; %set to zero to have random seed
c.sensors.ahars.altimeter.BETA = 1/3000;      % noise time constant
c.sensors.ahars.altimeter.SIGMA = 0.03;       % noise standard deviation
c.sensors.ahars.altimeter.DT = params.DT;

% Aerodynamic Turbulence
c.aerodynamicturbulence.on = 1;
c.aerodynamicturbulence.type = 'AerodynamicTurbulenceMILF8785'; % time varying stochastic wind drafts, different for each of the helicopters
c.aerodynamicturbulence.dt = 0.02;
c.aerodynamicturbulence.seed = 0;% 123456; %set to zero to have random seed
c.aerodynamicturbulence.DT = params.DT;
c.aerodynamicturbulence.W6 = params.environment.wind.W6;  %velocity at 6m from ground in m/s

% Graphics
c.quadrotorgraphics.on = params.display3d.on;
c.quadrotorgraphics.type = 'QuadrotorGraphics';
c.quadrotorgraphics.AL = 0.4;       % arm length m
c.quadrotorgraphics.AT = 0.01;      % arm width m
c.quadrotorgraphics.AW = 0.02;      % arm thickness m
c.quadrotorgraphics.BW = 0.12;      % body width m
c.quadrotorgraphics.BT = 0.08;      % body thickness m
c.quadrotorgraphics.R = 0.08;       % rotor radius m 
c.quadrotorgraphics.DFT = 0.02;     % distance from truss m


