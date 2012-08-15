% bare bones example of use of the QRSim() simulator 
% with one of the the cats-mouse scenario

%clear all
close all

% include simulator
addpath(['..',filesep,'..',filesep,'sim']);
addpath(['..',filesep,'..',filesep,'controllers']);

% create simulator object
qrsim = QRSim();

% load task parameters and do housekeeping
state = qrsim.init('TaskCatsMouseNoiseless');
%state = qrsim.init('TaskCatsMouseNoisy');
%state = qrsim.init('TaskCatsMouseNoisyAndWindy');

U = zeros(2,qrsim.task.Nc);
tstart = tic;

for i=1:qrsim.task.durationInSteps,
    tloop=tic;
    
    mousePos = state.platforms{qrsim.task.Nc+1}.getEX(1:2);
    
    % a quick and by no means perfect way of 
    % computing velocity controls for each cat   
    for j=1:qrsim.task.Nc,
        % vector to the mouse
        u = mousePos - state.platforms{j}.getX(1:2);
        % if far away add 
        u = u  + (norm(u)/2)*state.platforms{qrsim.task.Nc+1}.getEX(18:19);
        % scale by the max allowed velocity
        U(:,j) = qrsim.task.velPIDs{j}.maxv*(u/norm(u));
    end
    
    
    % step simulator
    qrsim.step(U);
    
    % wait so to run in real time
    wait = max(0,state.DT-toc(tloop));
    pause(wait);
end

% get reward
fprintf('final reward: %f\n',qrsim.reward());

elapsed = toc(tstart);

fprintf('running %d times real time\n',(qrsim.task.durationInSteps*state.DT)/elapsed);
