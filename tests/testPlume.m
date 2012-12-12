function e = testPlume()
% bare bone test for the plume scenario

clear all
close all

make_plots = 0;

addpath('plume');
% include simulator
addpath(['..',filesep,'sim']);
addpath(['..',filesep,'controllers']);

% create simulator object
qrsim = QRSim();

% load task parameters and do housekeeping
state = qrsim.init('TestTaskPlumeSingleSourceGaussianDispersion');

% create a 3 x helicopters matrix of control inputs
% column i will contain the 3D NED velocity [vx;vy;vz] in m/s for helicopter i
U = zeros(3,state.task.numUAVs);
tstart = tic;

if(make_plots)
    hf = figure(2);
    hp = plot(0,0);
end

plumeMeas = zeros(state.task.numUAVs,state.task.durationInSteps);
plumePos = zeros(3,state.task.durationInSteps);

positions = state.task.getLocations();
samplesPerLocation = state.task.getSamplesPerLocation();
samples = zeros(samplesPerLocation,size(positions,2));

% run the scenario and at every timestep generate a control
% input for each of the helicopters
u = zeros(2,state.task.numUAVs);

% source
s = state.environment.area.getSources();

% limits
l = state.environment.area.getLimits();

% get wind direction
w = state.environment.wind.getLinear([0;0;-6;0;0;0]);
w = w/norm(w);
downwind = 1;

% cheat by putting the uav in the center of the source
state.platforms{1}.setX([s+5*w;0;0;0]);

for i=1:state.task.durationInSteps,
    tloop=tic;
    
    % a basic policy in which the helicopter(s) moves 
    % up and down the dispersion cone
    if(downwind)
        % random velocity direction
        U(1:2,1) = 0.5*state.task.velPIDs{1}.maxv*w(1:2);        
    else
        U(1:2,1) = -0.5*state.task.velPIDs{1}.maxv*w(1:2);
    end
    X = state.platforms{1}.getX(1:3);
    
    if(norm(X(1)-l(1))<10 || norm(X(1)-l(2))<10 || norm(X(2)-l(2))<10 || norm(X(2)-l(3))<10)
       downwind = 0;
       %disp('upwind');
    end
    
    if(norm(X(1:2)-s(1:2))<5)
       downwind = 1;
       %disp('downwind');
    end
    
    % scale by the max allowed velocity
    U(3,1) = -0.1*state.task.velPIDs{1}.maxv*(X(3)-s(3));
    
    % step simulator
    qrsim.step(U);
    
    samples(i,:)=state.environment.area.getSamples(positions);
    % get plume measurement
    plumeMeas(1,i)=state.platforms{1}.getPlumeSensorOutput();
    plumePos(:,i) =state.platforms{1}.getX(1:3);
    if(make_plots)
        t = (1:i)*state.task.dt;
        set(hp,'Xdata',t);
        set(hp,'Ydata',plumeMeas(1,1:i));
    end
    
    if(make_plots)
        % wait so to run in real time
        % this can be commented out obviously
        wait = max(0,state.task.dt-toc(tloop));
        pause(wait);
    end
end

% query at what locations we need to make predictions of concentration
positions = state.task.getLocations();

% set positions to perform optimization
state.environment.area.setPos(plumePos);

% perform optimization
x = state.environment.area.optimize([1,0.2,0.6]);

% compute samples given known model and computed parameters
samples = state.environment.area.getSamplesGivenParameters(x,positions);
                
% set the samples so that the task can compute a reward
state.task.setSamples(samples);

% get final reward, this works only after the samples have been set.
if( qrsim.reward()<1e-6)
    disp('test plume scenario [PASSED]');
    e = 0;
else
    disp('test plume scenario [FAILED]');
    e = 1;
end

