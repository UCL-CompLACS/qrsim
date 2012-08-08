% bare bones example of use of the QRSim() simulator object with one
% helicopter

clear all
close all

% include simulator
addpath(['..',pathsep,'sim:..',pathsep',controllers');

% create simulator object
qrsim = QRSim();

% load task parameters and do housekeeping
%state = qrsim.init('TaskCatsMouseNoiseless');
%state = qrsim.init('TaskCatsMouseNoisy');
state = qrsim.init('TaskCatsMouseWindy');

% number of steps we run the simulation for
N = 3000;

wp = state.platforms{1}.getX(1:3);

% creat PID controller omainbject
pid = WaypointPID(state.DT);

tstart = tic;

for i=1:N,
    tloop=tic;
    % compute controls
    U = pid.computeU(state.platforms{1}.getEX(),wp,0);
    %U = [0;0.02;0.595;0;12];
    % step simulator
    qrsim.step(U);
    
    % wait so to run in real time
    wait = max(0,state.DT-toc(tloop));
    pause(wait);
end

% get reward
% qrsim.reward();

elapsed = toc(tstart);

fprintf('running %d times real time\n',(N*state.DT)/elapsed);
