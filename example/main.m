% bare bones example of use of the simulator object
%clear all
close all
global state;

% only needed if using the pid controller
clear global pid;

% create simulator object
qrsim = QRSim();

% load task parameters and do housekeeping
qrsim.init('KeepSpot');

% number of steps we run the simulation for
N = 3000;


% add a simple 2D plot of the helicopter altitude
figure(2);
hanz = plot(0,0,0,0);

XX1=zeros(2,N/20);
XX2=zeros(2,N/20);
xlabel('time[s]');
ylabel('h [m]');
idx=1;

% desired px,py,pz and desired platform heading
wp =[0,0,-20,pi/2];

for i=1:N,
    tloop=tic;
    
    if(i>200)
        wp = [15,15,-10,-pi/2];
    end
    
    if(i>1500)
        wp = [0,0,-30,0];
    end
    
    if(i>2500)
        wp = [0,0,-20,-pi/2];
    end
    % compute controls
    U=quadrotorPID(state.platforms(1).eX,wp);%state.platforms(1).params.X(1:3));
    
    % step simulator
    qrsim.step(U);
    
    % get reward
    % qrsim.reward();
    
    % wait so to run in real time
    wait = max(0,state.DT-toc(tloop));
    pause(wait);
    
    if(mod(i,20)==0)
        XX1(:,idx)=state.platforms(1).eX(18:19);
        
        
        sph = sin(state.platforms(1).X(4)); cph = cos(state.platforms(1).X(4));
        sth = sin(state.platforms(1).X(5)); cth = cos(state.platforms(1).X(5));
        sps = sin(state.platforms(1).X(6)); cps = cos(state.platforms(1).X(6));
        
        dcm = [                (cth * cps),                   (cth * sps),     (-sth);
            (-cph * sps + sph * sth * cps), (cph * cps + sph * sth * sps),(sph * cth);
            (sph * sps + cph * sth * cps),(-sph * cps + cph * sth * sps),(cph * cth)];
        
        % velocity in global frame
        gvel = (dcm')*state.platforms(1).X(7:9);
        
        XX2(:,idx)=gvel(1:2);
        
        % update the altitude plot
        t = 1:idx;
        set(hanz(1),'Xdata',t.*20*state.DT);
        set(hanz(1),'Ydata',XX1(2,1:idx));
        set(hanz(2),'Xdata',t.*20*state.DT);
        set(hanz(2),'Ydata',XX2(2,1:idx));
        idx=idx+1;
    end
    
    %disp(' ');
end

%global state;

% speed note:
% to have the simulation running considerably faster,
% you might want to compile the various mex files that are in the project
% running the mexify.m script.

%clear all;
%close all;
%clear classes;
%clc;

%qrsim = QRSim();

%global state;

% load parameters and do housekeeping
% always to be executed before anything else!!
% check default_config for the set of config parameters
% including dt
%qrsim.init('KeepSpot');

% as controller one could use a joystick
% (note: needs matlab vr toolbox)
%joy = vrjoystick(1);


% instantiate helicopter
% at position 0,1,-6 (note that Z is negative we use NED!!)
% and orientation 0,0,0
%h = Pelican([0,1,-6, 0, 0, 0]);

% number of steps we run the simulation for
%N = 30000;
%fprintf('simulating %d minutes of real time\n',(N*state.DT)/60);


% add a simple 2D plot of the helicopter altitude
%figure(2);
%hanxy1 = plot(0,0);
%XX1=zeros(3,N/20);
%xlabel('time[s]');
%ylabel('x y [m]');

%idx=1;

%tbegin = tic;
%for i=1:N,

%    fprintf('time t = %f\n',state.t);

%    tloop=tic;

%state.environment.gpsspacesegment.step([]);
%state.environment.wind.step([]);

% read input from joystick
%U = joy2input(read(joy));

% alterantively define a constant input
% note that the one below is a trim state and will
% not produce any motion of the platform
%    U=[0.2;0.01;0.59;0.2;10];

% alternatively one could compute the helicopter
% input given the current state and a target


% thep the dynamics foward
%state.platforms(1).step(U);

%    qrsim.step(U);

% let's add to the plot one of the
% helicopter states, namely altitude
% note: this needs the imu noise to be on
%    if(mod(i,20)==0)
%    XX1(:,idx)=state.platforms(1).eX(1:3);
%    idx=idx+1;
%    end
% update the altitude plot
%    t = 1:i;
%set(hanxy1,'Xdata',XX1(1,1:i));%t.*state.DT);
%set(hanxy1,'Ydata',XX1(2,1:i));

%if (params.display3d.on ==1)
%        wait = max(0,state.DT-toc(tloop));
%        pause(wait);
%end

% state.t=state.t+state.DT;
%end
%a=toc(tbegin);

%if (params.display3d.on ==0)
%    nrt = params.dt/(a/N);
%    fprintf('running %d times realtime \n',nrt);
%end


%mE = mean(XX1(1,:));
%mN = mean(XX1(2,:));

% a little picture...
%figure('Position',[10 10 400 400]);
%plot(XX1(1,:)-mE,XX1(2,:)-mN,'k');
%axis equal;
%grid on;

%figure();
%subplot(2,1,1);
%p = spectrum.periodogram;
%hp = psd(p,XX1(2,:)-mE,'Fs',5);
%plot(hp);
%axis([0 2.5 -70 30]);

%subplot(2,1,2);
%p = spectrum.periodogram;
%hp = psd(p,XX1(2,:)-mN,'Fs',5);
%plot(hp);
%axis([0 2.5 -70 30]);


%figure();
%plot(xcorr(XX1(2,:)-mN))
%plot(xcorr(XX1(1,:)-mE))

