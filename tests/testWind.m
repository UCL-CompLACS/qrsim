function e = testWind()

% note that this test requires both simulink and the aerospace blockset

clear all;
close all;

e = 0;

plots = 0;

cd('wind');


%%% model parameters

Vfts = 1; hft = 5; W20ft = 1; phi = 0; theta = 0; psi = 0; dir=0;
e = e | runTurbulenceAndCompare('theoretical',W20ft,Vfts,dir,hft,phi,theta,psi,plots,1);

Vfts = 10; hft = 20; W20ft = 10; phi = 0; theta = 0; psi = 0; dir=0;
e = e | runTurbulenceAndCompare('theoretical',W20ft,Vfts,dir,hft,phi,theta,psi,plots,2);

Vfts = 100; hft = 50; W20ft = 10; phi = 0; theta = 0; psi = 0; dir=0;
e = e | runTurbulenceAndCompare('theoretical',W20ft,Vfts,dir,hft,phi,theta,psi,plots,3);

Vfts = 10; hft = 5; W20ft = 10; phi = 0; theta = 0; psi = 0; dir=0;
e = e | runTurbulenceAndCompare('theoretical',W20ft,Vfts,dir,hft,phi,theta,psi,plots,4);

Vfts = 10; hft = 100; W20ft = 10; phi = 0; theta = 0; psi = 0; dir=0;
e = e | runTurbulenceAndCompare('theoretical',W20ft,Vfts,dir,hft,phi,theta,psi,plots,5);

Vfts = 30; hft = 100; W20ft = 10; phi = 0; theta = 0; psi = 0; dir=0;
e = e | runTurbulenceAndCompare('theoretical',W20ft,Vfts,dir,hft,phi,theta,psi,plots,6);

Vfts = 20; hft = 500; W20ft = 20; phi = 0; theta = 0; psi = 0; dir=0;
e = e | runTurbulenceAndCompare('theoretical',W20ft,Vfts,dir,hft,phi,theta,psi,plots,7);

Vfts = 10; hft = 10; W20ft = 1; phi = 0; theta = 0; psi = 0; dir=0;
e = e | runTurbulenceAndCompare('theoretical',W20ft,Vfts,dir,hft,phi,theta,psi,plots,8);

Vfts = 10; hft = 10; W20ft = 10; phi = 0; theta = 0; psi = 0; dir=0;
e = e | runTurbulenceAndCompare('theoretical',W20ft,Vfts,dir,hft,phi,theta,psi,plots,9);

Vfts = 10; hft = 10; W20ft = 100; phi = 0; theta = 0; psi = 0; dir=0;
e = e | runTurbulenceAndCompare('theoretical',W20ft,Vfts,dir,hft,phi,theta,psi,plots,10);

%%% wind direction

Vfts = 20; hft = 20; W20ft = 10; phi = 0; theta = pi/4; psi = 0; dir=pi/4;
e = e | runTurbulenceAndCompare('simulink',W20ft,Vfts,dir,hft,phi,theta,psi,plots,11);

Vfts = 20; hft = 20; W20ft = 10; phi = 0; theta = pi/4; psi = 0; dir=pi/2;
e = e | runTurbulenceAndCompare('simulink',W20ft,Vfts,dir,hft,phi,theta,psi,plots,12);

Vfts = 20; hft = 20; W20ft = 10; phi = 0; theta = pi/4; psi = 0; dir=3*pi/4;
e = e | runTurbulenceAndCompare('simulink',W20ft,Vfts,dir,hft,phi,theta,psi,plots,13);

Vfts = 20; hft = 20; W20ft = 10; phi = 0; theta = pi/4; psi = 0; dir=pi;
e = e | runTurbulenceAndCompare('simulink',W20ft,Vfts,dir,hft,phi,theta,psi,plots,14);

Vfts = 20; hft = 20; W20ft = 10; phi = 0; theta = pi/4; psi = 0; dir=9*pi/8;
e = e | runTurbulenceAndCompare('simulink',W20ft,Vfts,dir,hft,phi,theta,psi,plots,15);

Vfts = 20; hft = 20; W20ft = 10; phi = 0; theta = pi/4; psi = 0; dir=7*pi/4;
e = e | runTurbulenceAndCompare('simulink',W20ft,Vfts,dir,hft,phi,theta,psi,plots,16);

Vfts = 20; hft = 20; W20ft = 10; phi = 0; theta = pi/4; psi = 0; dir=15*pi/8;
e = e | runTurbulenceAndCompare('simulink',W20ft,Vfts,dir,hft,phi,theta,psi,plots,17);

%%% orientations

Vfts = 100; hft = 50; W20ft = 10; phi = 0; theta = 0; psi = pi/8; dir=0;
e = e | runTurbulenceAndCompare('simulink',W20ft,Vfts,dir,hft,phi,theta,psi,plots,18);

Vfts = 100; hft = 50; W20ft = 10; phi = 0; theta = 0; psi = pi/4; dir=0;
e = e | runTurbulenceAndCompare('simulink',W20ft,Vfts,dir,hft,phi,theta,psi,plots,19);

Vfts = 100; hft = 50; W20ft = 10; phi = 0; theta = 0; psi = 3*pi/8; dir=0;
e = e | runTurbulenceAndCompare('simulink',W20ft,Vfts,dir,hft,phi,theta,psi,plots,20);

Vfts = 100; hft = 50; W20ft = 10; phi = 0; theta = 0; psi = pi/2; dir=0;
e = e | runTurbulenceAndCompare('simulink',W20ft,Vfts,dir,hft,phi,theta,psi,plots,21);


Vfts = 100; hft = 50; W20ft = 10; phi = 0; theta = pi/8; psi = 0; dir=0;
e = e | runTurbulenceAndCompare('simulink',W20ft,Vfts,dir,hft,phi,theta,psi,plots,22);

Vfts = 100; hft = 50; W20ft = 10; phi = 0; theta = pi/4; psi = 0; dir=0;
e = e | runTurbulenceAndCompare('simulink',W20ft,Vfts,dir,hft,phi,theta,psi,plots,23);

Vfts = 100; hft = 50; W20ft = 10; phi = 0; theta = 3*pi/8; psi = 0; dir=0;
e = e | runTurbulenceAndCompare('simulink',W20ft,Vfts,dir,hft,phi,theta,psi,plots,24);

Vfts = 100; hft = 50; W20ft = 10; phi = 0; theta = pi/2; psi = 0; dir=0;
e = e | runTurbulenceAndCompare('simulink',W20ft,Vfts,dir,hft,phi,theta,psi,plots,25);


Vfts = 100; hft = 50; W20ft = 10; phi = pi/8; theta = 0; psi = 0; dir=0;
e = e | runTurbulenceAndCompare('simulink',W20ft,Vfts,dir,hft,phi,theta,psi,plots,26);

Vfts = 100; hft = 50; W20ft = 10; phi = pi/4; theta = 0; psi = 0; dir=0;
e = e | runTurbulenceAndCompare('simulink',W20ft,Vfts,dir,hft,phi,theta,psi,plots,27);

Vfts = 100; hft = 50; W20ft = 10; phi = 3*pi/8; theta = 0; psi = 0; dir=0;
e = e | runTurbulenceAndCompare('simulink',W20ft,Vfts,dir,hft,phi,theta,psi,plots,28);

Vfts = 100; hft = 50; W20ft = 10; phi = pi/2; theta = 0; psi = 0; dir=0;
e = e | runTurbulenceAndCompare('simulink',W20ft,Vfts,dir,hft,phi,theta,psi,plots,29);


Vfts = 100; hft = 50; W20ft = 10; phi = pi/4; theta = 0; psi = 3*pi/8; dir=0;
e = e | runTurbulenceAndCompare('simulink',W20ft,Vfts,dir,hft,phi,theta,psi,plots,30);

Vfts = 100; hft = 50; W20ft = 10; phi = pi/8; theta =  pi/4; psi = 0; dir=0;
e = e | runTurbulenceAndCompare('simulink',W20ft,Vfts,dir,hft,phi,theta,psi,plots,31);

Vfts = 100; hft = 50; W20ft = 10; phi = 0; theta = pi/4; psi = pi/4; dir=0;
e = e | runTurbulenceAndCompare('simulink',W20ft,Vfts,dir,hft,phi,theta,psi,plots,32);

Vfts = 100; hft = 50; W20ft = 10; phi = 3*pi/8; theta = pi/4; psi = pi/8; dir=0;
e = e | runTurbulenceAndCompare('simulink',W20ft,Vfts,dir,hft,phi,theta,psi,plots,33);


%%% full qrsim tests with wind shear and direction changes 
e = e | runQRSimAndCompare('TaskCompareWindWithSimulinkW2D0','comparison with simulink w20=2fts direction=0',plots);

e = e | runQRSimAndCompare('TaskCompareWindWithSimulinkW2D30','comparison with simulink w20=2fts direction=30',plots);

e = e | runQRSimAndCompare('TaskCompareWindWithSimulinkW2D90','comparison with simulink w20=2fts direction=90',plots);


cd('..');

end

function e = runQRSimAndCompare(task,msg,plots)

N = 10000;
TOL1 = 1e-10;
TOL2 = 6;

e = 0;

addpath('../../controllers');

% trick to pass stuff to simulink, surely there mut be a better way
evalin('base','global windstate;');

% create simulator object
qrsim = QRSim();

% load task parameters and do housekeeping
state = qrsim.init(task);

pid = WaypointPID(state.DT);

global windstate;

windstate.i =0;

windstate.simin=zeros(N,6);
windstate.meanwindfts=zeros(N,3);
windstate.turbwindfts=zeros(N,3);


fs = 1/state.DT;

wps = [ 0,   0,  35, -35,  0,   0;
        0,   0,   0,   0, 35, -35;
       -5, -35, -30, -30, -5,  -5];

j =1;
for i=1:N,
    %tloop=tic;
    % compute controls
    U=pid.computeU(state.platforms{1}.getX(),wps(:,j),0);
    
    % step simulator
    qrsim.step(U);
    
    % wait so to run in real time
    %wait = max(0,state.task.dt-toc(tloop));
    %pause(wait);
    
    d=norm(state.platforms{1}.getX(1:3)-wps(:,j));
    
    if(d<1.5)
        j=j+1;
        if(j>6), j=1; end
        %disp(['switching to:',num2str(wps(:,j))]);
    end
end

evalin('base','simin=windstate.simin;');
load_system('wind_and_turb_comparison');
set_param('wind_and_turb_comparison','StopTime',num2str((N-1)*state.DT));
set_param('wind_and_turb_comparison','FixedStep',num2str(state.DT));
set_param('wind_and_turb_comparison/shear_model','W_20',num2str(mToFt(state.environment.wind.getW6())));
set_param('wind_and_turb_comparison/shear_model','Wdeg',num2str(radsToDegs(state.environment.wind.getDirection())));
set_param('wind_and_turb_comparison/dryden_turb_model','W20',num2str(mToFt(state.platforms{1}.getAerodynamicTurbulence().getW6())));
set_param('wind_and_turb_comparison/dryden_turb_model','Wdeg',num2str(radsToDegs(state.platforms{1}.getAerodynamicTurbulence().getDirection())));
set_param('wind_and_turb_comparison/dryden_turb_model','ts',num2str(state.DT));
simOut = sim('wind_and_turb_comparison','SaveState','off');

yout = simOut.get('yout');
t = yout(:,1);
ymeanwindfts = yout(:,2:4);
yturbwindfts = yout(:,5:7);


if(~all(mean((windstate.meanwindfts - ymeanwindfts).^2)<TOL1))
    e = e | 1;
end

[Puu_y,f]=pwelch(yturbwindfts(:,1),rectwin(2^12),0, 2^12,fs);
Pvv_y=pwelch(yturbwindfts(:,2),rectwin(2^12),0, 2^12,fs);
Pww_y=pwelch(yturbwindfts(:,3),rectwin(2^12),0, 2^12,fs);
Puu_y = Puu_y.*0.25;
Pvv_y = Pvv_y.*0.25;
Pww_y = Pww_y.*0.25;

Puu_s=pwelch(windstate.turbwindfts(:,1),rectwin(2^12),0, 2^12,fs);
Pvv_s=pwelch(windstate.turbwindfts(:,2),rectwin(2^12),0, 2^12,fs);
Pww_s=pwelch(windstate.turbwindfts(:,3),rectwin(2^12),0, 2^12,fs);
Puu_s = Puu_s.*0.25;
Pvv_s = Pvv_s.*0.25;
Pww_s = Pww_s.*0.25;


meuu =  mean(abs(10*log10(Puu_s)-10*log10(Puu_y)));
mevv =  mean(abs(10*log10(Pvv_s)-10*log10(Pvv_y)));
meww =  mean(abs(10*log10(Pww_s)-10*log10(Pww_y)));

if(~all([meuu,mevv,meww] < [TOL2,TOL2,TOL2]))
    e = e | 1;
end

if(plots)
    figure();
    subplot(3,1,1);
    plot(t,windstate.meanwindfts(:,1));
    hold on;
    plot(t,ymeanwindfts(:,1),'r');
    
    subplot(3,1,2);
    plot(t,windstate.meanwindfts(:,2));
    hold on;
    plot(t,ymeanwindfts(:,2),'r');
    
    subplot(3,1,3);
    plot(t,windstate.meanwindfts(:,3));
    hold on;
    plot(t,ymeanwindfts(:,3),'r');
    
    
    figure();
    subplot(3,1,1);
    plot(t,windstate.turbwindfts(:,1));
    hold on;
    plot(t,yturbwindfts(:,1),'r');
    
    subplot(3,1,2);
    plot(t,windstate.turbwindfts(:,2));
    hold on;
    plot(t,yturbwindfts(:,2),'r');
    
    subplot(3,1,3);
    plot(t,windstate.turbwindfts(:,3));
    hold on;
    plot(t,yturbwindfts(:,3),'r');
    
    figure;
    subplot(1,3,1);
    semilogx(f,10*log10(Puu_s));
    hold on;
    semilogx(f,10*log10(Puu_y),'r');
    grid on;
    axis([0.01 100 -80 20]);
    
    subplot(1,3,2);
    semilogx(f,10*log10(Pvv_s));
    hold on;
    semilogx(f,10*log10(Pvv_y),'r');
    grid on;
    axis([0.01 100 -80 20]);
    
    subplot(1,3,3);
    semilogx(f,10*log10(Pww_s));
    hold on;
    semilogx(f,10*log10(Pww_y),'r');
    grid on;
    axis([0.01 100 -80 20]);
end

if(~e)
    fprintf(['Test ',msg,' [PASSED]\n']);
else
    fprintf(['Test ', msg,' [FAILED]\n']);
end

clear state;
clear global pid;

end

function e = runTurbulenceAndCompare(reference,W20ft,Vfts,dir,hft,phi,theta,psi,plots,seed)

TOL = 6;
N = 20000;
T = 0.01;

msg = [' V=',num2str(Vfts),' h=',num2str(hft),' ori=[',num2str([phi,theta,psi]),'] dir=',num2str(dir)];

fs=1/T;
V = ftToM(Vfts);

sigmaw = 0.1*W20ft;
sigmau = sigmaw/(0.177+0.000823*hft)^0.4;
sigmav = sigmau;

Lw = hft;
Lu = hft/(0.177+0.000823*hft)^1.2;
Lv = Lu;


%%% turbulence model
global windstate;

% trick to pass stuff to simulink, surely there mut be a better way
evalin('base','global windstate;');

state = State();

state.t = 0;
state.DT = T;
state.numRStreams = 0;

objparams.DT = T;
objparams.dt = T;
objparams.on = 1;
objparams.W6 = ftToM(W20ft);
objparams.direction = dir;
objparams.zOrigin = 0;
objparams.state = state;

X = [0;0;-ftToM(hft);phi;theta;psi;V;0;0;0;0;0];

objparams.W6 = ftToM(W20ft);
turbModel = AerodynamicTurbulenceMILF8785ForTesting(objparams);
state.rStreams = RandStream.create('mrg32k3a','seed',seed,'NumStreams',state.numRStreams,'CellOutput',1);

turbModel.setState(X);
turbModel.reset();
uvwm = zeros(3,N);

for i=1:N
    turbModel.step(X);
    uvwm(:,i) = mToFt(turbModel.getLinear([]));
end

[Pmuu,f]=pwelch(uvwm(1,:),rectwin(2^12),0, 2^12,fs);
Pmvv=pwelch(uvwm(2,:),rectwin(2^12),0, 2^12,fs);
Pmww=pwelch(uvwm(3,:),rectwin(2^12),0, 2^12,fs);
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
    windstate.simin = [((0:(N-1))*state.DT)',repmat([hft,Vfts,phi,theta,psi],N,1)];
    evalin('base','simin=windstate.simin;');
    load_system('wind_and_turb_comparison');
    set_param('wind_and_turb_comparison','StopTime',num2str((N-1)*state.DT));
    set_param('wind_and_turb_comparison','FixedStep',num2str(state.DT));
    set_param('wind_and_turb_comparison/shear_model','W_20',num2str(W20ft));
    set_param('wind_and_turb_comparison/shear_model','Wdeg',num2str(radsToDegs(dir)));
    set_param('wind_and_turb_comparison/dryden_turb_model','W20',num2str(W20ft));
    set_param('wind_and_turb_comparison/dryden_turb_model','Wdeg',num2str(radsToDegs(dir)));
    set_param('wind_and_turb_comparison/dryden_turb_model','ts',num2str(state.DT));
    simOut = sim('wind_and_turb_comparison','SaveState','off');

    yout = simOut.get('yout');
    yturbwindfts = yout(:,5:7);

    Puu=pwelch(yturbwindfts(:,1),rectwin(2^12),0, 2^12,fs);
    Pvv=pwelch(yturbwindfts(:,2),rectwin(2^12),0, 2^12,fs);
    Pww=pwelch(yturbwindfts(:,3),rectwin(2^12),0, 2^12,fs);
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

clear state;

end
