
clear all;
clc;

rand('state',37); % set arbitrary seed for uniform draws


% number of random targets in the environment
NUM_TARGETS = 100;
% we assume the enviroment to be a 3D box ENVIRONMENT_SIZE x ENVIRONMENT_SIZE x ENVIRONMENT_HEIGHT centered in the origin
ENVIRONMENT_SIZE = 200;
ENVIRONMENT_HEIGHT = 0.01;


% taken from one of the calibration of a 
% point grey chameleon with a 8mm lens
f = [2280; 2280];  % focal length
c = [640; 480];    % principal points

%targets=[ENVIRONMENT_SIZE/2-ENVIRONMENT_SIZE.*rand(2,NUM_TARGETS);ENVIRONMENT_HEIGHT.*rand(1,NUM_TARGETS)];

targets=[repmat(-2.5:0.5:2.5,1,11);reshape(repmat(-2.5:0.5:2.5,11,1),1,11*11);zeros(1,121)];


%camera position and orientation

% translation
t = [0;0;-50];

% rotation series of 3 rotations around the new axis in zyx order
angle = [0,0,pi/2];
R = angle2dcm(angle(3),angle(2),angle(1),'ZYX');

anglePlatform = [0.3,0,0.2];
Rp = angle2dcm(anglePlatform(3),anglePlatform(2),anglePlatform(1),'ZYX');

% points in front of the camera to
% display field of view, the distance chosen
% is arbitrary 
s=[  c(1)  c(1) -c(1) -c(1);
     c(2) -c(2)  c(2) -c(2);
     f(1)  f(1)  f(1)  f(1)]./1000;

% bring the chosen point to world coords
ss = Rp'*R'*s;
ss = ss+repmat(t,1,4);

% compute intersection point of the camera field
% of view with z=0
gp1 = zintersect(ss(:,1),t);
gp2 = zintersect(ss(:,2),t);
gp3 = zintersect(ss(:,3),t);
gp4 = zintersect(ss(:,4),t);



% 3D map plot
figure(1);
hold off;
title('map');

% targets
plot3(targets(1,:), targets(2,:),targets(3,:),'.');
axis equal;
axis([-300 300 -300 300 -140 0]);
xlabel('x');
ylabel('y');
zlabel('z');
grid on;
hold on;
%invert axis to be coherent with NED
set(gca,'ZDir','rev');
set(gca,'YDir','rev');  
            
% camera centre
plot3(t(1),t(2),t(3),'r*');

% sketch of the camera
plot3([t(1),ss(1,1)],[t(2),ss(2,1)],[t(3),ss(3,1)],'-r');
plot3([t(1),ss(1,2)],[t(2),ss(2,2)],[t(3),ss(3,2)],'-r');
plot3([t(1),ss(1,3)],[t(2),ss(2,3)],[t(3),ss(3,3)],'-r');
plot3([t(1),ss(1,4)],[t(2),ss(2,4)],[t(3),ss(3,4)],'-r');

plot3([ss(1,1),ss(1,2)],[ss(2,1),ss(2,2)],[ss(3,1),ss(3,2)],'-r');
plot3([ss(1,2),ss(1,4)],[ss(2,2),ss(2,4)],[ss(3,2),ss(3,4)],'-r');
plot3([ss(1,4),ss(1,3)],[ss(2,4),ss(2,3)],[ss(3,4),ss(3,3)],'-r');
plot3([ss(1,3),ss(1,1)],[ss(2,3),ss(2,1)],[ss(3,3),ss(3,1)],'-r');

% camera intersection with the z=0 plane
plot3([t(1),gp1(1)],[t(2),gp1(2)],[t(3),gp1(3)],'-g');
plot3([t(1),gp2(1)],[t(2),gp2(2)],[t(3),gp2(3)],'-g');
plot3([t(1),gp3(1)],[t(2),gp3(2)],[t(3),gp3(3)],'-g');
plot3([t(1),gp4(1)],[t(2),gp4(2)],[t(3),gp4(3)],'-g');

plot3([gp1(1),gp2(1)],[gp1(2),gp2(2)],[gp1(3),gp2(3)],'-g');
plot3([gp2(1),gp4(1)],[gp2(2),gp4(2)],[gp2(3),gp4(3)],'-g');
plot3([gp4(1),gp3(1)],[gp4(2),gp3(2)],[gp4(3),gp3(3)],'-g');
plot3([gp3(1),gp1(1)],[gp3(2),gp1(2)],[gp3(3),gp1(3)],'-g');




% targets in camera frame
uv = [];

for i=1:size(targets,2),    
    uvi = cam_prj(R*Rp, t ,targets(:,i),f,c); 
    if(~isempty(uvi))
        uv=[uv,uvi];  %#ok<AGROW>
    end
end

% image plot
figure(2);
clf
if(~isempty(uv))
    plot(uv(1,:),uv(2,:),'.r');
end
axis equal;
axis([0 1280 0 960]);
title('image');
% image origin on the top left 
% of the frame, x positive in the right 
% and y positive downwards
set(gca,'YDir','reverse') 
