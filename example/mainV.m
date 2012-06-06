% bare bones example of use of the QRSim() simulator object with one
% helicopter in order to track a defined velocity profile

clear all
close all
clc


% create simulator object
qrsim = QRSim();

% load task parameters and do housekeeping
state = qrsim.init('TaskKeepVel');

% number of steps we run the simulation for
N = 400;

% target velocity (in NED coordinates)
vt = [repmat([0.4;0;0],1,100),repmat([0;1;0],1,100),repmat([0;0;-1],1,100),repmat([-1;-1;0],1,100)];

pid = VelocityPID(state.DT);

X = zeros(3,N);

tstart = tic;

for i=1:N,
    tloop=tic;
    % compute controls
    U = pid.computeU(state.platforms{1}.getX(),vt(1:3,i),0);
    qrsim.task.setTargetVelocity(vt(:,i));
    % step simulator
    qrsim.step(U);
    
    X(:,i) = state.platforms{1}.getX(7:9);
    
    % wait so to run in real time
    wait = max(0,state.DT-toc(tloop));
    pause(wait);
end
% get reward
qrsim.reward();
    
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