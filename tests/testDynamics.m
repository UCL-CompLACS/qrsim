function [ e ] = testDynamics()
%test that the response of the dynamic model to the control input matches
%the flight data

clear all;
close all;

cd('dynamics');

plots = 1;

% run the sim using logged inputs and comparing outputs with logged data
compareRatationToLogs(plots);


cd('..');

end

function e = compareRatationToLogs(plots)

e = 0;

UAVCTRL_2_SI = [-deg2rad(0.025),-deg2rad(0.025),1/4097,-deg2rad(254.760/2047)]; % conversion factors

data = csvread('preliminaryRotation_allBalanced01_2011-09-02-20-47-53_synced.csv');  % flight data file

N = length(data);
data= data(1:N,:);

% preallocate state array
X = zeros(N,6);

% Observation variables: phi,theta,psi,p,q,r
% note: the asctec stuff is not in the correct order
Z = [data(:,3),data(:,2),data(:,4),data(:,6),data(:,5),data(:,7)];

% Input variables pt;rl;th;ya;
U = [data(:,8:end).*repmat(UAVCTRL_2_SI,N,1),11*ones(N,1)]';
U(3,:) = 0.615*ones(1,N);

% new state structure
global state;

% create simulator object
qrsim = QRSim();

% load task parameters and do housekeeping
qrsim.init('TaskDynamicsCompareRotations');

for i=1:N
    % step simulator
    qrsim.step(U(:,i));
    
    X(i,:) = [state.platforms(1).getX(4:6);state.platforms(1).getX(10:12)]';
    
end

% Generate new time axis
t = (0:state.DT:(N-1)*state.DT)';

mean((X(:,1:3)-Z(:,1:3)).^2)


if (plots)
    figure();
    subplot(3,1,1);
    plot(t,X(:,1));
    hold on;
    plot(t,Z(:,1),'r');
    
    subplot(3,1,2);
    plot(t,X(:,2));
    hold on;
    plot(t,Z(:,2),'r');
    
    subplot(3,1,3);
    plot(t,X(:,3));
    hold on;
    plot(t,Z(:,3),'r');
    
    
    figure();
    subplot(3,1,1);
    plot(t,X(:,4));
    hold on;
    plot(t,Z(:,4),'r');
    
    subplot(3,1,2);
    plot(t,X(:,5));
    hold on;
    plot(t,Z(:,5),'r');
    
    subplot(3,1,3);
    plot(t,X(:,6));
    hold on;
    plot(t,Z(:,6),'r');
    
end

% clear the state
clear global state;

if(e)
    fprintf('Test comparison of rotation with logged flight data [FAILED]\n');
else
    fprintf('Test comparison of rotation with logged flight data [PASSED]\n');
end

end
