
close all;
N=100000;


W20ft = 1;
T = 0.01;
fs=1/T;
Vfts = 1;
hft=5;

sigmaw = 0.1*W20ft;
sigmau = sigmaw/(0.177+0.000823*hft)^0.4;
sigmav = sigmau;


Lw = hft;
Lu = hft/(0.177+0.000823*hft)^1.2;
Lv = Lu;


%%% turbulence model
global state;

state.t = 0;
state.numRStreams = 0;

objparams.DT = T;
objparams.dt = T;
objparams.on = 1;
objparams.W6 = ft2m(W20ft);
objparams.direction = 0;
objparams.zOrigin = 0;

windModel = WindConstMean(objparams);

turbModel = AerodynamicTurbulenceMILF8785(objparams);
state.rStreams = RandStream.create('mrg32k3a','seed',sum(100*clock),'NumStreams',state.numRStreams,'CellOutput',1);

windModel.reset();
turbModel.reset();
uvwm = zeros(3,N);
X = [0;0;-ft2m(hft);0;0;0;0;0;0;0;0;0;0];
XandWind = [X;windModel.getLinear(X)];

for i=1:N
    turbModel.step(XandWind);
    uvwm(:,i) = m2ft(turbModel.getLinear([]));
end

[Pmuu,f]=pwelch(uvwm(1,:),rectwin(2^14),0, 2^14,fs);
[Pmvv,f]=pwelch(uvwm(2,:),rectwin(2^14),0, 2^14,fs);
[Pmww,f]=pwelch(uvwm(3,:),rectwin(2^14),0, 2^14,fs);


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

figure(2);
subplot(1,3,1);
semilogx(f,10*log10(puu),'g');
hold on;
semilogx(f,10*log10(Pmuu*0.25),'m');
grid on;
axis([0.01 100 -80 20]);

subplot(1,3,2);
semilogx(f,10*log10(pvv),'g');
hold on;
semilogx(f,10*log10(Pmvv*0.25),'m');
grid on;
axis([0.01 100 -80 20]);

subplot(1,3,3);
semilogx(f,10*log10(pww),'g');
hold on;
semilogx(f,10*log10(Pmww*0.25),'m');
grid on;
axis([0.01 100 -80 20]);


figure(3);
subplot(1,3,1);
semilogx(f,10*log10((Pmuu*0.25))-10*log10(puu),'m');
grid on;

subplot(1,3,2);
semilogx(f,10*log10((Pmvv*0.25))-10*log10(pvv),'m');
grid on;

subplot(1,3,3);
semilogx(f,10*log10((Pmww*0.25))-10*log10(pww),'m');
grid on;

TOL = 10;

muu =  mean(abs(10*log10((Pmuu*0.25))-10*log10(puu)));
mvv =  mean(abs(10*log10((Pmvv*0.25))-10*log10(pvv)));
mww =  mean(abs(10*log10((Pmww*0.25))-10*log10(pww)));

if(all([muu,mvv,mww] < [TOL,TOL,TOL]))
    disp('passed');
else
    disp('failed');
end


