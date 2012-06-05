function e = testPIDs() %#ok<*AGROW>
%TESTPIDS Summary of this function goes here
%   Detailed explanation goes here

plots = 0;

cd('pids');

e = 0;
e = e | testWaypointPID(plots);
e = e | testVelocityPID(plots);
e = e | testVelocityHeightPID(plots);
e = e | testAngleHeightPID(plots);

cd ('..');

end

function e = testWaypointPID(plots)

close all;

told = 1;
tola = pi/36;

e = 0;

addpath('../../controllers');

% number of steps we run the simulation for
N = 600;

% create simulator object
qrsim = QRSim();

% load task parameters and do housekeeping
state = qrsim.init('TaskNoWind');

des=[   0,   0,  10, 0;
        0,   0, -10, pi/4;
       10,   0,   0, 0;
      -10,   0,   0, pi/2;
        0,  10,   0, 0;
        0, -10,   0, -pi/3];

pid = WaypointPID(state.DT);

for j = 1:size(des,1)
    if(plots)
        figure(j);
        P=[];
        Z=[];
        A=[];
    end
    for i=1:N,
        % compute controls
        U=pid.computeU(state.platforms{1}.getEX(),des(j,:));
        
        % step simulator
        qrsim.step(U);
        if(plots)
            P=[P,state.platforms{1}.getEX(1:2)]; 
            Z=[Z,-state.platforms{1}.getEX(17)]; 
            A=[A,state.platforms{1}.getEX(6)];          
        end
    end
        
    if(plots)
        subplot(4,1,1);
        plot(P(1,:));
        hold on;
        plot(ones(1,N)*des(j,1),'r');
        ylabel('px [m]');
        grid on;
        axis([0 400 -15 15]);
        subplot(4,1,2)
        plot(P(2,:));
        hold on;
        plot(ones(1,N)*des(j,2),'r');
        ylabel('py [m]');
        grid on;
        axis([0 400 -15 15]);
        subplot(4,1,3)
        plot(Z);
        hold on;
        plot(ones(1,N)*des(j,3),'r');
        ylabel('pz [m]');
        grid on;
        axis([0 400 -15 15]);
        subplot(4,1,4)
        plot(A);
        hold on;
        plot(ones(1,N)*des(j,4),'r');
        ylabel('heading [rad]');
        grid on;
        axis([0 400 -pi pi]);
    end
    
    diffd = norm([state.platforms{1}.getEX(1:2)-des(j,1:2)';-state.platforms{1}.getEX(17)-des(j,3)]);
    diffa = abs(state.platforms{1}.getEX(6)-des(j,4));    
    if(~((diffd<told)&&(diffa<tola)))
        e = e | 1;
    end
    qrsim.reset();
end

jj = j;
for j = 1:size(des,1)
    if(plots)
        figure(jj+j);
        P=[];
        A=[];
    end
    for i=1:N,
        % compute controls
        U=pid.computeU(state.platforms{1}.getX(),des(j,:));
        
        % step simulator
        qrsim.step(U);
        qrsim.step(U);
        if(plots)
            P=[P,state.platforms{1}.getX(1:3)];
            A=[A,state.platforms{1}.getX(6)];          
        end
    end
            
    if(plots)
        subplot(4,1,1);
        plot(P(1,:));
        hold on;
        plot(ones(1,N)*des(j,1),'r');
        ylabel('px [m]');
        grid on;
        axis([0 400 -15 15]);
        subplot(4,1,2)
        plot(P(2,:));
        hold on;
        plot(ones(1,N)*des(j,2),'r');
        ylabel('py [m]');
        grid on;
        axis([0 400 -15 15]);
        subplot(4,1,3)
        plot(P(3,:));
        hold on;
        plot(ones(1,N)*des(j,3),'r');
        ylabel('pz [m]');
        grid on;
        axis([0 400 -15 15]);
        subplot(4,1,4)
        plot(A);
        hold on;
        plot(ones(1,N)*des(j,4),'r');
        ylabel('heading [rad]');
        grid on;
        axis([0 400 -pi pi]);
    end
    
    diffd = norm(state.platforms{1}.getX(1:3)-des(j,1:3)');
    diffa = abs(state.platforms{1}.getX(6)-des(j,4));    
    if(~((diffd<told)&&(diffa<tola)))
        e = e | 1;
    end
    qrsim.reset();
end

if(e)
    fprintf('Test WaypointPID [FAILED]\n');
else
    fprintf('Test WaypointPID [PASSED]\n');
end

end


function e = testVelocityPID(plots)

close all;

tolv = 0.15;
tola = 0.1;

e = 0;

addpath('../../controllers');

% number of steps we run the simulation for
N = 400;

% create simulator object
qrsim = QRSim();

% load task parameters and do housekeeping
state = qrsim.init('TaskNoWindNoDrag');

des=[  -2,   0, 0, 0;
    0,   0, -2, pi/4;
    2,   0,  0, 0;
    -2,   0,  0, pi/2;
    0,   2,  0, 0;
    0,  -2,  0, -pi/3];

pid = VelocityPID(state.DT);

for j = 1:size(des,1)
    if(plots)
        figure(j);
        VV=[];
        A=[];
    end
    for i=1:N,
        % compute controls
        U=pid.computeU(state.platforms{1}.getEX(),des(j,1:3)',des(j,4));
        
        % step simulator
        qrsim.step(U);
        if(plots)
            VV=[VV,[state.platforms{1}.getEX(18:19);-state.platforms{1}.getEX(20)]];
            A=[A,state.platforms{1}.getEX(6)];
        end
    end
    
    if(plots)
        subplot(4,1,1);
        plot(VV(1,:));
        hold on;
        plot(ones(1,N)*des(j,1),'r');
        ylabel('vx [m/s]');
        grid on;
        axis([0 400 -3 3]);
        subplot(4,1,2)
        plot(VV(2,:));
        hold on;
        plot(ones(1,N)*des(j,2),'r');
        ylabel('vy [m/s]');
        grid on;
        axis([0 400 -3 3]);
        subplot(4,1,3)
        plot(VV(3,:));
        hold on;
        plot(ones(1,N)*des(j,3),'r');
        ylabel('vz [m/s]');
        grid on;
        axis([0 400 -3 3]);
        subplot(4,1,4)
        plot(A);
        hold on;
        plot(ones(1,N)*des(j,4),'r');
        ylabel('heading [rad]');
        grid on;
        axis([0 400 -pi pi]);
    end
    
    diffv = norm([state.platforms{1}.getEX(18:19)-des(j,1:2)';-state.platforms{1}.getEX(20)-des(j,3)]);
    diffa = abs(state.platforms{1}.getEX(6)-des(j,4));
    if(~(diffv<tolv)&&(diffa<tola))
        e = e | 1;
    end
    qrsim.reset();
end

jj = j;
for j = 1:size(des,1)
    if(plots)
        figure(jj+j);
        VV=[];
        A=[];
    end    
    for i=1:N,
        % compute controls
        U=pid.computeU(state.platforms{1}.getX(),des(j,1:3)',des(j,4));
        
        % step simulator
        qrsim.step(U);
        if(plots)            
            vv=dcm(state.platforms{1}.getX())'*state.platforms{1}.getX(7:9);
            VV=[VV,vv];            
            A=[A,state.platforms{1}.getX(6)];
        end
    end
    
    if(plots)
        subplot(4,1,1);
        plot(VV(1,:));
        hold on;
        plot(ones(1,N)*des(j,1),'r');
        ylabel('vx [m/s]');
        grid on;
        axis([0 400 -3 3]);
        subplot(4,1,2)
        plot(VV(2,:));
        hold on;
        plot(ones(1,N)*des(j,2),'r');
        ylabel('vy [m/s]');
        grid on;
        axis([0 400 -3 3]);
        subplot(4,1,3)
        plot(VV(3,:));
        hold on;
        plot(ones(1,N)*des(j,3),'r');
        ylabel('vz [m/s]');
        grid on;
        axis([0 400 -3 3]);
        subplot(4,1,4)
        plot(A);
        hold on;
        plot(ones(1,N)*des(j,4),'r');
        ylabel('heading [rad]');
        grid on;
        axis([0 400 -pi pi]);
    end
    
    vv=dcm(state.platforms{1}.getX())'*state.platforms{1}.getX(7:9);
    diffv = norm(vv(1:3)-des(j,1:3)');
    diffa = abs(state.platforms{1}.getX(6)-des(j,4));
    if(~(diffv<tolv)&&(diffa<tola))
        e = e | 1;
    end
    qrsim.reset();
end

if(e)
    fprintf('Test VelocityPID [FAILED]\n');
else
    fprintf('Test VelocityPID [PASSED]\n');
end 

end


function e = testVelocityHeightPID(plots)

close all;

tolv = 0.7;
tolh = 0.3;
tola = 0.1;

e = 0;

addpath('../../controllers');

% number of steps we run the simulation for
N = 700;

% create simulator object
qrsim = QRSim();

% load task parameters and do housekeeping
state = qrsim.init('TaskNoWind');

des=[  -2,   0,  0, 0;
    2,   0,  0, pi/4;
    2,   0,  0, 0;
    -2,   0,  0, pi/2;
    0,   2,  10, 0;
    0,  -2, -10, -pi/3];

pid = VelocityHeightPID(state.DT);

for j = 1:size(des,1)
    if(plots)
        figure(j);
        VV=[];
        Z=[];
        A=[];
    end
    for i=1:N,
        % compute controls
        U=pid.computeU(state.platforms{1}.getEX(),des(j,1:2)',des(j,3),des(j,4));
        
        % step simulator
        qrsim.step(U);
        if(plots)
            VV = [VV,state.platforms{1}.getEX(18:19)];
            Z = [Z,-state.platforms{1}.getEX(17)];
            A = [A,state.platforms{1}.getEX(6)];
        end
    end
    
    if(plots)
        subplot(4,1,1);
        plot(VV(1,:));
        hold on;
        plot(ones(1,N)*des(j,1),'r');
        ylabel('vx [m/s]');
        grid on;
        axis([0 400 -3 3]);
        subplot(4,1,2)
        plot(VV(2,:));
        hold on;
        plot(ones(1,N)*des(j,2),'r');
        ylabel('vy [m/s]');
        grid on;
        axis([0 400 -3 3]);
        subplot(4,1,3)
        plot(Z);
        hold on;
        plot(ones(1,N)*des(j,3),'r');
        ylabel('z [m]');
        grid on;
        axis([0 400 -12 12]);
        subplot(4,1,4)
        plot(A);
        hold on;
        plot(ones(1,N)*des(j,4),'r');
        ylabel('heading [rad]');
        grid on;
        axis([0 400 -pi pi]);
    end
    
    diffv = norm(state.platforms{1}.getEX(18:19)-des(j,1:2)');
    diffh = abs(-state.platforms{1}.getEX(17)-des(j,3));
    diffa = abs(state.platforms{1}.getEX(6)-des(j,4));
    if(~(diffv<tolv)&&(diffh<tolh)&&(diffa<tola))
        e = e | 1;
    end
    qrsim.reset();
end

jj = j;
for j = 1:size(des,1)
    if(plots)
        figure(jj+j);
        VV=[];
        Z=[];
        A=[];
    end
    for i=1:N,
        % compute controls
        U=pid.computeU(state.platforms{1}.getX(),des(j,1:2)',des(j,3),des(j,4));
        
        % step simulator
        qrsim.step(U);
        
        if(plots)
            vv = dcm(state.platforms{1}.getX())'*state.platforms{1}.getX(7:9);
            VV = [VV,vv(1:2)];
            Z = [Z,state.platforms{1}.getX(3)];
            A = [A,state.platforms{1}.getX(6)];
        end
    end
    
    if(plots)
        subplot(4,1,1);
        plot(VV(1,:));
        hold on;
        plot(ones(1,N)*des(j,1),'r');
        ylabel('vx [m/s]');
        grid on;
        axis([0 400 -3 3]);
        subplot(4,1,2)
        plot(VV(2,:));
        hold on;
        plot(ones(1,N)*des(j,2),'r');
        ylabel('vy [m/s]');
        grid on;
        axis([0 400 -3 3]);
        subplot(4,1,3)
        plot(Z);
        hold on;
        plot(ones(1,N)*des(j,3),'r');        
        ylabel('z [m]');
        axis([0 400 -12 12]);
        grid on;
        subplot(4,1,4)
        plot(A);
        hold on;
        plot(ones(1,N)*des(j,4),'r');
        ylabel('heading [rad]');
        axis([0 400 -pi pi]);
        grid on;
    end
    
    vv=dcm(state.platforms{1}.getX())'*state.platforms{1}.getX(7:9);
    diffv = norm(vv(1:2)-des(j,1:2)');
    diffh = abs(state.platforms{1}.getX(3)-des(j,3));
    diffa = abs(state.platforms{1}.getX(6)-des(j,4));
    if(~(diffv<tolv)&&(diffh<tolh)&&(diffa<tola))
        e = e | 1;
    end
    qrsim.reset();
end

if(e)
    fprintf('Test WaypointHeightPID [FAILED]\n');
else
    fprintf('Test WaypointHeightPID [PASSED]\n');
end

end

function e = testAngleHeightPID(plots)

close all;

tolpt = 0.2;
tolh = 0.3;
tola = 0.1;

e = 0;

addpath('../../controllers');

% number of steps we run the simulation for
N = 700;

% create simulator object
qrsim = QRSim();

% load task parameters and do housekeeping
state = qrsim.init('TaskNoWind');

des=[  0,   0,  0, 0;
       0,   0,  0, pi/4;
       0,   0,  10, 0;
       0,   0, -10, -pi/3];

pid = VelocityHeightPID(state.DT);

for j = 1:size(des,1)
    if(plots)
        figure(j);
        PT=[];
        Z=[];
        A=[];
    end
    for i=1:N,
        % compute controls
        U=pid.computeU(state.platforms{1}.getEX(),des(j,1:2)',des(j,3),des(j,4));
        
        % step simulator
        qrsim.step(U);
        if(plots)
            PT = [PT,state.platforms{1}.getEX(4:5)];
            Z = [Z,-state.platforms{1}.getEX(17)];
            A = [A,state.platforms{1}.getEX(6)];
        end
    end
    
    if(plots)
        subplot(4,1,1);
        plot(PT(1,:));
        hold on;
        plot(ones(1,N)*des(j,1),'r');
        ylabel('phi [rad]');
        grid on;
        axis([0 400 -3 3]);
        subplot(4,1,2)
        plot(PT(2,:));
        hold on;
        plot(ones(1,N)*des(j,2),'r');
        ylabel('theta [rad]');
        grid on;
        axis([0 400 -3 3]);
        subplot(4,1,3)
        plot(Z);
        hold on;
        plot(ones(1,N)*des(j,3),'r');
        ylabel('z [m]');
        grid on;
        axis([0 400 -12 12]);
        subplot(4,1,4)
        plot(A);
        hold on;
        plot(ones(1,N)*des(j,4),'r');
        ylabel('heading [rad]');
        grid on;
        axis([0 400 -pi pi]);
    end
    
    diffpt = norm(state.platforms{1}.getEX(4:5)-des(j,1:2)');
    diffh = abs(-state.platforms{1}.getEX(17)-des(j,3));
    diffa = abs(state.platforms{1}.getEX(6)-des(j,4));
    if(~(diffpt<tolpt)&&(diffh<tolh)&&(diffa<tola))
        e = e | 1;
    end
    qrsim.reset();
end

jj = j;
for j = 1:size(des,1)
    if(plots)
        figure(jj+j);
        PT=[];
        Z=[];
        A=[];
    end
    for i=1:N,
        % compute controls
        U=pid.computeU(state.platforms{1}.getX(),des(j,1:2)',des(j,3),des(j,4));
        
        % step simulator
        qrsim.step(U);
        
        if(plots)
            PT = [PT,state.platforms{1}.getX(4:5)];
            Z = [Z,state.platforms{1}.getX(3)];
            A = [A,state.platforms{1}.getX(6)];
        end
    end
    
    if(plots)
        subplot(4,1,1);
        plot(PT(1,:));
        hold on;
        plot(ones(1,N)*des(j,1),'r');
        ylabel('phi [rad]');
        grid on;
        axis([0 400 -3 3]);
        subplot(4,1,2)
        plot(PT(2,:));
        hold on;
        plot(ones(1,N)*des(j,2),'r');
        ylabel('theta [rad]');
        grid on;
        axis([0 400 -3 3]);
        subplot(4,1,3)
        plot(Z);
        hold on;
        plot(ones(1,N)*des(j,3),'r');        
        ylabel('z [m]');
        axis([0 400 -12 12]);
        grid on;
        subplot(4,1,4)
        plot(A);
        hold on;
        plot(ones(1,N)*des(j,4),'r');
        ylabel('heading [rad]');
        axis([0 400 -pi pi]);
        grid on;
    end
    
    diffpt = norm(state.platforms{1}.getX(4:5)-des(j,1:2)');
    diffh = abs(state.platforms{1}.getX(3)-des(j,3));
    diffa = abs(state.platforms{1}.getX(6)-des(j,4));
    if(~(diffpt<tolpt)&&(diffh<tolh)&&(diffa<tola))
        e = e | 1;
    end
    qrsim.reset();
end

if(e)
    fprintf('Test AngleHeightPID [FAILED]\n');
else
    fprintf('Test AngleHeightPID [PASSED]\n');
end

end