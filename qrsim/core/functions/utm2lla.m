function  lla = utm2lla(E,N,utmzone,h)
%  UTM2LLA Converts UTM coordinates to geodetic coordinates .
%   LLA = UTM2LLA(E,N,UTMZONE,H) converts 4 1-by-N arrays of UTM coordinates to a 3-by-N
%   array of geodetic coordinates (latitude, longitude and altitude), LLA.
%   LLA is in [degrees degrees meters].  E is in meters, N is in meters, H is in meters,
%   UTMZONE is a 3char string.
%   Straight implementation of http:%%www.lantmateriet.se/upload/filer/kartor/
%   geodesi_gps_och_detaljmatning/geodesi/Formelsamling/Gauss_Conformal_Projection.pdf
%
%   Examples:
%
%      lla = utm2lla( 6.927085783032901e+05, 5.732679017252645e+06,'30U',0)
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
%ahat = (a/(1+n))*(1+(n^2)/4+(n^4)/64);

k0 = 0.9996;
a1 = 6367449.14582;
maxpow = 6;

tol_ = 1.49011611938e-09;

nx = n_*n_;
b1 = 1/(1+n_)*(nx*(nx*(nx+4)+64)+256)/256;
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
        error('utm2lla: utmzone should be a vector of strings like "30T"\n');
    end
    
    %    if (utmzone(3,i)>'M')
    %       hemis='N';   % Northern hemisphere
    %    else
    %       hemis='S';
    %    end
    
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
    ar = ar/2;
    ai = ai/2;           % cos(2*zeta')
    yr1 = 1 - yr1 + ar * yr0 - ai * yi0;
    yi1 =   - yi1 + ai * yr0 + ar * yi0;
    ar = s0 * ch0;
    ai = c0 * sh0; % sin(2*zeta)
    xip  = xi  + ar * xip0 - ai * etap0;
    etap = eta + ai * xip0 + ar * etap0;
    % Convergence and scale for Gauss-Schreiber TM to Gauss-Krueger TM.
    gamma = atan2(yi1, yr1);
    k = b1 / hypot(yr1, yi1);
    % JHS 154 has
    %
    %   phi' = asin(sin(xi') / cosh(eta')) (Krueger p 17 (25))
    %   lam = asin(tanh(eta') / cos(phi')
    %   psi = asinh(tan(phi'))
    s = sinh(etap);
    c = max(real(0), cos(xip)); % cos(pi/2) might be negative
    r = hypot(s, c);
    if (r ~= 0)
        lam = atan2(s, c);        % Krueger p 17 (25)
        % Use Newton's method to solve for tau
        
        taup = sin(xip)/r;
        % To lowest order in e^2, taup = (1 - e^2) * tau = _e2m * tau; so use
        % tau = taup/_e2m as a starting guess.  Only 1 iteration is needed for
        % |lat| < 3.35 deg, otherwise 2 iterations are needed.  If, instead,
        % tau = taup is used the mean number of iterations increases to 1.99
        % (2 iterations are needed except near tau = 0).
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
        gamma = gamma + atan(tan(xip) * tanh(etap)); %% Krueger p 19 (31)
        %Note cos(phi') * cosh(eta') = r
        k = k*sqrt(e2m + e2 * cos(phi)^2) *hypot(1, tau) * r;
    else
        phi = pi/2;
        lam = 0;
        k = k*c;
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
    gamma = gamma / (pi/180);
    if (backside)
        gamma = 180 - gamma;
    end
    gamma = gamma * xisign * etasign;
    k = k*k0;
    
    lla(:,i)=[lat;lon;h(i)];
    
    %    xi = (x-FN)/(k0*ahat);
    %    eta = (y-FE)/(k0*ahat);
    %
    %    delta1 = (1/2)*n-(2/3)*n^2+(37/96)*n^3-(1/360)*n^4-(81/512)*n^5+(96199/604800)*n^6;
    %    delta2 = (1/48)*n^2+(1/15)*n^3-(437/1440)*n^4+(46/105)*n^5-(1118711/3870720)*n^6;
    %    delta3 = (17/480)*n^3-(37/840)*n^4-(209/4480)*n^5+(5569/90720)*n^6;
    %    delta4 = (4397/161280)*n^4-(11/504)*n^5-(830251/7257600)*n^6;
    %    delta5 = (4583/161280)*n^5-(108847/3991680)*n^6;
    %    delta6 = (20648693/638668800)*n^6;
    %
    %    xiprime  =  xi - delta1*sin(2*xi)*cosh(2*eta)- ...
    %                     delta2*sin(4*xi)*cosh(4*eta)- ...
    %                     delta3*sin(6*xi)*cosh(6*eta)- ...
    %                     delta4*sin(8*xi)*cosh(8*eta)- ...
    %                     delta5*sin(10*xi)*cosh(10*eta)- ...
    %                     delta6*sin(12*xi)*cosh(12*eta);
    %
    %    etaprime = eta - delta1*cos(2*xi)*sinh(2*eta)- ...
    %                     delta2*cos(4*xi)*sinh(4*eta)- ...
    %                     delta3*cos(6*xi)*sinh(6*eta)- ...
    %                     delta4*cos(8*xi)*sinh(8*eta)- ...
    %                     delta5*cos(10*xi)*sinh(10*eta)- ...
    %                     delta6*cos(12*xi)*sinh(12*eta);
    %
    %    phistar = asin(sin(xiprime)/cosh(etaprime));
    %
    %    deltaLambda = atan(sinh(etaprime)/cos(xiprime));
    %
    %
    %    Astar = e2+e2^2+e2^3+e2^4;
    %    Bstar = (-1/6)*(7*e2^2+17*e2^3+30*e2^4);
    %    Cstar = (1/120)*(224*e2^3+889*e2^4);
    %    Dstar = (-1/126)*(4279*e2^4);
    %
    %    phi = phistar + sin(phistar)*cos(phistar)*(Astar+Bstar*sin(phistar)^2+Cstar*sin(phistar)^4+Dstar*sin(phistar)^6);
    %
    %    lat = phi*(180/pi);
    %    lon = deltaLambda*(180/pi) + lambda0;
    %
    %    lla(:,i)=[lat;lon;h(i)];
    
    %    sa = 6378137.000000 ; sb = 6356752.314245;
    %
    %    e2 = ( ( ( sa ^ 2 ) - ( sb ^ 2 ) ) ^ 0.5 ) / sb;
    %    e2squared = e2 ^ 2;
    %    c = ( sa ^ 2 ) / sb;
    %
    %    X = x - 500000;
    %
    %    if hemis == 'S' || hemis == 's'
    %        Y = y - 10000000;
    %    else
    %        Y = y;
    %    end
    %
    %
    %    S = ( ( zone * 6 ) - 183 );
    %    lat =  Y / ( 6366197.724 * 0.9996 );
    %    v = ( c / ( ( 1 + ( e2squared * ( cos(lat) ) ^ 2 ) ) ) ^ 0.5 ) * 0.9996;
    %    a = X / v;
    %    a1 = sin( 2 * lat );
    %    a2 = a1 * ( cos(lat) ) ^ 2;
    %    j2 = lat + ( a1 / 2 );
    %    j4 = ( ( 3 * j2 ) + a2 ) / 4;
    %    j6 = ( ( 5 * j4 ) + ( a2 * ( cos(lat) ) ^ 2) ) / 3;
    %    alpha = ( 3 / 4 ) * e2squared;
    %    beta = ( 5 / 3 ) * alpha ^ 2;
    %    gamma = ( 35 / 27 ) * alpha ^ 3;
    %    Bm = 0.9996 * c * ( lat - alpha * j2 + beta * j4 - gamma * j6 );
    %    b = ( Y - Bm ) / v;
    %    Epsi = ( ( e2squared * a^ 2 ) / 2 ) * ( cos(lat) )^ 2;
    %    Eps = a * ( 1 - ( Epsi / 3 ) );
    %
    %    nab = ( b * ( 1 - Epsi ) ) + lat;
    %    sinheps = ( exp(Eps) - exp(-Eps) ) / 2;
    %    Delt = atan(sinheps / (cos(nab) ) );
    %    TaO = atan(cos(Delt) * tan(nab));
    %    longitude = (Delt *(180 / pi ) ) + S;
    %    latitude = ( lat + ( 1 + e2squared* (cos(lat)^ 2) - ( 3 / 2 ) * e2squared *...
    %        sin(lat) * cos(lat) * ( TaO - lat ) ) * ( TaO - lat ) ) * (180 / pi);
    %
    %   lla(:,i)=[latitude;longitude;h(i)];
    
end