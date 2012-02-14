clear all;
close all;

N=100000;

%W6ms = 1;
W20ft = 1;%m2ft(W6ms);
T = 0.01;
fs=1/T;
%Vms = 0.3;
Vfts = 1;%m2ft(Vms);
%hm = 1;
hft=5;%m2ft(hm);


sigmaw = 0.1*W20ft;
sigmau = sigmaw/(0.177+0.000823*hft)^0.4;
sigmav = sigmau;


Lw = hft;
Lu = hft/(0.177+0.000823*hft)^1.2;
Lv = Lu;

% Vfts = 10;
% 
% sigmau = 10;
% sigmav = 10;
% sigmaw = 10;
% 
% Lv = 1000;
% Lu = 1000;
% Lw = 1000;

%%% time domain
uvwg=zeros(3,1);
eta=randn(3,N);
uvwgms = zeros(3,N);

for i=1:N,   
   uvwg(1) = (1-(Vfts*T)/Lu)*uvwg(1)+sqrt((2*Vfts*T)/Lu)*sigmau*eta(1,i); 
   uvwg(2) = (1-(Vfts*T)/Lv)*uvwg(2)+sqrt((2*Vfts*T)/Lv)*sigmav*eta(2,i); 
   uvwg(3) = (1-(Vfts*T)/Lw)*uvwg(3)+sqrt((2*Vfts*T)/Lw)*sigmaw*eta(3,i); 
   uvwgms(:,i) = uvwg;
end

[Puu,f]=pwelch(uvwgms(1,:),rectwin(2^14),0,  2^14,fs);
[Pvv,f]=pwelch(uvwgms(2,:),rectwin(2^14),0,  2^14,fs);
[Pww,f]=pwelch(uvwgms(3,:),rectwin(2^14),0,  2^14,fs);


%%% theoretical
w = 2*pi*f;
puu = zeros(1,length(w));
pvv = zeros(1,length(w));
pww = zeros(1,length(w));

for i=1:length(w)
    puu(1,i) = ((2*(sigmau^2)*Lu)/(pi*Vfts))*(1/(1+(Lu*(w(i)/Vfts))^2));
    pvv(1,i) = (((sigmav^2)*Lv)/(pi*Vfts))*((1+3*(Lv*w(i)/Vfts)^2)/(1+(Lv*(w(i)/Vfts))^2)^2);
    pww(1,i) = (((sigmaw^2)*Lw)/(pi*Vfts))*((1+3*(Lw*w(i)/Vfts)^2)/(1+(Lw*(w(i)/Vfts))^2)^2);
end

%%% simulink
data = load('wind_test.mat');


[Pduu,tmp]=pwelch(data.ans(2,:),rectwin(2^14),0, 2^14,fs);
[Pdvv,tmp]=pwelch(data.ans(3,:),rectwin(2^14),0, 2^14,fs);
[Pdww,tmp]=pwelch(data.ans(4,:),rectwin(2^14),0, 2^14,fs);


%%% turbulence model
global state;

state.t = 0;

state.numRStreams = 0;
objparams.DT = T;
objparams.dt = T;
objparams.on = 1;
objparams.W6 = ft2m(W20ft);

turbModel = AerodynamicTurbulenceMILF8785(objparams);
state.rStreams = RandStream.create('mrg32k3a','seed',sum(100*clock),'NumStreams',state.numRStreams,'CellOutput',1);

turbModel.reset();
uvwm = zeros(3,N);
XandWind = [0;0;ft2m(hft);0;0;0;0;0;0;0;0;0;0;ft2m(Vfts);0;0];

for i=1:N
turbModel.step(XandWind);
uvwm(:,i) = turbModel.getLinear([]);
end

[Pmuu,tmp]=pwelch(uvwm(1,:),rectwin(2^14),0, 2^14,fs);
[Pmvv,tmp]=pwelch(uvwm(2,:),rectwin(2^14),0, 2^14,fs);
[Pmww,tmp]=pwelch(uvwm(3,:),rectwin(2^14),0, 2^14,fs);


figure(2);
subplot(1,3,1);
semilogx(f,10*log10(Puu*0.25));
hold on;
semilogx(f,10*log10(Pduu*0.25),'r');
semilogx(f,10*log10(puu),'g');
semilogx(f,10*log10(Pmuu*0.25),'m');
grid on;
axis([0.01 100 -80 20]);

subplot(1,3,2);
semilogx(f,10*log10(Pvv*0.25));
hold on;
semilogx(f,10*log10(Pdvv*0.25),'r');
semilogx(f,10*log10(pvv),'g');
semilogx(f,10*log10(Pmvv*0.25),'m');
grid on;
axis([0.01 100 -80 20]);

subplot(1,3,3);
semilogx(f,10*log10(Pww*0.25));
hold on;
semilogx(f,10*log10(Pdww*0.25),'r');
semilogx(f,10*log10(pww),'g');
semilogx(f,10*log10(Pmww*0.25),'m');
grid on;
axis([0.01 100 -80 20]);


%figure;
%plot(xcorr(data.ans(2,:),'biased'))
