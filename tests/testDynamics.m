function [ e ] = testDynamics()
%test that the response of the dynamic model to the control input matches
%the flight data

clear all;
close all;

cd('dynamics');

plots = 0;


e = 0;

% run the sim using logged inputs and comparing outputs with logged data

e = e | compareThrustToLogs(plots);

e = e | compareRatationToLogs(plots);

e = e | compareTranslationToLogs(plots);

cd('..');

end


function e = compareTranslationToLogs(plots)

UAVCTRL_2_SI = [-degsToRads(0.025),-degsToRads(0.025),1/4097,-degsToRads(254.760/2047),1]; % conversion factors

data = csvread('outdoorRvc4modelling_2011-09-30-11-23-11synced4.csv');  % flight data file

shift = 25;
N = 8000;

% preallocate state array
X = zeros(N,6);

% Observation variables: vx,vy,vz,vxdot,vydot,vzdot, 
Z = [data(shift+(1:N),7:9),data(shift+(1:N),16:17),-data(shift+(1:N),18)];

% Input variables: pitch,roll,throttle,yaw,batt 
data(1:N,21) = data(1:N,21)+592;
U = ([data(1:N,19:22),11*ones(N,1)].*repmat(UAVCTRL_2_SI,N,1))';

% create simulator object
qrsim = QRSim();

% load task parameters and do housekeeping
state = qrsim.init('TaskDynamicsCompareTranslation');

state.platforms{1}.setX([0;0;-25;data(1,4:6)';0;0;0;data(1,10:12)']);

for i=1:N
    % step simulator
    qrsim.step(U(:,i));
    
    uvw = state.platforms{1}.getX(7:9);
    a = state.platforms{1}.getA();
    D = dcm(state.platforms{1}.getX(1:6))';
    
    X(i,:) = [D*uvw;(D*a+[0;0;9.81])];
end

% Generate new time axis
t = (0:state.DT:(N-1)*state.DT)';

e = ~all(mean((X-Z).^2)<15);

if (plots)
    figure();
    subplot(3,1,1)
    plot(t,X(:,1));
    hold on;
    plot(t,Z(:,1),'r'); 
    subplot(3,1,2)
    plot(t,X(:,2));
    hold on;
    plot(t,Z(:,2),'r'); 
    subplot(3,1,3)
    plot(t,X(:,3));
    hold on;
    plot(t,Z(:,3),'r');
    
    figure();
    subplot(3,1,1)
    plot(t,X(:,4));
    hold on;
    plot(t,Z(:,4),'r'); 
    subplot(3,1,2)
    plot(t,X(:,5));
    hold on;
    plot(t,Z(:,5),'r'); 
    subplot(3,1,3)
    plot(t,X(:,6));
    hold on;
    plot(t,Z(:,6),'r');
end

% clear the state
clear state;

if(e)
    fprintf('Test comparison of translation with logged flight data [FAILED]\n');
else
    fprintf('Test comparison of translation with logged flight data [PASSED]\n');
end


end

function e = compareThrustToLogs(plots)

UAVCTRL_2_SI = [-degsToRads(0.025),-degsToRads(0.025),1/4097,-degsToRads(254.760/2047)]; % conversion factors

data = csvread('thrustTestSquareVariable_Batt1_2011-08-23-17-08-26_50Hz.csv');  % flight data file

N = length(data);
data = data(1:N,:);

% preallocate state array
X = zeros(N,1);

% Observation variables: thrust, 
Z = data(:,3);

% Input variables pt;rl;th;ya;
U = zeros(5,N);
U(3,:) = (data(:,2).*UAVCTRL_2_SI(3))';
U(5,:) = data(:,4)';

% create simulator object
qrsim = QRSim();

% load task parameters and do housekeeping
state = qrsim.init('TaskDynamicsCompareThrust');

for i=1:N
    % step simulator
    qrsim.step(U(:,i));
    
    X(i,1) = state.platforms{1}.getX(13);
end

% Generate new time axis
t = (0:state.DT:(N-1)*state.DT)';

e = ~all(mean((X-Z).^2)<1);

if (plots)
    figure();
    plot(t,X(:,1));
    hold on;
    plot(t,Z(:,1),'r');
end

% clear the state
clear state;

if(e)
    fprintf('Test comparison of thrust with logged flight data [FAILED]\n');
else
    fprintf('Test comparison of thrust with logged flight data [PASSED]\n');
end


end


function e = compareRatationToLogs(plots)

UAVCTRL_2_SI = [-degsToRads(0.025),-degsToRads(0.025),1/4097,-degsToRads(254.760/2047)]; % conversion factors

data = csvread('preliminaryRotation_allBalanced01_2011-09-02-20-47-53_synced-50Hz.csv');  % flight data file

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

% create simulator object
qrsim = QRSim();

% load task parameters and do housekeeping
state = qrsim.init('TaskDynamicsCompareRotations');

for i=1:N
    % step simulator
    qrsim.step(U(:,i));
    
    X(i,:) = [state.platforms{1}.getX(4:6);state.platforms{1}.getX(10:12)]';
    
end

% Generate new time axis
t = (0:state.DT:(N-1)*state.DT)';

e = ~all(mean((X(:,1:6)-Z(:,1:6)).^2)<[0.001,0.001,0.02,0.03,0.02,0.03]);

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
clear state;

if(e)
    fprintf('Test comparison of rotation with logged flight data [FAILED]\n');
else
    fprintf('Test comparison of rotation with logged flight data [PASSED]\n');
end

end
