function e = testWind()

clear all;
close all;

e = 0;
N = 100000;
T = 0.01;
TOL = 5;
plots = 1;

cd('wind');

%%% model parameters
runSim();

% Vfts = 1; hft = 5; W20ft = 1; phi = 0; theta = 0; psi = 0; dir=0;
% e = e | runAndCompare('theoretical',T,W20ft,Vfts,dir,hft,phi,theta,psi,N,TOL,plots);
% 
% Vfts = 10; hft = 50; W20ft = 10; phi = 0; theta = 0; psi = 0; dir=0;
% e = e | runAndCompare('theoretical',T,W20ft,Vfts,dir,hft,phi,theta,psi,N,TOL,plots);
% 
% Vfts = 100; hft = 50; W20ft = 10; phi = 0; theta = 0; psi = 0; dir=0;
% e = e | runAndCompare('theoretical',T,W20ft,Vfts,dir,hft,phi,theta,psi,N,TOL,plots);
% 
% Vfts = 10; hft = 5; W20ft = 10; phi = 0; theta = 0; psi = 0; dir=0;
% e = e | runAndCompare('theoretical',T,W20ft,Vfts,dir,hft,phi,theta,psi,N,TOL,plots);
% 
% Vfts = 10; hft = 50; W20ft = 10; phi = 0; theta = 0; psi = 0; dir=0;
% e = e | runAndCompare('theoretical',T,W20ft,Vfts,dir,hft,phi,theta,psi,N,TOL,plots);
% 
% Vfts = 30; hft = 100; W20ft = 10; phi = 0; theta = 0; psi = 0; dir=0;
% e = e | runAndCompare('theoretical',T,W20ft,Vfts,dir,hft,phi,theta,psi,N,TOL,plots);
% 
% Vfts = 10; hft = 500; W20ft = 10; phi = 0; theta = 0; psi = 0; dir=0;
% e = e | runAndCompare('theoretical',T,W20ft,Vfts,dir,hft,phi,theta,psi,N,TOL,plots);
% 
% Vfts = 10; hft = 10; W20ft = 1; phi = 0; theta = 0; psi = 0; dir=0;
% e = e | runAndCompare('theoretical',T,W20ft,Vfts,dir,hft,phi,theta,psi,N,TOL,plots);
% 
% Vfts = 10; hft = 10; W20ft = 10; phi = 0; theta = 0; psi = 0; dir=0;
% e = e | runAndCompare('theoretical',T,W20ft,Vfts,dir,hft,phi,theta,psi,N,TOL,plots);
% 
% Vfts = 10; hft = 10; W20ft = 100; phi = 0; theta = 0; psi = 0; dir=0;
% e = e | runAndCompare('theoretical',T,W20ft,Vfts,dir,hft,phi,theta,psi,N,TOL,plots);
% 
% %% wind direction
% 
% Vfts = 20; hft = 20; W20ft = 10; phi = 0; theta = pi/4; psi = 0; dir=pi/4;
% e = e | runAndCompare('windlog_20V20h10w20_0p45t0p_45dir.mat',T,W20ft,Vfts,dir,hft,phi,theta,psi,N,TOL,plots);
% 
% Vfts = 20; hft = 20; W20ft = 10; phi = 0; theta = pi/4; psi = 0; dir=pi/2;
% e = e | runAndCompare('windlog_20V20h10w20_0p45t0p_90dir.mat',T,W20ft,Vfts,dir,hft,phi,theta,psi,N,TOL,plots);
% 
% Vfts = 20; hft = 20; W20ft = 10; phi = 0; theta = pi/4; psi = 0; dir=3*pi/4;
% e = e | runAndCompare('windlog_20V20h10w20_0p45t0p_135dir.mat',T,W20ft,Vfts,dir,hft,phi,theta,psi,N,TOL,plots);
% 
% Vfts = 20; hft = 20; W20ft = 10; phi = 0; theta = pi/4; psi = 0; dir=pi;
% e = e | runAndCompare('windlog_20V20h10w20_0p45t0p_180dir.mat',T,W20ft,Vfts,dir,hft,phi,theta,psi,N,TOL,plots);
% 
% Vfts = 20; hft = 20; W20ft = 10; phi = 0; theta = pi/4; psi = 0; dir=9*pi/8;
% e = e | runAndCompare('windlog_20V20h10w20_0p45t0p_202dir.mat',T,W20ft,Vfts,dir,hft,phi,theta,psi,N,TOL,plots);
% 
% Vfts = 20; hft = 20; W20ft = 10; phi = 0; theta = pi/4; psi = 0; dir=7*pi/4;
% e = e | runAndCompare('windlog_20V20h10w20_0p45t0p_315dir.mat',T,W20ft,Vfts,dir,hft,phi,theta,psi,N,TOL,plots);
% 
% Vfts = 20; hft = 20; W20ft = 10; phi = 0; theta = pi/4; psi = 0; dir=15*pi/8;
% e = e | runAndCompare('windlog_20V20h10w20_0p45t0p_337dir.mat',T,W20ft,Vfts,dir,hft,phi,theta,psi,N,TOL,plots);
% 
% % orientations
% 
% Vfts = 100; hft = 50; W20ft = 10; phi = 0; theta = 0; psi = pi/8; dir=0;
% e = e | runAndCompare('windlog_100V50h10w20_0p0t22p_0dir.mat',T,W20ft,Vfts,dir,hft,phi,theta,psi,N,TOL,plots);
% 
% Vfts = 100; hft = 50; W20ft = 10; phi = 0; theta = 0; psi = pi/4; dir=0;
% e = e | runAndCompare('windlog_100V50h10w20_0p0t45p_0dir.mat',T,W20ft,Vfts,dir,hft,phi,theta,psi,N,TOL,plots);
% 
% Vfts = 100; hft = 50; W20ft = 10; phi = 0; theta = 0; psi = 3*pi/8; dir=0;
% e = e | runAndCompare('windlog_100V50h10w20_0p0t67p_0dir.mat',T,W20ft,Vfts,dir,hft,phi,theta,psi,N,TOL,plots);
% 
% Vfts = 100; hft = 50; W20ft = 10; phi = 0; theta = 0; psi = pi/2; dir=0;
% e = e | runAndCompare('windlog_100V50h10w20_0p0t90p_0dir.mat',T,W20ft,Vfts,dir,hft,phi,theta,psi,N,TOL,plots);
% 
% 
% Vfts = 100; hft = 50; W20ft = 10; phi = 0; theta = pi/8; psi = 0; dir=0;
% e = e | runAndCompare('windlog_100V50h10w20_0p22t0p_0dir.mat',T,W20ft,Vfts,dir,hft,phi,theta,psi,N,TOL,plots);
% 
% Vfts = 100; hft = 50; W20ft = 10; phi = 0; theta = pi/4; psi = 0; dir=0;
% e = e | runAndCompare('windlog_100V50h10w20_0p45t0p_0dir.mat',T,W20ft,Vfts,dir,hft,phi,theta,psi,N,TOL,plots);
% 
% Vfts = 100; hft = 50; W20ft = 10; phi = 0; theta = 3*pi/8; psi = 0; dir=0;
% e = e | runAndCompare('windlog_100V50h10w20_0p67t0p_0dir.mat',T,W20ft,Vfts,dir,hft,phi,theta,psi,N,TOL,plots);
% 
% Vfts = 100; hft = 50; W20ft = 10; phi = 0; theta = pi/2; psi = 0; dir=0;
% e = e | runAndCompare('windlog_100V50h10w20_0p90t0p_0dir.mat',T,W20ft,Vfts,dir,hft,phi,theta,psi,N,TOL,plots);
% 
% 
% Vfts = 100; hft = 50; W20ft = 10; phi = pi/8; theta = 0; psi = 0; dir=0;
% e = e | runAndCompare('windlog_100V50h10w20_22p0t0p_0dir.mat',T,W20ft,Vfts,dir,hft,phi,theta,psi,N,TOL,plots);
% 
% Vfts = 100; hft = 50; W20ft = 10; phi = pi/4; theta = 0; psi = 0; dir=0;
% e = e | runAndCompare('windlog_100V50h10w20_67p0t0p_0dir.mat',T,W20ft,Vfts,dir,hft,phi,theta,psi,N,TOL,plots);
% 
% Vfts = 100; hft = 50; W20ft = 10; phi = 3*pi/8; theta = 0; psi = 0; dir=0;
% e = e | runAndCompare('windlog_100V50h10w20_67p0t0p_0dir.mat',T,W20ft,Vfts,dir,hft,phi,theta,psi,N,TOL,plots);
% 
% Vfts = 100; hft = 50; W20ft = 10; phi = pi/2; theta = 0; psi = 0; dir=0;
% e = e | runAndCompare('windlog_100V50h10w20_90p0t0p_0dir.mat',T,W20ft,Vfts,dir,hft,phi,theta,psi,N,TOL,plots);
% 
% 
% Vfts = 100; hft = 50; W20ft = 10; phi = pi/4; theta = 0; psi = 3*pi/8; dir=0;
% e = e | runAndCompare('windlog_100V50h10w20_45p0t67p_0dir.mat',T,W20ft,Vfts,dir,hft,phi,theta,psi,N,TOL,plots);
% 
% Vfts = 100; hft = 50; W20ft = 10; phi = pi/8; theta =  pi/4; psi = 0; dir=0;
% e = e | runAndCompare('windlog_100V50h10w20_22p45t0p_0dir.mat',T,W20ft,Vfts,dir,hft,phi,theta,psi,N,TOL,plots);
% 
% Vfts = 100; hft = 50; W20ft = 10; phi = 0; theta = pi/4; psi = pi/4; dir=0;
% e = e | runAndCompare('windlog_100V50h10w20_0p45t45p_0dir.mat',T,W20ft,Vfts,dir,hft,phi,theta,psi,N,TOL,plots);
% 
% Vfts = 100; hft = 50; W20ft = 10; phi = 3*pi/8; theta = pi/4; psi = pi/8; dir=0;
% e = e | runAndCompare('windlog_100V50h10w20_67p45t22p_0dir.mat',T,W20ft,Vfts,dir,hft,phi,theta,psi,N,TOL,plots);

cd('..');

end

function e = runSim()

N = 10000;

e = 0;

% trick to pass stuff to simulink, surely there mut be a better way
evalin('base','global state;');

% new state structure
global state;

state.i =0;

% only needed if using the pid controller
clear global pid;

state.simin=zeros(N,6);

% create simulator object
qrsim = QRSim();

% load task parameters and do housekeeping
qrsim.init('TaskCompareWindWithSimulink');

wps=[   0,   0,  -10, 0;
        0,   0,  -35, 0;
       35,   0,  -10, 0;
      -35,   0,  -10, 0;
        0,  35,  -10, 0;
        0, -35,  -10, 0];
    
j =1;
for i=1:N, 

    % compute controls
    U=quadrotorPID(state.platforms(1).getX(),wps(j,:));
   
    % step simulator
    qrsim.step(U);   
    
    if(norm(state.platforms(1).getX(1:3)-wps(j,1:3)')<0.5)
       disp('switching'); 
       j=j+1;
    end
    
    if(j>6), j=1; end
end

evalin('base','simin=state.simin;');

simOut = sim('wind_and_turb_comparison','SaveState','off');
        
yout = simOut.get('yout');       

end

function e = runAndCompare(reference,T,W20ft,Vfts,dir,hft,phi,theta,psi,N,TOL,plots)

msg = [' V=',num2str(Vfts),' h=',num2str(hft),' ori=[',num2str([phi,theta,psi]),'] dir=',num2str(dir)];

fs=1/T;
V = ft2m(Vfts);

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
objparams.direction = dir;
objparams.zOrigin = 0;

X = [0;0;-ft2m(hft);phi;theta;psi;V;0;0;0;0;0];

objparams.W6 = ft2m(W20ft);
state.turbModel = AerodynamicTurbulenceMILF8785(objparams);
state.rStreams = RandStream.create('mrg32k3a','seed',sum(100*clock),'NumStreams',state.numRStreams,'CellOutput',1);

state.turbModel.setState(X);
state.turbModel.reset();
uvwm = zeros(3,N);

for i=1:N
    state.turbModel.step(X);
    uvwm(:,i) = m2ft(state.turbModel.getLinear([]));
end

clear global state;

[Pmuu,f]=pwelch(uvwm(1,:),rectwin(2^14),0, 2^14,fs);
Pmvv=pwelch(uvwm(2,:),rectwin(2^14),0, 2^14,fs);
Pmww=pwelch(uvwm(3,:),rectwin(2^14),0, 2^14,fs);
Pmuu = Pmuu.*0.25;
Pmvv = Pmvv.*0.25;
Pmww = Pmww.*0.25;

w = 2*pi*f;
Puu = zeros(length(w),1);
Pvv = zeros(length(w),1);
Pww = zeros(length(w),1);

if(strcmp(reference,'theoretical'))
    for i=1:length(w)
        Puu(i,1) = ((2*(sigmau^2)*Lu)/(pi*Vfts))*(1/(1+(Lu*(w(i)/Vfts))^2));
        Pvv(i,1) = (((sigmav^2)*Lv)/(pi*Vfts))*((1+3*(Lv*w(i)/Vfts)^2)/(1+(Lv*(w(i)/Vfts))^2)^2);
        Pww(i,1) = (((sigmaw^2)*Lw)/(pi*Vfts))*((1+3*(Lw*w(i)/Vfts)^2)/(1+(Lw*(w(i)/Vfts))^2)^2);
    end
else
    data = load(reference);
    Puu=pwelch(data.ans(2,:),rectwin(2^14),0, 2^14,fs);
    Pvv=pwelch(data.ans(3,:),rectwin(2^14),0, 2^14,fs);
    Pww=pwelch(data.ans(4,:),rectwin(2^14),0, 2^14,fs);
    Puu = Puu.*0.25;
    Pvv = Pvv.*0.25;
    Pww = Pww.*0.25;
end

if(plots)
    figure;
    subplot(1,3,1);
    semilogx(f,10*log10(Puu));
    hold on;
    semilogx(f,10*log10(Pmuu),'r');
    grid on;
    axis([0.01 100 -80 20]);
    
    subplot(1,3,2);
    semilogx(f,10*log10(Pvv));
    hold on;
    semilogx(f,10*log10(Pmvv),'r');
    grid on;
    axis([0.01 100 -80 20]);
    
    subplot(1,3,3);
    semilogx(f,10*log10(Pww));
    hold on;
    semilogx(f,10*log10(Pmww),'r');
    grid on;
    axis([0.01 100 -80 20]);
    
    %     figure;
    %     subplot(1,3,1);
    %     semilogx(f,10*log10((Pmuu))-10*log10(Puu),'r');
    %     grid on;
    %
    %     subplot(1,3,2);
    %     semilogx(f,10*log10((Pmvv))-10*log10(Pvv),'r');
    %     grid on;
    %
    %     subplot(1,3,3);
    %     semilogx(f,10*log10((Pmww))-10*log10(Pww),'r');
    %     grid on;
    
end

meuu =  mean(abs(10*log10((Pmuu))-10*log10(Puu)));
mevv =  mean(abs(10*log10((Pmvv))-10*log10(Pvv)));
meww =  mean(abs(10*log10((Pmww))-10*log10(Pww)));

if(all([meuu,mevv,meww] < [TOL,TOL,TOL]))
    fprintf(['Test ',msg,' [PASSED]\n']);
    e =0;
else
    fprintf(['Test ', msg,' [FAILED]\n']);
    e = 1;
end

end
