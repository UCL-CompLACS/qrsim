function U = quadrotorPID(X,wp)

%  quadrotorPID simple nested loops PID controller that can fly a quadrotor
%  given a target waypoint (wp). The platform axes are considered decoupled.
%  
%  The desidred attitude is enforced by a P controller that tries to achieve a 
%  linear velocity proportional to the  distance from the target.
%  Limits are in place to not reach dangerous velocities.
%

global pid;


if(~isfield(pid,'iz') || isnan(pid.ez) || isnan(pid.iz))
    pid.iz = 0;
    pid.ez = 0; 
    pid.wp = [0,0,0,0];
end

global state;

if(~all(pid.wp==wp))
    wpChange=1;
    pid.wp = wp;
else
    wpChange = 0;
end

x = X(1);
y = X(2);
z = X(3);
psi = X(6);
%u = X(7);
%v = X(8);

pxdot = X(18);
pydot = X(19);

Kxy =0.3;
Kv = 0.09;
maxtilt = 0.34;

% rotationg the wp to body coordinates
d = ((wp(1)-x)^2+(wp(2)-y)^2)^0.5;
a = (atan2((wp(2)-y),(wp(1)-x)) - psi);

bx = d * cos(a);
by = d * sin(a);

vel = sqrt(pxdot*pxdot+pydot*pydot);
u = vel * cos(a);
v = vel * sin(a);

% simple P controller on velocity with a cap on the max velocity and
% maxtilt
desu = limit( Kxy*bx,-5,5);
desTheta = Kv*(-(desu - u));
desTheta = limit(desTheta,-maxtilt,maxtilt); 

desv = limit( Kxy*by,-5,5);
desPhi = Kv*(desv - v);
desPhi = limit(desPhi,-maxtilt,maxtilt); 

Kya = 6;
maxyawrate = 4.4;
ya = limit(Kya * (wp(4) - psi),-maxyawrate,maxyawrate);

Kiz = 0.0008;
Kpz = 0.03;
Kdz = 0.04;

% vertical controller is a full PID
ez = -(wp(3) - z);

pid.iz = pid.iz + ez *state.DT;
if(~wpChange)
    de = (ez - pid.ez)/state.DT;
else
    disp('wp change');
    de =  0;
end
pid.ez = ez;

desth = 0.59 + Kpz * ez + Kiz * pid.iz + de * Kdz;
th = limit(desth,0,1);

% anti windup
pid.iz = pid.iz - (desth-th)*2;

U(1,1) = desTheta;
U(2,1) = desPhi;
U(3,1) = th;
U(4,1) = ya;
U(5,1) = 10;
end

function v = limit(v, minval, maxval)

v = max([min([maxval,v]),minval]);

end