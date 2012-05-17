function [e]=testSensorsNoiseModels()

addpath('sensors');

clear all;
close all;

e = 1;

TOLFACTOR = 0.4;
MEANTOL = 1e-2;

N = 50000;

% some buffuers
eX=zeros(20,N);
X=zeros(13,N);
a=zeros(3,N);

% a control that in absence of noise gives perfect hover
U = [0;0;0.59004353928;0;11];

% create simulator object
qrsim = QRSim();

% load task parameters and do housekeeping
state = qrsim.init('TestSensorsTask');

disp('Generating data, this will take a good while');

for i=1:N
    
    % step simulator
    qrsim.step(U);
          
    eX(:,i)=state.platforms{1}.getEX();
    X(:,i)=state.platforms{1}.getX();
    
    
    if(mod(i,1000)==0)
        fprintf('.');
    end
    a(:,i)=state.platforms{1}.getA();
end
fprintf('\n');

% work out acceleration empirical std    
ea  = eX(14:16,:)-a(1:3,:);
eaSigma = std(ea,0,2);

SIGMA = state.platforms{1}.getAHARS().getAccelerometer().getSigma();

if(abs(eaSigma(1)-SIGMA(1)) > (TOLFACTOR*SIGMA(1)) ||...
   abs(eaSigma(2)-SIGMA(2)) > (TOLFACTOR*SIGMA(2)) ||...
   abs(eaSigma(3)-SIGMA(3)) > (TOLFACTOR*SIGMA(3)))
    
   fprintf('accelerometer noise not as expected, test: [FAILED]\n'); 
   e = e && 1;
else
   fprintf('accelerometer noise as expected, test: [PASSED]\n'); 
   e = e && 0; 
end

% work out rotational velocity empirical std  
ew  = eX(10:12,:)-X(10:12,:);
ewSigma = std(ew,0,2);

SIGMA = state.platforms{1}.getAHARS().getGyroscope().getSigma();

if(abs(ewSigma(1)-SIGMA(1)) > (TOLFACTOR*SIGMA(1)) || ...
   abs(ewSigma(2)-SIGMA(2)) > (TOLFACTOR*SIGMA(2)) || ...
   abs(ewSigma(3)-SIGMA(3)) > (TOLFACTOR*SIGMA(3)) )
        
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

SIGMA = state.platforms{1}.getAHARS().getOrientationEstimator().getSigma();
BETA = state.platforms{1}.getAHARS().getOrientationEstimator().getBeta();
for i=1:3,
    
    [mu,sigma,lambda] = computeOUparameters(ew(i,:),state.platforms{1}.getAHARS().getOrientationEstimator().getDt());
    
    if((abs(mu) > MEANTOL) || ...
        (abs(sigma - SIGMA(i)) > (TOLFACTOR*SIGMA(i))) ||...
        (abs(lambda - BETA(i)) > (TOLFACTOR*BETA(i))) )        
        
        fprintf('orientationEstimator noise of axis %c not as expected, test: [FAILED]\n',axisLabels(i));
        e = e && 1; 
    else
        fprintf('orientationEstimator noise of axis %c as expected, test: [PASSED]\n',axisLabels(i));
        e = e && 0; 
    end
    
end

% work out altitude error
eh = eX(17,:)+X(3,:);

[mu,sigma,tau] = computeGMparameters(eh,state.platforms{1}.getAHARS().getAltimeter().getDt());

SIGMA = state.platforms{1}.getAHARS().getAltimeter().getSigma();
TAU = state.platforms{1}.getAHARS().getAltimeter().getTau();

if((abs(mu) > MEANTOL) || ...
        (abs(sigma - SIGMA) > (TOLFACTOR*SIGMA)) ||...
        (abs(tau - TAU) > (TOLFACTOR*TAU)) )        
        
        fprintf('altimeter noise not as expected, test: [FAILED]\n');
        e = e && 1; 
    else
        fprintf('altimeter noise as expected, test: [PASSED]\n');
        e = e && 0; 
end

rmpath('sensors');

end