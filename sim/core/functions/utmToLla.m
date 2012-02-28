function  lla = utmToLla(E,N,utmzone,h)
% UTMTOLLA Converts UTM coordinates to geodetic coordinates .
% 
% LLA = UTMTOLLA(E,N,UTMZONE,H) converts 4 1-by-N arrays of UTM coordinates to a 3-by-N
% array of geodetic coordinates (latitude, longitude and altitude), LLA.
% LLA is in [degrees degrees meters].  E is in meters, N is in meters, H is in meters,
% UTMZONE is a 3char string.
% Straight implementation of http://www.lantmateriet.se/upload/filer/kartor/
% geodesi_gps_och_detaljmatning/geodesi/Formelsamling/Gauss_Conformal_Projection.pdf
%
% Examples:
%
%      lla = utmToLla( 6.927085783032901e+05, 5.732679017252645e+06,'30U',0)
%

n1=length(E);
n2=length(N);
n3=size(utmzone,2);
n4=length(h);

if (n1~=n2 || n1~=n3 || n1~=n4)
    error('E,N,h and utmzone vectors should have the same number or columns');
end
c=size(utmzone,1);
if (c~=3)
    error('utmzone should be a vector of strings like "30T" instead it is %s',utmzone);
end

% useful WGS84 constants
f = 1/298.257223563;
%a = 6378137;

e2 = f*(2-f);
e = sqrt(abs(e2));
e2m = (1 - e2);

n_ = f/(2-f);

FE = 500000;


k0 = 0.9996;
a1 = 6367449.14582;
maxpow = 6;

tol_ = 1.49011611938e-09;

nx = n_*n_;

bet(1) = n_*(n_*(n_*(n_*(n_*(384796*n_-382725)-6720)+932400)-1612800)+1209600)/2419200;
bet(2) = nx*(n_*(n_*((1695744-1118711*n_)*n_-1174656)+258048)+80640)/3870720;
nx = nx*n_;
bet(3) = nx*(n_*(n_*(22276*n_-16929)-15984)+12852)/362880;
nx = nx*n_;
bet(4) = nx*((-830251*n_-158400)*n_+197865)/7257600;
nx = nx*n_;
bet(5) = (453717-435388*n_)*nx/15966720;
nx = nx*n_;
bet(6) = 20648693*nx/638668800;

% Memory pre-allocation
%
lla=zeros(3,n1);


% Main Loop
%
for i=1:n1
    
    if (utmzone(3,i)>'X' || utmzone(3,i)<'C')
        error('utmToLla: utmzone should be a vector of strings like "30T"\n');
    end
    
    if (utmzone(3,i)>'M')
        FN = 0;
    else
        FN = 10000000;
    end
    
    x=E(i)-FE;
    y=N(i)-FN;
    
    zone=str2double(utmzone(1:2,i));
    lon0 = ( ( zone * 6 ) - 183 );
    
    xi = y / (a1*k0);
    eta = x / (a1*k0);
    
    % Explicitly enforce the parity
    if(xi < 0), xisign = -1;  else  xisign = 1; end
    if(eta < 0), etasign = -1; else etasign =1; end
    
    xi = xi*xisign;
    eta = eta*etasign;
    
    backside = (xi > pi/2);
    
    if (backside)
        xi = pi - xi;
    end
    c0 = cos(2 * xi);
    ch0 = cosh(2 * eta);
    s0 = sin(2 * xi);
    sh0 = sinh(2 * eta);
    ar = 2 * c0 * ch0;
    ai = -2 * s0 * sh0; % 2 * cos(2*zeta)
    n = maxpow;
    
    % Accumulators for zeta'
    if(bitand(n,1))
        xip0 = -bet(n);
    else
        xip0 = 0;
    end
    etap0 = 0;
    xip1 = 0;
    etap1 = 0;
    % Accumulators for dzeta'/dzeta
    if(bitand(n,1))
        yr0 = - 2 * maxpow * bet(n);
        n = n-1;
    else
        yr0 = 0;
    end
    yi0 = 0;
    yr1 = 0;
    yi1 = 0;
    while (n>0)
        xip1  = ar * xip0 - ai * etap0 - xip1 - bet(n);
        etap1 = ai * xip0 + ar * etap0 - etap1;
        yr1 = ar * yr0 - ai * yi0 - yr1 - 2 * n * bet(n);
        yi1 = ai * yr0 + ar * yi0 - yi1;
        n=n-1;
        xip0  = ar * xip1 - ai * etap1 - xip0 - bet(n);
        etap0 = ai * xip1 + ar * etap1 - etap0;
        yr0 = ar * yr1 - ai * yi1 - yr0 - 2 * n * bet(n);
        yi0 = ai * yr1 + ar * yi1 - yi0;
        n=n-1;
    end
    ar = s0 * ch0;
    ai = c0 * sh0; 
    xip  = xi  + ar * xip0 - ai * etap0;
    etap = eta + ai * xip0 + ar * etap0;
    % Convergence and scale for Gauss-Schreiber TM to Gauss-Krueger TM.
    s = sinh(etap);
    c = max(0, cos(xip)); % cos(pi/2) might be negative
    r = hypot(s, c);
    if (r ~= 0)
        lam = atan2(s, c);        % Krueger p 17 (25)
        % Use Newton's method to solve for tau
        
        taup = sin(xip)/r;
        % To lowest order in e^2, taup = (1 - e^2) * tau = _e2m * tau; so use
        % tau = taup/_e2m as a starting guess.  Only 1 iteration is needed for
        % |lat| < 3.35 deg, otherwise 2 iterations are needed. 
        tau = taup/e2m;
        stol = tol_ * max([1,abs(taup)]);
        % min iterations = 1, max iterations = 2; mean = 1.94
        for j = 1:5,
            tau1 = hypot(1, tau);
            sig = sinh( e*atanh(e* tau / tau1 ) );
            taupa = hypot(1, sig) * tau - sig * tau1;
            dtau = (taup-taupa)*(1+e2m*tau^2)/(e2m*tau1*hypot(1, taupa));
            tau = tau + dtau;
            if (~(abs(dtau) >= stol))
                break;
            end
        end
        phi = atan(tau);
    else
        phi = pi/2;
        lam = 0;
    end
    lat = phi / (pi/180) * xisign;
    lon = lam / (pi/180);
    if (backside)
        lon = 180 - lon;
    end
    lon = lon*etasign;
    
    % Avoid losing a bit of accuracy in lon (assuming lon0 is an integer)
    if (lon + lon0 >= 180)
        lon = lon + lon0 - 360;
    else if (lon + lon0 < -180)
            lon = lon + lon0 + 360;
        else
            lon = lon + lon0;
        end
    end
    
    lla(:,i)=[lat;lon;h(i)];
    
end