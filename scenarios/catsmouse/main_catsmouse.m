% bare bones example of use of the QRSim() simulator 
% with one of the the cats-mouse scenario
%
% as a quick remainder, in this task which three quadrotors (cats) have to catch another
% quadrotor (mouse) AT THE END of the allotted time for the task.
% In other words we have only a final cost equal to the sum of the
% squared distances of the cats to the mouse. A large negative reward
% is returned if any of the helicopters goes outside of the flying area.
% For simplicity all quadrotors are supposed to fly at the same altitude.
% The initial position of the quadrotors is defined randomly
% (within reason) around the mouse; the mouse moves at a constant (max) speed
% and uses a predefined control law which pays more heed to cats that are close by.

clear all
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

% remainder:
% platforms with id 1..qrsim.task.Nc are cats
% the last platform (i.e. with id qrsim.task.Nc+1) is the mouse

% create a 2 x cats matrix of control inputs
% column i will contain the 2D NED velocity [vx;vy] in m/s for cat i 
U = zeros(2,qrsim.task.Nc);
tstart = tic;

% run the scenario and at every timestep generate a control
% input for each of the cats
for i=1:qrsim.task.durationInSteps,
    tloop=tic;
    
    % get the mouse position (note id qrsim.task.Nc+1)
    mousePos = state.platforms{qrsim.task.Nc+1}.getEX(1:2);
    
    % a quick and easy (and by no means perfect) way of 
    % computing velocity controls for each cat; replace it with your
    % control/learning algorithm.
    % (Note that for simplicity this control law tries to catch the mouse 
    % as soon as possible and not simply at the end of the allotted time.)
    for j=1:qrsim.task.Nc,
        % vector to the mouse
        u = mousePos - state.platforms{j}.getEX(1:2);
        % if far away add a weighted velocity to "predict" where the mouse will be
        u = u  + (norm(u)/2)*state.platforms{qrsim.task.Nc+1}.getEX(18:19);
        % scale by the max allowed velocity
        U(:,j) = qrsim.task.velPIDs{j}.maxv*(u/norm(u));
    end
    
    % step simulator
    qrsim.step(U);
    
    % wait so to run in real time
    % this can be commented out obviously
    wait = max(0,state.DT-toc(tloop));
    pause(wait);
end

% get final reward
% reminder: a large negative final reward (-1000) is returned in case of
% collisions or in case of any uav going outside the flight area 
fprintf('final reward: %f\n',qrsim.reward());

elapsed = toc(tstart);

fprintf('running %d times real time\n',(qrsim.task.durationInSteps*state.DT)/elapsed);
