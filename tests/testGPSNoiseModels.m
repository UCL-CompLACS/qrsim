function [e]=testGPSNoiseModels()

addpath('gps');

%clear all;
close all;
clc;
e = 1;

TOLFACTOR = 0.1;
MEANTOL = 1e-2;

%retvals = [];

%for j=1:3

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
qrsim.init('TestGPSTask');

disp('Generating data, this will take a while');

for i=1:N
    
    % step simulator
    qrsim.step(U);
          
    eX(:,i)=state.platforms(1).getEX();
    X(:,i)=state.platforms(1).getX();
    
    if(mod(i,1000)==0)
        fprintf('.');
    end
    a(:,i)=state.platforms(1).getA();
end
fprintf('\n');

% compute the Allan variance to compare it with the ground thruth
dt = state.environment.gpsspacesegment.getDt();
K = dt/state.DT;
ep = eX(1:3,1:K:end)-X(1:3,1:K:end);

t=(1:N/K)*state.DT;

% figure();
% plot(t,ep(1,:));
% xlabel('time[s]');
% ylabel('altitude [m]');
% 
% 
% figure();
% plot(ep(1,:),ep(2,:));
% xlabel('e_{px}[m]');
% ylabel('e_{py}[m]');

datas.rate = 1/dt;
datas.freq = ep(1,:);

tts = [2^0 2^1 2^2 2^3 2^4 2^5 2^6 2^7 2^8 2^9 2^10 2^11]*dt;
[retvals, s, errorb] = allan(datas,tts,'e_{px}');

%retvals = [retval;retvals]; %#ok<AGROW>

%clear global state;

%end

tts = tts(1:length(retvals));

%avg = sum(retvals)./j;


fname = 'arTest2Video-8_3_111-14_27_53_gps.csv';
d  = csvread(['/home/rdenardi/complacs/qrsim/tests/gt/gps/fromar2/',fname]);
d = d(1:350,:);
    
t = d(:,1)'-d(1,1);
lat = d(:,4)'./1e7;
lon = d(:,5)'./1e7;
h = d(:,6)'./1000;

[E,N,zone,h] = lla2utm([lat;lon;h]);
E = E-E(1);
N = N-N(1);


figure;
plot(E,N);

dt = 0.4;
datat.rate = 1/dt;
datat.freq = E;

ttt = [2^0 2^1 2^2 2^3 2^4 2^5 2^6 2^7 2^8 2^9 2^10 2^11]*dt;
[retvalt, s, errorb] = allan(datat,ttt,'x acc');

ttt = ttt(1:length(retvalt));

figure;
loglog(tts,retvals,'-o');
hold on;
loglog(ttt,retvalt,'-or');
grid on;

rmpath('gps');

end