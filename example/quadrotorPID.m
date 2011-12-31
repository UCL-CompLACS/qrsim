function U = quadrotorPID(X,wp)

%  quadrotorPID simple nested loops PID controller that can fly a quadrotor
%  given a target waypoint (wp). The platform axes are considered decoupled.
%  
%  The desidred attitude is enforced by a P controller that tries to achieve a 
%  linear velocity proportional to the  distance from the target.
%  Limits are in place to not reach dangerous velocities.
%

global pid;

x = X(1);
y = X(2);
z = X(3);
u = X(4);
v = X(5);
psi = X(9);


Kxy =0.3;
Kv = 0.09;
maxtilt = 0.34;

% rotationg the wp to body coordinates
d = ((wp(1)-x)^2+(wp(2)-y)^2)^0.5;
a = (atan2((wp(2)-y),(wp(1)-x)) - psi);

bx = d * cos(a);
by = d * sin(a);


% simple P controller on velocity with a cap on the max velocity and
% maxtilt
desu = limit( Kxy*bx,-5,5);
desTheta = Kv*(-(desu - u));
desTheta = limit(desTheta,-maxtilt,maxtilt); 

desv = limit( Kxy*by,-5,5);
desPhi = Kv*(desv - v);
desPhi = limit(desPhi,-maxtilt,maxtilt); 


Kiz = 0.0002;
Kpz = 0.005;
Kdz = 1.2;

% vertical controller is a full PID
ez = (wp(3) - z);

if(~isfield(pid,'iz'))
    pid.iz = 0;
    pid.ez = 0;
end

th = 0.48 + Kpz * ez + Kiz * pid.iz + (ez - pid.ez) * Kdz;

pid.ez = ez;
pid.iz = pid.iz + ez;


U(1,1) = desTheta;
U(2,1) = desPhi;
U(3,1) = th;
U(4,1) = 0;
U(5,1) = 10;
end

function v = limit(v, minval, maxval)

v = max([min([maxval,v]),minval]);

end