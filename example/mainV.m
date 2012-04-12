% bare bones example of use of the QRSim() simulator object with one
% helicopter

clear all
close all
clc
global state;

% only needed if using the pid controller


% create simulator object
qrsim = QRSim();

% load task parameters and do housekeeping
qrsim.init('TaskKeepSpot');

% number of steps we run the simulation for
N = 400;

% target velocity
vt = [repmat([0.4;0;0],1,100),repmat([0;1;0],1,100),repmat([0;0;-1],1,100),repmat([-1;-1;0],1,100)];

X = zeros(3,N);

tstart = tic;

for i=1:N,
    tloop=tic;
    % compute controls
    U = quadrotorVelPID(state.platforms(1).getX(),vt(:,i));
    % step simulator
    qrsim.step(U);
    
    X(:,i) = state.platforms(1).getX(7:9);
    % get reward
    % qrsim.reward();
    
    % wait so to run in real time
    wait = max(0,state.DT-toc(tloop));
    pause(wait);
end
elapsed = toc(tstart);

figure();

for i=1:size(X,1),
    subplot(size(X,1),1,i);
    plot(X(i,:));
    hold on;
    plot(vt(i,:),'--r');
    axis([0 N -1 1]);
end    

fprintf('running %d times real time\n',(N*state.DT)/elapsed);