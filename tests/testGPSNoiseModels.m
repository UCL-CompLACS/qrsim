function [e]=testGPSNoiseModels()

addpath('gps');

clear all;
close all;

TOL = 0.1;
plots = 0;

%%% run a reasonable simulation

N = 7000; % this give as much data as in the log

eX=zeros(20,N);
X=zeros(13,N);
a=zeros(3,N);

% a control that in absence of noise gives perfect hover
U = [0;0;0.59004353928;0;11];

% create simulator object
qrsim = QRSim();

% load task parameters and do housekeeping
state = qrsim.init('TestGPSTask');

disp('Generating data, this will take a while');

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

% compute the Allan variance 
dt = state.environment.gpsspacesegment.getDt();
K = dt/state.DT;
ep = eX(1:3,1:K:end)-X(1:3,1:K:end);

if(plots)   
    figure();
    plot(ep(1,:),ep(2,:));
    xlabel('e_{px}[m]');
    ylabel('e_{py}[m]');
    hold on;
end

datas.rate = 1/dt;
datas.freq = ep(1,:);

tts = [2^0 2^1 2^2 2^3 2^4 2^5 2^6 2^7 2^8 2^9 2^10 2^11]*dt;
[retvals, ~,~] = allan(datas,tts,'e_{px}',0);


%%%  compute the Allan variance from a log file

tts = tts(1:length(retvals));

d  = csvread('arTest2Video-8_3_111-14_27_53_gps.csv');
d = d(1:350,:);

lat = d(:,4)'./1e7;
lon = d(:,5)'./1e7;
h = d(:,6)'./1000;

[E,N,~,~] = llaToUtm([lat;lon;h]);
E = E-E(1);
N = N-N(1);

if (plots)
    plot(E,N,'r');
end

dt = 0.4;
datat.rate = 1/dt;
datat.freq = E;

ttt = [2^0 2^1 2^2 2^3 2^4 2^5 2^6 2^7 2^8 2^9 2^10 2^11]*dt;
[retvalt,~,~] = allan(datat,ttt,'x acc',0);

ttt = ttt(1:length(retvalt));

e = ~all(abs(retvalt-retvals(2:end))<TOL);

if(plots)    
    figure;
    loglog(tts,retvals,'-o');
    hold on;
    loglog(ttt,retvalt,'-or');
    grid on;    
end

if(e)
    fprintf('Test GPS noise [FAILED]\n');
else
    fprintf('Test GPS noise [PASSED]\n');
end

rmpath('gps');

end
