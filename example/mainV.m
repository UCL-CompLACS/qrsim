% bare bones example of use of the QRSim() simulator object with one
% helicopter in order to track a defined velocity profile

clear all
close all
clc


% create simulator object
qrsim = QRSim();

% load task parameters and do housekeeping
state = qrsim.init('TaskKeepVel');


% target velocity (in NED coordinates)
vt = [repmat([1.4;0;0],1,200),repmat([0;1;0],1,200),repmat([0;0;-1],1,200),repmat([-1;-1;0],1,200)];

% number of steps we run the simulation for
N = size(vt,2);

pid = VelocityPID(state.DT);

X = zeros(3,N);

tstart = tic;

for i=1:N,
    tloop=tic;
    % one should alway make sure that the uav is valid
    % i.e. no collision or out of area event happened
    if(state.platforms{1}.isValid())
        % compute controls
        U = pid.computeU(state.platforms{1}.getEX(),vt(1:3,i),0);
        state.task.setTargetVelocity(vt(:,i));
        % step simulator
        qrsim.step(U);
        
        X(:,i) = [state.platforms{1}.getEX(18:19);-state.platforms{1}.getEX(20)];
    end
    % wait so to run in real time
    wait = max(0,state.task.dt-toc(tloop));
    pause(wait);
end
% get reward
% qrsim.reward();

elapsed = toc(tstart);

figure();

for i=1:size(X,1),
    subplot(size(X,1),1,i);
    plot((1:N)*state.task.dt,X(i,:));
    hold on;
    plot((1:N)*state.task.dt,vt(i,:),'--r');
    axis([0 N*state.task.dt -3 3]);
    xlabel('t [s]');
    ylabel('[m/s]');
end

fprintf('running %d times real time\n',(N*state.DT)/elapsed);
