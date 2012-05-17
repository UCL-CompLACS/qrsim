% bare bones example of use of the QRSim() simulator object with one
% helicopter

clear all
close all
clc


% only needed if using the pid controller
clear global pid;

% create simulator object
qrsim = QRSim();

% load task parameters and do housekeeping
state = qrsim.init('TaskComplacs');

% number of steps we run the simulation for
N = 30000;


% the complacs path
wps=[ 6  0  0 14 14  8  8 16 16 19 22 22 24 24 30 30 24 24 32 32 32 40 43 46 49 49 55 49 49 63 63 57 57 63;
     -8 -8  0  0 -8 -8  0  0 -8 -4 -8  0  0 -8 -8 -4 -4  0  0 -8  0  0 -8  0  0 -8 -8 -8  0  0 -4 -4 -8 -8;
     -9 -9 -9 -9 -9 -9 -9 -9 -9 -9 -9 -9 -9 -9 -9 -9 -9 -9 -9 -9 -9 -9 -9 -9 -9 -9 -9 -9 -9 -9 -9 -9 -9 -9;
      0  0  0  0  0  0  0  0  0  0  0  0  0  0  0  0  0  0  0  0  0  0  0  0  0  0  0  0  0  0  0  0  0  0];  



wpidx = 1;
for i=1:N,  
    
    tloop = tic;
    ex = state.platforms{1}.getEX();
    if((norm(ex(1:3)-wps(1:3,wpidx))<0.4) && (wpidx<size(wps,2)))
        wpidx = wpidx+1;
    end    
    
    % compute controls
    U = quadrotorPID(ex,wps(:,wpidx)',state.DT);
    % step simulator
    qrsim.step(U);
    
    % get reward
    % qrsim.reward();
    
    % wait so to run in real time
    wait = max(0,state.DT-toc(tloop));
    pause(wait);
    
end
