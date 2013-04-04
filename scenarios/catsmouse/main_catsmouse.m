% bare bones example of use of the QRSim() simulator
% with one of the cats-mouse scenario
%
% as a quick remainder, in this task three quadrotors (cats) have to catch another
% quadrotor (mouse) AT THE END of the allotted time for the task.
% In other words we have only a final cost equal to the sum of the
% squared distances of the cats to the mouse. A large negative reward
% is returned if any of the helicopters goes outside of the flying area.
% For simplicity all quadrotors are supposed to fly at the same altitude.
% The initial position of the quadrotors is defined randomly
% (within reason) around the mouse; the mouse moves at a constant (max) speed
% and uses a predefined control law which pays more heed to cats that are close by.

% REMINDER:
% to turn of visualization set the task parameter taskparams.display3d.on to 0

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

% reminder:
% platforms with id 1..state.task.Nc are cats
% the last platform (i.e. with id state.task.Nc+1) is the mouse

% create a 2 x cats matrix of control inputs
% column i will contain the 2D NED velocity [vx;vy] in m/s for cat i
U = zeros(2,state.task.Nc);
tstart = tic;

% run the scenario and at every timestep generate a control
% input for each of the uavs
% note: the duration of the task might need changing depending
% on the way the learning is carried out
for i=1:state.task.durationInSteps,
    tloop=tic;
    
    % get the mouse position (note id state.task.Nc+1)
    mousePos = state.platforms{state.task.Nc+1}.getEX(1:2);
    
    % as example we use a quick and easy way of computing velocity controls for each cat; 
    % REPLACE IT with your control/learning algorithm.
    % (Note that for simplicity this control law tries to catch the mouse
    % as soon as possible and not simply at the end of the allotted time.)
    for j=1:state.task.Nc,
        % vector to the mouse
        u = mousePos - state.platforms{j}.getEX(1:2);
        
        % if far away add a weighted velocity to "predict" where the mouse will be
        u = u  + (norm(u)/2)*state.platforms{state.task.Nc+1}.getEX(18:19);
        
        % keep away from other cats if closer than 2*collisionDistance
        for k = 1:state.task.Nc,
            % one should alway make sure that the uav is valid 
            % i.e. no collision or out of area event happened
            if(state.platforms{k}.isValid())                  
                d = state.platforms{j}.getEX(1:2) - state.platforms{k}.getEX(1:2);
                if((k~=j)&&(norm(d)<2*state.platforms{j}.getCollisionDistance()))
                    u = u + (1/(norm(d)-state.platforms{j}.getCollisionDistance()))*(d/norm(d));
                end
            end
        end
        
        % scale by the max allowed velocity
        U(:,j) = state.task.velPIDs{j}.maxv*(u/norm(u));
    end
    
    % step simulator
    qrsim.step(U);
    
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

fprintf('running %d times real time\n',(state.task.durationInSteps*state.DT)/elapsed);
