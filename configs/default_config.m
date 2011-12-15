

% Simulator step time in second
% this should not be changed...
params.DT = 0.01;

params.seed = 0; %set to zero to have a seed that depends on the system time

%%%%% visualization %%%%%
% 3D display parameters
params.display3d.on = 1;
params.display3d.width = 1000;
params.display3d.height = 600;


%%%%% environment %%%%%
% these need to follow the conventions of axis(), they are in m, Z down
params.environment.area.limits = [-10 20 -7 7 -20 0];
params.environment.area.type = 'AreaGraphics';
[E N zone h] = lla2utm([51.71190;-0.21052;0]);
params.environment.area.originutmcoords.E = E;
params.environment.area.originutmcoords.N = N;
params.environment.area.originutmcoords.h = h;  
params.environment.area.originutmcoords.zone =  zone;


% GPS
% The 
params.environment.gpsspacesegment.on = 0; % if off the gps returns the noiseless position
params.environment.gpsspacesegment.dt = 0.2;
% specific setting due to the use of the ngs15992_16to17.sp3 file
params.environment.gpsspacesegment.preciseorbitfile = 'ngs15992_16to17.sp3';
params.environment.gpsspacesegment.tStart = Orbits.parseTime(2010,8,31,16,0,0);
% a typical day (ro31082010.10o) at RVC had the following svs visible:
%03G 05G 06G 07G 13G 16G 18G 19G 20G 22G 24G 29G 31G
params.environment.gpsspacesegment.svs = [3,5,6,7,13,16,18,19,20,22,24,29,31];
params.environment.gpsspacesegment.type = 'GPSSpaceSegmentGM';
params.environment.gpsspacesegment.PR_BETA = 2000;             % process time constant (from [2])           
params.environment.gpsspacesegment.PR_SIGMA = 0.1746;          % process standard deviation (from [2])
%params.environment.gpsspacesegment.type = 'GPSPseudorangeGM2';
%params.environment.gpsspacesegment.PR_BETA2 = 600;               % process time constant
%params.environment.gpsspacesegment.PR_BETA1 =  1.075;            % process time constant   
%params.environment.gpsspacesegment.PR_SIGMA = 0.001;             % process standard deviation (from [2])
params.environment.gpsspacesegment.DT = params.DT;

% Wind 
% i.e. a steady omogeneous wind with a direction and magnitude
% this is common to all helicopters
params.environment.wind.on = 0;
params.environment.wind.type = 'WindConstMean';
params.environment.wind.direction = [1;0;0]; %mean wind direction
params.environment.wind.W6 = 0.1;  %velocity at 6m from ground in m/s
params.environment.wind.dt = 1;    %not actually used since the model is constant
params.environment.wind.DT = params.DT;

%%%%% platforms %%%%% 
% Configuration and initial state for each of the platforms
params.platforms(1).configfile = 'pelican_config';
params.platforms(1).X = [0;0;-20;0;0;0];

% state.platforms(2).configfile = 'pelican_config';
% state.platforms(2).initX = [0;0;0;0;0;0];
% 
% state.platforms(3).configfile = 'pelican_config';
% state.platforms(3).initX = [0;0;0;0;0;0];




% [1] J. Rankin, "An error model for sensor simulation GPS and differential GPS," IEEE 
%     Position Location and Navigation Symposium, 1994, pp.260-266.
% [2] Carlson, Justin, "Mapping Large, Urban Environments with GPS-Aided SLAM" (2010). 
%     Dissertations. Paper 44.