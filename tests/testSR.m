function e = testSR()
% test if in the search and rescue scenario the persons disappear as expected when found

clear all
close all

% include simulator
addpath('sr');
addpath(['..',filesep,'sim']);
addpath(['..',filesep,'controllers']);

% create simulator object
qrsim = QRSim();

% load task parameters and do housekeeping
state = qrsim.init('TaskSearchRescueTest');

% create a 2 x helicopters matrix of control inputs
% column i will contain the 3D NED velocity [vx;vy;vy] in m/s for helicopter i
U = zeros(3,state.task.numUAVs);

% given that this is a test we know the person location
% an the helicopter start location

% run the scenario and at every timestep generate a control
% input for each of the uavs

r = 0;

for i=1:state.task.durationInSteps,
    tloop=tic;
    
    % a basic randon search policy in which the helicopter(s) moves around
    % at a fixed velocity changing direction every once in a while    
    if(rem(i-1,10)==0)           
        % quick and dirty way to drive the 1st uav to the first person @ 0,0
        U(:,1) = 0.1*([0;0;-4]-state.platforms{1}.getX(1:3));
        % quick and dirty way to drive the 1st uav to the first person @ 10,50
        U(:,2) = 0.1*([10;50;-4]-state.platforms{2}.getX(1:3));    
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
    
    r = r+ qrsim.reward();
    
    if(state.display3dOn)
        % wait so to run in real time
        % this can be commented out obviously
        wait = max(0,state.task.dt-toc(tloop));
        pause(wait);
    end
end

if(r==2)
    disp('test search rescue reward [PASSED]');
    e = 0;
else    
    disp('test search rescue reward [FAILED]');
    e = 1;
end    

end