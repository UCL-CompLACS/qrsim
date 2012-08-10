% bare bones example of use of the QRSim() simulator 
% with one of the the cats-mouse scenario

%clear all
close all

% include simulator
addpath('../../sim');
addpath('../../controllers');

% create simulator object
qrsim = QRSim();

% load task parameters and do housekeeping
state = qrsim.init('TaskCatsMouseNoiseless');
%state = qrsim.init('TaskCatsMouseNoisy');
%state = qrsim.init('TaskCatsMouseWindy');


tstart = tic;

for i=1:qrsim.task.durationInSteps,
    tloop=tic;
    
    % compute acceleration controls for each cat    
    U = zeros(2,3);
    
    % step simulator
    qrsim.step(U);
    
    % wait so to run in real time
    wait = max(0,state.DT-toc(tloop));
    pause(wait);
end

% get reward
fprintf('final reward: %f',qrsim.reward());

elapsed = toc(tstart);

fprintf('running %d times real time\n',(qrsim.task.durationInSteps*state.DT)/elapsed);
