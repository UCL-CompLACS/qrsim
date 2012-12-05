% bare bones example of use of the QRSim() simulator
% with one of the search-and-rescue scenario
%
% as a quick remainder, in this task targets (people) are lost/injured on 
% the ground in a landscape and need to be located and rescued. 
% A helicopter agent is equipped with a camera/classification module
% for predicting the position of targets in its field of vision, but the quality of predictions
% depend upon the geometry between helicopter and ground (e.g. the distance). Rather
% than raw images the camera module provides higher-level data in the form of likelihood
% ratios of the current image conditioned on the presence or absence of a target.

clear all
close all

% include simulator
addpath(['..',filesep,'..',filesep,'sim']);
addpath(['..',filesep,'..',filesep,'controllers']);

% create simulator object
qrsim = QRSim();

% load task parameters and do housekeeping
state = qrsim.init('TaskSearchRescueSingleNoiseless');
%state = qrsim.init('TaskSearchRescueSingleNoisy');
%state = qrsim.init('TaskSearchRescueMultipleNoiseless');
%state = qrsim.init('TaskSearchRescueMultipleNoisyAndWindy');


% create a 2 x helicopters matrix of control inputs
% column i will contain the 2D NED velocity [vx;vy] in m/s for helicopter i
U = zeros(2,state.task.numUAVs);
tstart = tic;

% run the scenario and at every timestep generate a control
% input for each of the uavs
u = zeros(2,state.task.numUAVs);
for i=1:state.task.durationInSteps,
    tloop=tic;
    
    % a basic randon search policy in which the helicopter(s) moves around
    % at a fixed velocity changing direction every once in a while    
    if(rem(i-1,10)==0)
        for j=1:state.task.numUAVs,            
            % random velocity direction
            u(:,j) = rand(2,1)-[0.5;0.5];
            % scale by the max allowed velocity
            U(:,j) = 0.5*(u(:,j)/norm(u(:,j)));
        end
    end
    
    % step simulator
    qrsim.step(U);
    
    % get camera measurement
    % Note:
    % the output is an object of type CemeraObservation, i.e.
    % a simple structure containing the fields:
    % llkd      log-likelihood difference for each gound patch
    % wg        list of corner points for the ground patches
    % gridDims  dimensions of the grid of measurements
    %
    % the corner points wg of the ground patches are layed out in a regular
    % gridDims(1) x gridDims(2) grid pattern, we return them stored in a
    % 3*N matrix (i.e. each point has x;y;z coordinates) obtained
    % scanning the grid left to right and top to bottom.
    % this means that the 4 cornes of window i,j
    % are wg(:,(i-1)*(gridDims(1)+1)+j+[0,1,gridDims(1)+1,gridDims(1)+2])
    for j=1:state.task.numUAVs,
        m = state.platforms{j}.getCameraOutput();
    end    
    
    if(state.display3dOn)
        % wait so to run in real time
        % this can be commented out obviously
        wait = max(0,state.task.dt-toc(tloop));
        pause(wait);
    end
end

% get final reward
% reminder: a large negative final reward (-1000) is returned in case of
% collisions or in case of any uav going outside the flight area
fprintf('final reward: %f\n',qrsim.reward());

elapsed = toc(tstart);

fprintf('running %d times real time\n',(state.task.durationInSteps*state.task.dt)/elapsed);
