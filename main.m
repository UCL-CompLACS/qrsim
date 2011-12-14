
% speed note:
% to have the simulation running considerably faster, 
% you might want to compile the various mex files that are in the project
% running the mexify.m script.

%clear all;
close all;
%clear classes;
clc;


%global state;

% load parameters and do housekeeping
% always to be executed before anything else!!
% check default_config for the set of config parameters
% including dt
state = init('default_config');

% as controller one could use a joystick
% (note: needs matlab vr toolbox)
%joy = vrjoystick(1);


% instantiate helicopter 
% at position 0,1,-6 (note that Z is negative we use NED!!)
% and orientation 0,0,0
%h = Pelican([0,1,-6, 0, 0, 0]);

% turn on plotting of the trajectory in the 3D plot
state.platforms(1).plotTrajectory(1);

% number of steps we run the simulation for
N = 30000;
fprintf('simulating %d minutes of real time\n',(N*state.DT)/60);


% add a simple 2D plot of the helicopter altitude
%figure(2);
%hanxy1 = plot(0,0);
XX1=zeros(3,N/20);
%xlabel('time[s]');
%ylabel('x y [m]');

idx=1;

tbegin = tic;
for i=1:N,
    
    tloop=tic;  
    
    % read input from joystick
    %U = joy2input(read(joy));
    
    % alterantively define a constant input
    % note that the one below is a trim state and will 
    % not produce any motion of the platform
    U=[0;0;0.59;0;10];
    
    % alternatively one could compute the helicopter
    % input given the current state and a target 
    
    
    % thep the dynamics foward
    state.platforms(1).step(U);
    
    % let's add to the plot one of the
    % helicopter states, namely altitude
    % note: this needs the imu noise to be on
    if(mod(i,20)==0)
    XX1(:,idx)=state.platforms(1).pseudoX(1:3);
    idx=idx+1;
    end    
    % update the altitude plot
    t = 1:i;
    %set(hanxy1,'Xdata',XX1(1,1:i));%t.*state.DT);
    %set(hanxy1,'Ydata',XX1(2,1:i));

    % update graphical output
    % this runs only if the graphics is turned on
    state.platforms(1).updateGraphics();
    
    if (params.display3d.on ==1)
        wait = max(0,state.DT-toc(tloop));   
        pause(wait);
    end
    
    state.t=state.t+state.DT;
end
a=toc(tbegin);

if (params.display3d.on ==0)
    nrt = params.dt/(a/N);
    fprintf('running %d times realtime \n',nrt);
end


mE = mean(XX1(1,:));
mN = mean(XX1(2,:));

% a little picture...
figure('Position',[10 10 400 400]);
plot(XX1(1,:)-mE,XX1(2,:)-mN,'k');
axis equal;
grid on;

figure();
subplot(2,1,1);
p = spectrum.periodogram;
hp = psd(p,XX1(2,:)-mE,'Fs',5);
plot(hp);
%axis([0 2.5 -70 30]);

subplot(2,1,2);
p = spectrum.periodogram;
hp = psd(p,XX1(2,:)-mN,'Fs',5);
plot(hp);
%axis([0 2.5 -70 30]);


%figure();
%plot(xcorr(XX1(2,:)-mN))
%plot(xcorr(XX1(1,:)-mE))

