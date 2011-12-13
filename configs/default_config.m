global state;
global params;

%%%% GLOBAL %%%%
% simulation time see also tGPS below
state.t = 0;

% step time in seconds
% this should not be changed...
params.dt = 0.02;


% 3D display parameters
params.display3d.on = 0;
params.display3d.width = 1000;
params.display3d.height = 600;


%%%%% environment %%%%%
% these need to follow the conventions of axis(), they are in m, Z down
params.environment.area.limits = [-10 20 -7 7 -20 0];

[E N zone h] = lla2utm([51.71190;-0.21052;0]);
params.environment.area.originutmcoords.E = E;
params.environment.area.originutmcoords.N = N;
params.environment.area.originutmcoords.h = h;  
params.environment.area.originutmcoords.zone =  zone;


% Wind 
% i.e. a steady omogeneous wind with a direction and magnitude
% this is common to all helicopters
params.environment.wind.on = 1;
params.environment.wind.meandirection = [1;0;0];
params.environment.wind.W6 = 0.03;  %velocity at 6m from ground in m/s
params.environment.wind.type = 'TurbulenceMILF8785'; % time varying stochastic wind drafts, different for each of the helicopters
params.environment.wind.dt = 0.02;
params.environment.wind.seed = 0;% 123456; %set to zero to have random seed


config = loadConfig('pelican_config');
config.X = [0;0;0;0;0;0];

state.platforms(1) = Pelican(config);
