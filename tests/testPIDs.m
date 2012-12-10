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

addpath(['..',filesep,'..',filesep,'controllers']);

% number of steps we run the simulation for
N = 600;

% create simulator object
qrsim = QRSim();

% load task parameters and do housekeeping
state = qrsim.init('TaskNoWind');

des = [  0,    0,  10,  -10,   0,     0;
         0,    0,   0,    0,  10,   -10;
        10,  -10,   0,    0,   0,     0;
         0, pi/4,   0, pi/2,   0, -pi/3]; 
    
pid = WaypointPID(state.DT);
t = (1:N)*state.task.dt;
for j = 1:size(des,2)
    if(plots)
        figure(j);
        P=[];
        Z=[];
        A=[];
    end
    for i=1:N,
        % compute controls
        U=pid.computeU(state.platforms{1}.getEX(),des(1:3,j),des(4,j));
        
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
        plot(t,P(1,:));
        hold on;
        plot(t,ones(1,N)*des(1,j),'r');
        ylabel('px [m]');
        grid on;
        axis([0 N*state.task.dt -15 15]);
        subplot(4,1,2)
        plot(t,P(2,:));
        hold on;
        plot(t,ones(1,N)*des(2,j),'r');
        ylabel('py [m]');
        grid on;
        axis([0 N*state.task.dt -15 15]);
        subplot(4,1,3)
        plot(t,Z);
        hold on;
        plot(t,ones(1,N)*des(3,j),'r');
        ylabel('pz [m]');
        grid on;
        axis([0 N*state.task.dt -15 15]);
        subplot(4,1,4)
        plot(t,A);
        hold on;
        plot(t,ones(1,N)*des(4,j),'r');
        ylabel('heading [rad]');
        grid on;
        axis([0 N*state.task.dt -pi pi]);
        xlabel('t[s]');
    end
    
    diffd = norm([state.platforms{1}.getEX(1:2)-des(1:2,j);-state.platforms{1}.getEX(17)-des(3,j)]);
    diffa = abs(state.platforms{1}.getEX(6)-des(4,j));    
    if(~((diffd<told)&&(diffa<tola))&&state.platforms{1}.isValid())
        e = e | 1;
    end
    qrsim.reset();
    pid.reset();
end

jj = j;
for j = 1:size(des,2)
    if(plots)
        figure(jj+j);
        P=[];
        A=[];
    end
    for i=1:N,
        % compute controls
        U=pid.computeU(state.platforms{1}.getX(),des(1:3,j),des(4,j));
        
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
        plot(t,P(1,:));
        hold on;
        plot(t,ones(1,N)*des(1,j),'r');
        ylabel('px [m]');
        grid on;
        axis([0 N*state.task.dt -15 15]);
        subplot(4,1,2)
        plot(t,P(2,:));
        hold on;
        plot(t,ones(1,N)*des(2,j),'r');
        ylabel('py [m]');
        grid on;
        axis([0 N*state.task.dt -15 15]);
        subplot(4,1,3)
        plot(t,P(3,:));
        hold on;
        plot(t,ones(1,N)*des(3,j),'r');
        ylabel('pz [m]');
        grid on;
        axis([0 N*state.task.dt -15 15]);
        subplot(4,1,4)
        plot(t,A);
        hold on;
        plot(t,ones(1,N)*des(4,j),'r');
        ylabel('heading [rad]');
        grid on;
        axis([0 N*state.task.dt -pi pi]);        
        xlabel('t[s]');
    end
    
    diffd = norm(state.platforms{1}.getX(1:3)-des(1:3,j));
    diffa = abs(state.platforms{1}.getX(6)-des(4,j));    
    if(~((diffd<told)&&(diffa<tola))&&state.platforms{1}.isValid())
        e = e | 1;
    end
    qrsim.reset();
    pid.reset();
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

addpath(['..',filesep,'..',filesep,'controllers']);

% number of steps we run the simulation for
N = 400;

% create simulator object
qrsim = QRSim();

% load task parameters and do housekeeping
state = qrsim.init('TaskNoWind');

des = [ -2,    0,   2,   -2,   0,     0;
         0,    0,   0,    0,   2,    -2;
         0,   -2,   0,    0,   0,     0;
         0, pi/4,   0, pi/2,   0, -pi/3]; 

pid = VelocityPID(state.DT);
t = (1:N)*state.task.dt;
for j = 1:size(des,2)
    if(plots)
        figure(j);
        VV=[];
        A=[];
    end
    for i=1:N,
        % compute controls
        U=pid.computeU(state.platforms{1}.getEX(),des(1:3,j),des(4,j));
        
        % step simulator
        qrsim.step(U);
        if(plots)
            VV=[VV,[state.platforms{1}.getEX(18:19);-state.platforms{1}.getEX(20)]];
            A=[A,state.platforms{1}.getEX(6)];
        end
    end
    
    if(plots)
        subplot(4,1,1);
        plot(t,VV(1,:));
        hold on;
        plot(t,ones(1,N)*des(1,j),'r');
        ylabel('vx [m/s]');
        grid on;
        axis([0 N*state.task.dt -3 3]);
        subplot(4,1,2)
        plot(t,VV(2,:));
        hold on;
        plot(t,ones(1,N)*des(2,j),'r');
        ylabel('vy [m/s]');
        grid on;
        axis([0 N*state.task.dt -3 3]);
        subplot(4,1,3)
        plot(t,VV(3,:));
        hold on;
        plot(t,ones(1,N)*des(3,j),'r');
        ylabel('vz [m/s]');
        grid on;
        axis([0 N*state.task.dt -3 3]);
        subplot(4,1,4)
        plot(t,A);
        hold on;
        plot(t,ones(1,N)*des(4,j),'r');
        ylabel('heading [rad]');
        grid on;
        axis([0 N*state.task.dt -pi pi]);
        xlabel('t[s]');
    end
    
    diffv = norm([state.platforms{1}.getEX(18:19)-des(1:2,j);-state.platforms{1}.getEX(20)-des(3,j)]);
    diffa = abs(state.platforms{1}.getEX(6)-des(4,j));
    if(~(diffv<tolv)&&(diffa<tola)&&state.platforms{1}.isValid())
        e = e | 1;
    end
    qrsim.reset();
    pid.reset();
end

jj = j;
for j = 1:size(des,2)
    if(plots)
        figure(jj+j);
        VV=[];
        A=[];
    end    
    for i=1:N,
        % compute controls
        U=pid.computeU(state.platforms{1}.getX(),des(1:3,j),des(4,j));
        
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
        plot(t,VV(1,:));
        hold on;
        plot(t,ones(1,N)*des(1,j),'r');
        ylabel('vx [m/s]');
        grid on;
        axis([0 N*state.task.dt -3 3]);
        subplot(4,1,2)
        plot(t,VV(2,:));
        hold on;
        plot(t,ones(1,N)*des(2,j),'r');
        ylabel('vy [m/s]');
        grid on;
        axis([0 N*state.task.dt -3 3]);
        subplot(4,1,3)
        plot(t,VV(3,:));
        hold on;
        plot(t,ones(1,N)*des(3,j),'r');
        ylabel('vz [m/s]');
        grid on;
        axis([0 N*state.task.dt -3 3]);
        subplot(4,1,4)
        plot(t,A);
        hold on;
        plot(t,ones(1,N)*des(4,j),'r');
        ylabel('heading [rad]');
        grid on;
        axis([0 N*state.task.dt -pi pi]);
        xlabel('t[s]');        
    end
    
    vv=dcm(state.platforms{1}.getX())'*state.platforms{1}.getX(7:9);
    diffv = norm(vv(1:3)-des(1:3,j));
    diffa = abs(state.platforms{1}.getX(6)-des(4,j));
    if(~(diffv<tolv)&&(diffa<tola)&&state.platforms{1}.isValid())
        e = e | 1;
    end
    qrsim.reset();
    pid.reset();
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

addpath(['..',filesep,'..',filesep,'controllers']);


% create simulator object
qrsim = QRSim();

% load task parameters and do housekeeping
state = qrsim.init('TaskNoWind');

% number of steps we run the simulation for
N = 700;

des = [ -2,    2,   2,   -2,   0,     0;
         0,    0,   0,    0,   2,    -2;
         0,    0,   0,    0,  10,   -10;
         0, pi/4,   0, pi/2,   0, -pi/3]; 
     
pid = VelocityHeightPID(state.DT);

t = (1:N)*state.task.dt;
for j = 2:size(des,2)
    if(plots)
        figure(j);
        VV=[];
        Z=[];
        A=[];
    end
    for i=1:N,
        % compute controls
        U=pid.computeU(state.platforms{1}.getEX(),des(1:2,j),des(3,j),des(4,j));
        
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
        plot(t,VV(1,:));
        hold on;
        plot(t,ones(1,N)*des(1,j),'r');
        ylabel('vx [m/s]');
        grid on;
        axis([0 N*state.task.dt -3 3]);
        subplot(4,1,2)
        plot(t,VV(2,:));
        hold on;
        plot(t,ones(1,N)*des(2,j),'r');
        ylabel('vy [m/s]');
        grid on;
        axis([0 N*state.task.dt -3 3]);
        subplot(4,1,3)
        plot(t,Z);
        hold on;
        plot(t,ones(1,N)*des(3,j),'r');
        ylabel('z [m]');
        grid on;
        axis([0 N*state.task.dt -12 12]);
        subplot(4,1,4)
        plot(t,A);
        hold on;
        plot(t,ones(1,N)*des(4,j),'r');
        ylabel('heading [rad]');
        grid on;
        axis([0 N*state.task.dt -pi pi]);
        xlabel('t[s]');        
    end
    
    diffv = norm(state.platforms{1}.getEX(18:19)-des(1:2,j));
    diffh = abs(-state.platforms{1}.getEX(17)-des(3,j));
    diffa = abs(state.platforms{1}.getEX(6)-des(4,j));
    if(~(diffv<tolv)&&(diffh<tolh)&&(diffa<tola)&&state.platforms{1}.isValid())
        e = e | 1;
    end
    qrsim.reset();
    pid.reset();
end

jj = j;
for j = 1:size(des,2)
    if(plots)
        figure(jj+j);
        VV=[];
        Z=[];
        A=[];
    end
    for i=1:N,
        % compute controls
        U=pid.computeU(state.platforms{1}.getX(),des(1:2,j),des(3,j),des(4,j));
        
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
        plot(t,VV(1,:));
        hold on;
        plot(t,ones(1,N)*des(1,j),'r');
        ylabel('vx [m/s]');
        grid on;
        axis([0 N*state.task.dt -3 3]);
        subplot(4,1,2)
        plot(t,VV(2,:));
        hold on;
        plot(t,ones(1,N)*des(2,j),'r');
        ylabel('vy [m/s]');
        grid on;
        axis([0 N*state.task.dt -3 3]);
        subplot(4,1,3)
        plot(t,Z);
        hold on;
        plot(t,ones(1,N)*des(3,j),'r');        
        ylabel('z [m]');
        axis([0 N*state.task.dt -12 12]);
        grid on;
        subplot(4,1,4)
        plot(t,A);
        hold on;
        plot(t,ones(1,N)*des(4,j),'r');
        ylabel('heading [rad]');
        axis([0 N*state.task.dt -pi pi]);
        grid on;
        xlabel('t[s]');        
    end
    
    vv=dcm(state.platforms{1}.getX())'*state.platforms{1}.getX(7:9);
    diffv = norm(vv(1:2)-des(1:2,j));
    diffh = abs(state.platforms{1}.getX(3)-des(3,j));
    diffa = abs(state.platforms{1}.getX(6)-des(4,j));
    if(~(diffv<tolv)&&(diffh<tolh)&&(diffa<tola)&&state.platforms{1}.isValid())
        e = e | 1;
    end
    qrsim.reset();
    pid.reset();
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

addpath(['..',filesep,'..',filesep,'controllers']);

% number of steps we run the simulation for
N = 700;

% create simulator object
qrsim = QRSim();

% load task parameters and do housekeeping
state = qrsim.init('TaskNoWind');
   
des = [  0,    0,   0,     0;
         0,    0,   0,     0;
         0,    0,  10,   -10;
         0, pi/4,   0, -pi/3];    

pid = VelocityHeightPID(state.DT);
t = (1:N)*state.task.dt;
for j = 1:size(des,2)
    if(plots)
        figure(j);
        PT=[];
        Z=[];
        A=[];
    end
    for i=1:N,
        % compute controls
        U=pid.computeU(state.platforms{1}.getEX(),des(1:2,j),des(3,j),des(4,j));
        
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
        plot(t,PT(1,:));
        hold on;
        plot(t,ones(1,N)*des(1,j),'r');
        ylabel('phi [rad]');
        grid on;
        axis([0 N*state.task.dt -3 3]);
        subplot(4,1,2)
        plot(t,PT(2,:));
        hold on;
        plot(t,ones(1,N)*des(2,j),'r');
        ylabel('theta [rad]');
        grid on;
        axis([0 N*state.task.dt -3 3]);
        subplot(4,1,3)
        plot(t,Z);
        hold on;
        plot(t,ones(1,N)*des(3,j),'r');
        ylabel('z [m]');
        grid on;
        axis([0 N*state.task.dt -12 12]);
        subplot(4,1,4)
        plot(t,A);
        hold on;
        plot(t,ones(1,N)*des(4,j),'r');
        ylabel('heading [rad]');
        grid on;
        axis([0 N*state.task.dt -pi pi]);
    end
    
    diffpt = norm(state.platforms{1}.getEX(4:5)-des(1:2,j));
    diffh = abs(-state.platforms{1}.getEX(17)-des(3,j));
    diffa = abs(state.platforms{1}.getEX(6)-des(4,j));
    if(~(diffpt<tolpt)&&(diffh<tolh)&&(diffa<tola)&&state.platforms{1}.isValid())
        e = e | 1;
    end
    qrsim.reset();
    pid.reset();
end

jj = j;
for j = 1:size(des,2)
    if(plots)
        figure(jj+j);
        PT=[];
        Z=[];
        A=[];
    end
    for i=1:N,
        % compute controls
        U=pid.computeU(state.platforms{1}.getX(),des(1:2,j),des(3,j),des(4,j));
        
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
        plot(t,PT(1,:));
        hold on;
        plot(t,ones(1,N)*des(1,j),'r');
        ylabel('phi [rad]');
        grid on;
        axis([0 N*state.task.dt -3 3]);
        subplot(4,1,2)
        plot(t,PT(2,:));
        hold on;
        plot(t,ones(1,N)*des(2,j),'r');
        ylabel('theta [rad]');
        grid on;
        axis([0 N*state.task.dt -3 3]);
        subplot(4,1,3)
        plot(t,Z);
        hold on;
        plot(t,ones(1,N)*des(3,j),'r');        
        ylabel('z [m]');
        axis([0 N*state.task.dt -12 12]);
        grid on;
        subplot(4,1,4)
        plot(t,A);
        hold on;
        plot(t,ones(1,N)*des(4,j),'r');
        ylabel('heading [rad]');
        axis([0 N*state.task.dt -pi pi]);
        grid on;
        xlabel('t[s]');        
    end
    
    diffpt = norm(state.platforms{1}.getX(4:5)-des(1:2,j));
    diffh = abs(state.platforms{1}.getX(3)-des(3,j));
    diffa = abs(state.platforms{1}.getX(6)-des(4,j));
    if(~(diffpt<tolpt)&&(diffh<tolh)&&(diffa<tola)&&state.platforms{1}.isValid())
        e = e | 1;
    end
    qrsim.reset();
    pid.reset();
end

if(e)
    fprintf('Test AngleHeightPID [FAILED]\n');
else
    fprintf('Test AngleHeightPID [PASSED]\n');
end

end
