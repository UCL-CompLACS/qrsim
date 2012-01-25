%function [e]=testGPSNoiseModels()

clear all;
close all;
clc;
e = 1;

TOLFACTOR = 0.1;
MEANTOL = 1e-2;
global state;

N = 10000;

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

disp('Generating data, this will take a while');

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

% compute the Allan variance to compare it with the ground thruth

K = state.platforms.params.sensors.gpsreceiver.dt/state.DT;
ep = eX(1:3,1:K:end)-X(1:3,1:K:end);

t=(1:N/K)*state.DT;

figure();
plot(t,ep(1,:));
xlabel('time[s]');
ylabel('altitude [m]');


figure();
plot(ep(1,:),ep(2,:));
xlabel('e_{px}[m]');
ylabel('e_{py}[m]');

data.rate = 1/state.platforms.params.sensors.gpsreceiver.dt;
data.freq = ep(1,:);

[retval, s, errorb] = allan(data,[2^0 2^1 2^2 2^3 2^4 2^5 2^6 2^7 2^8 2^9 2^10 2^11]*state.platforms.params.sensors.gpsreceiver.dt,'e_{px}');
