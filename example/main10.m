% bare bones example of use of the QRSim() simulator object with one
% helicopter

clear all
close all
global state;

% only needed if using the pid controller
clear global pid;

% create simulator object
qrsim = QRSim();

% load task parameters and do housekeeping
qrsim.init('TaskKeepSpot');

% number of steps we run the simulation for
N = 3000;

wp = zeros(10,4);

for i=1:10
    wp(i,:) = [state.platforms(i).getX(1:3)',0];
end
tstart = tic;

U = zeros(5,10);
for i=1:N,
    tloop=tic;
    for j=1:10
        % compute controls
        U(:,j) = quadrotorPID(state.platforms(j).getEX(),wp(j,:));
    end
    % step simulator
    qrsim.step(U);
    
    % get reward
    % qrsim.reward();
    
    % wait so to run in real time
    wait = max(0,state.DT-toc(tloop));
    pause(wait);
end
elapsed = toc(tstart);

fprintf('running %d times real time\n',(N*state.DT)/elapsed);