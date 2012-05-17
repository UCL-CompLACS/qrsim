% bare bones example of use of the QRSim() simulator object with one
% helicopter

clear all
close all


% only needed if using the pid controller
clear global pid;

addpath('../sim');

% create simulator object
qrsim = QRSim();

% load task parameters and do housekeeping
state = qrsim.init('TaskKeepSpot');

% number of steps we run the simulation for
N = 3000;

wp = [state.platforms{1}.getX(1:3)',0];

tstart = tic;

for i=1:N,
    tloop=tic;
    % compute controls
    U = quadrotorPID(state.platforms{1}.getEX(),wp,state.DT);
    % step simulator
    qrsim.step(U);
    
    % get reward
    % qrsim.reward();
    
    % wait so to run in real time
    %wait = max(0,state.DT-toc(tloop));
    %pause(wait);
end
elapsed = toc(tstart);

fprintf('running %d times real time\n',(N*state.DT)/elapsed);