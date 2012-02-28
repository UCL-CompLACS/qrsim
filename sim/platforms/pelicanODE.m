function [xdot,a] = pelicanODE(X,U,dt)
%PELICANODE set of ODE that represent the platform dynamic

LOW_THROTTLE_LIMIT = 300;
MAX_ANGVEL=degsToRads(150);
G = 9.81;

% rotational params
pq0 = -3.25060e-04;
pq1 = 1.79797e+02;
pq2 = -24.3536;
r0 = -4.81783e-03;
r1 = -5.08944;

% thrust params
Cth0 = 6.63881e-01;
Cth1  =7.44649e-04;
Cth2   =2.39855e-06;
Cvb0   = -18.0007;
Cvb1   = 4.23754;
tau0   = 3.07321;
tau1   = 46.8004;

% linear drag params
kuv = -4.97391e-01;
kw =  -1.35341;

% not vectorized in any way since
% we have a MEX for it
xdot = zeros(13,1);

pt = U(1);
rl = U(2);
th = U(3);
ya = U(4);
vb = U(5);

wind = U(6:8);

mass = U(9);

noise = U(10:15);

phi = X(4);
theta = X(5);
psi = X(6);
u = X(7);
v = X(8);
w = X(9);
p = X(10);
q = X(11);
r = X(12);
Fth = X(13);

% handy values
sph = sin(phi); cph = cos(phi);
sth = sin(theta); cth = cos(theta); tth = sth/cth;
sps = sin(psi); cps = cos(psi);

D = [                   (cth * cps),                    (cth * sps),      (-sth);
    (-cph * sps + sph * sth * cps),  (cph * cps + sph * sth * sps), (sph * cth);
    (sph * sps + cph * sth * cps), (-sph * cps + cph * sth * sps), (cph * cth)];


%%%% meat

% angles
xdot(4) = p+q*sph*tth+r*cph*tth;
xdot(5) = q*cph - r*sph;
xdot(6) = q*sph/cth+r*cph/cth;

% angular velocities (body frame)
xdot(10) = pq1*(pq0*rl - phi) + pq2*p;

if(p>MAX_ANGVEL && (xdot(10)>0))
    xdot(10) = 0;
elseif(p<-MAX_ANGVEL && (xdot(10)<0))
    xdot(10) = 0;
end

xdot(11) = pq1*(pq0*pt - theta) + pq2*q;

if(q>MAX_ANGVEL && (xdot(11)>0))
    xdot(11) = 0;
elseif(q<-MAX_ANGVEL && (xdot(11)<0))
    xdot(11) = 0;
end

xdot(12) = r0*ya + r1*r;

% position
xdot(1:3)= D'*[u;v;w];

%linear velocities (body frame)

% first we update the thrust force
dFth = ((Cth0 + Cth1*th + Cth2*th^2)-Fth);

if (th<LOW_THROTTLE_LIMIT)
    xdot(13) = tau0*dFth;
else
    if (abs(dFth)<tau1*dt)
        tau=dFth/dt;
    else if (dFth>0)
            tau = tau1;
        else
            tau = -tau1;
        end
    end
    
    if((Fth + tau*dt) > Cvb0+Cvb1*vb)
        xdot(13) = (Cvb0+Cvb1*vb - Fth)/dt;
    else
        xdot(13) = tau;
    end
end

% acceleration in body frame
gb = D*[0;0;G];

%resultant acceleration in body frame
%note: thrust force always orthogonal to the rotor
%plane i.e. in the  -Z body direction
ra = [0;0;-(Fth+xdot(13)*dt)]/mass + gb;

% wind influence added as in Simulink example "Lightweight Airplane Design"
% asbSkyHogg/VehicleSystemModel/Vehicle/Aerodynamics/DerivedConditions
xdot(7) = -q*w + r*v + ra(1) + kuv*(u-wind(1));
xdot(8) = -r*u + p*w + ra(2) + kuv*(v-wind(2));
xdot(9) = -p*v + q*u + ra(3) + kw*(w-wind(3));

% an accelerometer can not measure the 
a = xdot(7:9)-gb;

% finally we add the noise
xdot(7:12) = xdot(7:12)+noise;

end

