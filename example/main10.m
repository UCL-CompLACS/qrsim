% bare bones example of use of the QRSim() simulator object with one
% helicopter

clear all
close all

% include simulator
addpath(['..',filesep,'sim']);
% include controllers
addpath(['..',filesep,'controllers']);

% create simulator object
qrsim = QRSim();

% load task parameters and do housekeeping
state = qrsim.init('TaskKeepSpot10');

% number of steps we run the simulation for
N = 3000;

wp = zeros(3,10);
pids = cell(10,1);

for i=1:10
    wp(:,i) = state.platforms{i}.getX(1:3);
    pids{i} = WaypointPID(state.DT);
end
tstart = tic;

U = zeros(5,10);
for i=1:N,
    tloop=tic;
    for j=1:10
        % compute controls
        U(:,j) = pids{j}.computeU(state.platforms{j}.getEX(),wp(:,j),0);
    end
    % step simulator
    qrsim.step(U);
    
    % wait so to run in real time
    wait = max(0,state.task.dt-toc(tloop));
    pause(wait);
end
    
% get reward
% qrsim.reward();

elapsed = toc(tstart);

fprintf('running %d times real time\n',(N*state.DT)/elapsed);
