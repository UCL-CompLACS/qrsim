%clear all;
close all;

N=100000;


W20ft = 1;
T = 0.01;
fs=1/T;
Vfts = 100;
hft=50;

sigmaw = 0.1*W20ft;
sigmau = sigmaw/(0.177+0.000823*hft)^0.4;
sigmav = sigmau;


Lw = hft;
Lu = hft/(0.177+0.000823*hft)^1.2;
Lv = Lu;


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
puu = zeros(length(w),1);
pvv = zeros(length(w),1);
pww = zeros(length(w),1);

for i=1:length(w)
    puu(i,1) = ((2*(sigmau^2)*Lu)/(pi*Vfts))*(1/(1+(Lu*(w(i)/Vfts))^2));
    pvv(i,1) = (((sigmav^2)*Lv)/(pi*Vfts))*((1+3*(Lv*w(i)/Vfts)^2)/(1+(Lv*(w(i)/Vfts))^2)^2);
    pww(i,1) = (((sigmaw^2)*Lw)/(pi*Vfts))*((1+3*(Lw*w(i)/Vfts)^2)/(1+(Lw*(w(i)/Vfts))^2)^2);
end

%%% simulink
data = load('windlog_1V5h1w20_0p0t0p.mat');


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
objparams.W6 = ft2m(W20ft/(log(hft/0.15)/log(20/0.15)));
objparams.direction = 0;
objparams.zOrigin = 0;

phi = 0;
theta = 0;
psi = 0;
D = angle2dcm(psi,theta,phi);


% need to get body velocities from airspeed and plug it in below
X = [0;0;-ft2m(hft);0;0;0;0;ft2m(Vfts)+objparams.W6;0;0;0;0;0];
state.windModel = WindConstMean(objparams);

objparams.W6 = ft2m(W20ft);
state.turbModel = AerodynamicTurbulenceMILF8785(objparams);
state.rStreams = RandStream.create('mrg32k3a','seed',sum(100*clock),'NumStreams',state.numRStreams,'CellOutput',1);

state.windModel.reset();
state.turbModel.reset();
uvwm = zeros(3,N);

for i=1:N
    state.turbModel.step(X);
    uvwm(:,i) = m2ft(state.turbModel.getLinear([]));
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


figure(3);
subplot(1,3,1);
semilogx(f,10*log10((Puu*0.25))-10*log10(puu));
hold on;
semilogx(f,10*log10((Pduu*0.25))-10*log10(puu),'r');
semilogx(f,10*log10((Pmuu*0.25))-10*log10(puu),'m');
grid on;

subplot(1,3,2);
semilogx(f,10*log10((Pvv*0.25))-10*log10(pvv));
hold on;
semilogx(f,10*log10((Pdvv*0.25))-10*log10(pvv),'r');
semilogx(f,10*log10((Pmvv*0.25))-10*log10(pvv),'m');
grid on;

subplot(1,3,3);
semilogx(f,10*log10((Pww*0.25))-10*log10(pww));
hold on;
semilogx(f,10*log10((Pdww*0.25))-10*log10(pww),'r');
semilogx(f,10*log10((Pmww*0.25))-10*log10(pww),'m');
grid on;

TOL = 2;

muu =  mean(abs(10*log10((Pmuu*0.25))-10*log10(puu)));
mvv =  mean(abs(10*log10((Pmvv*0.25))-10*log10(pvv)));
mww =  mean(abs(10*log10((Pmww*0.25))-10*log10(pww)));

if(all([muu,mvv,mww] < [TOL,TOL,TOL]))
   disp('passed'); 
else
    disp('failed');
end    

 
