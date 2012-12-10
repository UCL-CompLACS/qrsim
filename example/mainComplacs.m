% bare bones example of use of the QRSim() simulator object with one
% helicopter

clear all
close all
clc

% create simulator object
qrsim = QRSim();

% load task parameters and do housekeeping
state = qrsim.init('TaskComplacs');

% number of steps we run the simulation for
N = 30000;


% the complacs path
wps=[ 6  0  0 14 14  8  8 16 16 19 22 22 24 24 30 30 24 24 32 32 32 40 43 46 49 49 55 49 49 63 63 57 57 63;
    -8 -8  0  0 -8 -8  0  0 -8 -4 -8  0  0 -8 -8 -4 -4  0  0 -8  0  0 -8  0  0 -8 -8 -8  0  0 -4 -4 -8 -8;
    -9 -9 -9 -9 -9 -9 -9 -9 -9 -9 -9 -9 -9 -9 -9 -9 -9 -9 -9 -9 -9 -9 -9 -9 -9 -9 -9 -9 -9 -9 -9 -9 -9 -9];

% another path
%wps=[ 6  0  0  6  6  0  8  8  8 14 14 14 16 19 22 24 27 30 35 32 35 38 35 46 40 40 43 40 40 46;
%     -8 -8 -4 -4  0  0  0 -8  0  0 -8  0  0 -8  0  0 -8  0  0 -8  0 -8  0  0  0 -4 -4 -4 -8 -8;
%     -9 -9 -9 -9 -9 -9 -9 -9 -9 -9 -9 -9 -9 -9 -9 -9 -9 -9 -9 -9 -9 -9 -9 -9 -9 -9 -9 -9 -9 -9];

% the PID controller
pid = WaypointPID(state.DT);

wpidx = 1;
for i=1:N,
    % one should alway make sure that the uav is valid
    % i.e. no collision or out of area event happened
    if(state.platforms{1}.isValid())
        tloop = tic;
        ex = state.platforms{1}.getEX();
        if((norm(ex(1:3)-wps(:,wpidx))<0.4) && (wpidx<size(wps,2)))
            wpidx = wpidx+1;
        end
        
        % compute controls
        U = pid.computeU(ex,wps(:,wpidx),0);
        % step simulator
        qrsim.step(U);        
    end
    % wait so to run in real time
    wait = max(0,state.task.dt-toc(tloop));
    pause(wait);
    
end

% get reward
% qrsim.reward();

