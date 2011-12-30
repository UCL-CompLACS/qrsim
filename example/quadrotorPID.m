function U = quadrotorPID(X,wp)

%  CONTROLPID simple nested loops PID controller that can fly a quadrotor
%  given a target waypoint. The dimension are considered decoupled.
%  
%  At the inner level angles are tracked by a P controller that tries to
%  achieve the desired attitude. The desidred attitude is enforced by a P
%  controller that tries to achieve a linear velocity proportional to the
%  distance from the target. Caps are in place an the maximum angle and
%  maximum velocity that can be tracked.
%
%  Renzo De Nardi  r.denardi@ucl.ac.uk


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
d = ((wp.X-x)^2+(wp.Y-y)^2)^0.5;
a = (atan2((wp.Y-y),(wp.X-x)) - psi);

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
Kpz = 0.05;
Kdz = 1.2;

% vertical controller is a full PID
ez = (wp.Z - z);

th = 0.48 + Kpz * ez + Kiz * pid.iz + (ez - pid.ez) * Kdz;

pid.ez = ez;
pid.iz = pid.iz + ez;


U(1) = desTheta;
U(2) = desPhi;
U(3) = th;
U(4) = 0;
