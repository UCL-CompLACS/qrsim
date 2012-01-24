%function [e]=testSensorsNoiseModels()

clear all;
close all;
clc;
e = 1;

TOLFACTOR = 0.1;
MEANTOL = 1e-2;
global state;

N = 30000;

% some buffuers
eX=zeros(20,N);
X=zeros(13,N);
a=zeros(3,N);

% a control that in absence of noise gives perfect hover
U = [0;0;0.59004353928;0;11];

% create simulator object
qrsim = QRSim();

% load task parameters and do housekeeping
qrsim.init('TestSensorsTask');

disp('Generating data, this will take a good while');

for i=1:N
    
    % step simulator
    qrsim.step(U);
          
    eX(:,i)=state.platforms(1).eX;
    X(:,i)=state.platforms(1).X;
    
    if(mod(i,1000)==0)
        fprintf('.');
    end
    a(:,i)=state.platforms(1).a;
end
fprintf('\n');

% work out acceleration empirical std    
ea  = eX(14:16,:)-a(1:3,:);
eaSigma = std(ea,0,2);

if(abs(eaSigma(1)-state.platforms.params.sensors.ahars.accelerometer.SIGMA(1)) > (TOLFACTOR*state.platforms.params.sensors.ahars.accelerometer.SIGMA(1)) ||...
   abs(eaSigma(2)-state.platforms.params.sensors.ahars.accelerometer.SIGMA(2)) > (TOLFACTOR*state.platforms.params.sensors.ahars.accelerometer.SIGMA(2)) ||...
   abs(eaSigma(3)-state.platforms.params.sensors.ahars.accelerometer.SIGMA(3)) > (TOLFACTOR*state.platforms.params.sensors.ahars.accelerometer.SIGMA(3)))
    
   fprintf('accelerometer noise not as expected, test: [FAILED]\n'); 
   e = e && 1;
else
   fprintf('accelerometer noise as expected, test: [PASSED]\n'); 
   e = e && 0; 
end

% work out rotational velocity empirical std  
ew  = eX(10:12,:)-X(10:12,:);
ewSigma = std(ew,0,2);
if(abs(ewSigma(1)-state.platforms.params.sensors.ahars.gyroscope.SIGMA(1)) > (TOLFACTOR*state.platforms.params.sensors.ahars.gyroscope.SIGMA(1)) || ...
   abs(ewSigma(2)-state.platforms.params.sensors.ahars.gyroscope.SIGMA(2)) > (TOLFACTOR*state.platforms.params.sensors.ahars.gyroscope.SIGMA(2)) || ...
   abs(ewSigma(3)-state.platforms.params.sensors.ahars.gyroscope.SIGMA(3)) > (TOLFACTOR*state.platforms.params.sensors.ahars.gyroscope.SIGMA(3)) )
        
   fprintf('gyros noise not as expected, test: [FAILED]\n');
   e = e && 1;  
else
   fprintf('gyros noise as expected, test: [PASSED]\n');
   e = e && 0; 
end

% work out the orientation error
ew = eX(4:6,:)-X(4:6,:);

% since we know the noise is a Ornstein-Uhlenbeck process we can compute
% its parameters and compare it with the simulation parameters
axisLabels = 'xyz'; 

for i=1:3,
    
    [mu,sigma,lambda] = computeOUparameters(ew(i,:),state.platforms.params.sensors.ahars.orientationEstimator.dt);
    
    if((abs(mu) > MEANTOL) || ...
        (abs(sigma - state.platforms.params.sensors.ahars.orientationEstimator.SIGMA(i)) > (TOLFACTOR*state.platforms.params.sensors.ahars.orientationEstimator.SIGMA(i))) ||...
        (abs(lambda - state.platforms.params.sensors.ahars.orientationEstimator.BETA(i)) > (TOLFACTOR*state.platforms.params.sensors.ahars.orientationEstimator.BETA(i))) )        
        
        fprintf('orientationEstimator noise of axis %c not as expected, test: [FAILED]\n',axisLabels(i));
        e = e && 1; 
    else
        fprintf('orientationEstimator noise of axis %c as expected, test: [PASSED]\n',axisLabels(i));
        e = e && 0; 
    end
    
end

% work out altitude error
eh = eX(17,:)+X(3,:);

[mu,sigma,tau] = computeOUparameters(eh,state.platforms.params.sensors.ahars.orientationEstimator.dt);

if((abs(mu) > MEANTOL) || ...
        (abs(sigma - state.platforms.params.sensors.ahars.altimeter.SIGMA) > (TOLFACTOR*state.platforms.params.sensors.ahars.altimeter.SIGMA)) ||...
        (abs(tau - state.platforms.params.sensors.ahars.altimeter.TAU) > (TOLFACTOR*state.platforms.params.sensors.ahars.altimeter.TAU)) )        
        
        fprintf('altimeter noise not as expected, test: [FAILED]\n');
        e = e && 1; 
    else
        fprintf('altimeter noise as expected, test: [PASSED]\n');
        e = e && 0; 
end


ep = eX(1:3,:)-X(1:3,:);

t=(1:N)*state.DT;
figure();
plot(t,ep(1,:));

figure();
plot(ep(1,:),ep(2,:));
%clear global state;