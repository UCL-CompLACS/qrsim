function U = quadrotorVelPID(X,vt)

%  quadrotorVelPID simple nested loops PID controller that can fly a quadrotor
%  given a target linear velocity. The platform axes are considered decoupled.
%  
%  An appropriate attitude is enforced by a P controller that tries to achieve 
%  the desired linear velocity
%



Kv = 0.4;
Kw = -0.6;
maxtilt = 0.34;

u = X(7);
v = X(8);
w = X(9);

desu = limit( vt(1),-3,3);
desTheta = Kv*(-(desu - u));
desTheta = limit(desTheta,-maxtilt,maxtilt); 
 
desv = limit( vt(2),-3,3);
desPhi = Kv*(desv - v);
desPhi = limit(desPhi,-maxtilt,maxtilt); 

desw = limit( vt(3),-3,3);
desth = 0.59 + Kw*(desw - w);
th = limit(desth,0,1);

ya = 0;


U(1,1) = desTheta;
U(2,1) = desPhi;
U(3,1) = th;
U(4,1) = ya;
U(5,1) = 10;
end

function v = limit(v, minval, maxval)

v = max([min([maxval,v]),minval]);

end