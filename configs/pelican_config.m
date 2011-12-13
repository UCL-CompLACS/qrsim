global params;
global loadConfigFlag;

% This script defines all the typical parameters of an AscTec pelican quadrotor
% 
% These paramters must be loaded using the function loadConfig and are then
% passed to the platform constructor, which will take care of propagating the correct 
% parameters to each of the objects part of a platform.  
%
% Example:
%
%  platform  = loadConfig('pelican_config');
%  n = Pelican([0;0;0;0;0;0],platform);
%

if(~loadConfigFlag)
   error('This script is meant to be loaded using loadConfig'); 
end    


%%%%% platforms %%%%%
c.dt = 0.02;
c.on = 1;

% GPS 
c.sensors.gps.on = 1; % if off the gps returns the noiseless position
c.sensors.gps.type = 'GPSPseudorangeGM';
%c.sensors.gps.type = 'GPSPseudorangeGM2';
c.sensors.gps.dt = 0.2;
c.sensors.gps.seed = 123456; %set to zero to have random seed
% specific setting due to the use of the ngs15992_16to17.sp3 file
c.sensors.gps.preciseorbitfile = 'ngs15992_16to17.sp3';
c.sensors.gps.tStart = Orbits.parseTime(2010,8,31,16,0,0);
%gps.tStart = DateTime(2010,8,31,16,0,0); 
% a typical day (ro31082010.10o) at RVC had the following svs visible:
%03G 05G 06G 07G 13G 16G 18G 19G 20G 22G 24G 29G 31G
c.sensors.gps.svs = [3,5,6,7,13,16,18,19,20,22,24,29,31];
c.sensors.gps.originutmcoords = params.environment.area.originutmcoords;
% max and min number of satellites 
c.sensors.gps.minmaxnumsv=[10,13]; 
c.sensors.gps.PR_BETA = 2000;             % process time constant (from [2])           
c.sensors.gps.PR_SIGMA = 0.1746;          % process standard deviation (from [2])
c.sensors.gps.R_SIGMA = 0.02;             % receiver noise standard deviation 
%c.sensors.gps.PR_BETA2 = 600;               % process time constant
%c.sensors.gps.PR_BETA1 =  1.075;            % process time constant   
%c.sensors.gps.PR_SIGMA = 0.001;             % process standard deviation (from [2])
%c.sensors.gps.R_SIGMA = 0.02;               % receiver noise standard deviation  

% AHARS attitude-heading-altitude reference system (a.k.a. imu + altimeter)
% dt defined by the minimum dt of the sensors
c.sensors.ahars.on = 1;  % setting it to 0 is equivalent to disabling all the ones below
c.sensors.ahars.type = 'AHARSPelican';

c.sensors.ahars.accelerometer.on = 1;  % if off the accelerometer returns the noiseless acceleration
c.sensors.ahars.accelerometer.type = 'AccelerometerG';
c.sensors.ahars.accelerometer.dt = 0.02;
c.sensors.ahars.accelerometer.seed = 0;% 123456; %set to zero to have random seed
c.sensors.ahars.accelerometer.SIGMA = [0.0005;0.0005;0.0005]; % noise standard deviation

c.sensors.ahars.gyroscope.on = 1; % if off the gyroscope returns the noiseless rotational velocity
c.sensors.ahars.gyroscope.type = 'GyroscopeG';
c.sensors.ahars.gyroscope.dt = 0.02;
c.sensors.ahars.gyroscope.seed = 0;% 123456; %set to zero to have random seed
c.sensors.ahars.gyroscope.SIGMA = [0.0005;0.0005;0.0005]; % noise standard deviation

c.sensors.ahars.orientationEstimator.on = 1; % if off the estimator returns the noiseless orientation
c.sensors.ahars.orientationEstimator.type = 'OrientationEstimatorGM';
c.sensors.ahars.orientationEstimator.dt = 0.02;
c.sensors.ahars.orientationEstimator.seed = 0;% 123456; %set to zero to have random seed
c.sensors.ahars.orientationEstimator.BETA = [1/100;1/100;1/100];       % noise time constant
c.sensors.ahars.orientationEstimator.SIGMA = [0.0005;0.0005;0.0005];   % noise standard deviation
        
c.sensors.ahars.altimeter.on = 1; % if off the altimeter returns the noiseless altitude
c.sensors.ahars.altimeter.type = 'AltimeterGM';
c.sensors.ahars.altimeter.dt = 0.02;
c.sensors.ahars.altimeter.seed = 0;% 123456; %set to zero to have random seed
c.sensors.ahars.altimeter.BETA = 1/3000;      % noise time constant
c.sensors.ahars.altimeter.SIGMA = 0.03;       % noise standard deviation


% Turbulence 
% this simply lifts the global configuration
c.wind = params.environment.wind;

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


% [1] J. Rankin, "An error model for sensor simulation GPS and differential GPS," IEEE 
%     Position Location and Navigation Symposium, 1994, pp.260-266.
% [2] Carlson, Justin, "Mapping Large, Urban Environments with GPS-Aided SLAM" (2010). 
%     Dissertations. Paper 44.
