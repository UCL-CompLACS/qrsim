function  [E,N,utmzone,h] = llaToUtm(lla)
% LLATOUTM Converts geodetic coordinates to UTM coordinates.
%
% [E,N,UTMZONE,H] = LLATOUTM( LLA ) converts an 3-by-N array of geodetic coordinates
% (latitude, longitude and altitude), LLA, to 4 1-by-N arrays of UTM coordinates.
% LLA is in [degrees degrees meters].  E is in meters, N is in meters, H is in meters,
% UTMZONE is a 3char string.
% Straight implementation of http://www.lantmateriet.se/upload/filer/kartor/
% geodesi_gps_och_detaljmatning/geodesi/Formelsamling/Gauss_Conformal_Projection.pdf
%
% Examples:
%
%      [E,N,utmzone,h] = llaToUtm([51.71190;-0.21052;0])
%

% Argument checking
%
error(nargchk(1, 1, nargin));  %2 arguments required
[n1,n2]=size(lla);
if ((n1~=2)&&(n1~=3))
    error('A 2xN or 3xN input is expected');
end


% Memory pre-allocation
%
E=zeros(1,n2);
N=zeros(1,n2);
utmzone(:,n2)='60X';


% useful WGS84 constants
f = 1/298.257223563;
%a = 6378137;

e2 = f*(2-f);
e = sqrt(abs(e2));
%e2m = (1 - e2);

n_ = f/(2-f);

FE = 500000;
%ahat = (a/(1+n))*(1+(n^2)/4+(n^4)/64);

k0 = 0.9996;
a1 = 6367449.14582;
maxpow = 6;


nx = n_*n_;
%b1 = 1/(1+n_)*(nx*(nx*(nx+4)+64)+256)/256;
alp(1) = n_*(n_*(n_*(n_*(n_*(31564*n_-66675)+34440)+47250)-100800)+75600)/151200;
alp(2) = nx*(n_*(n_*((863232-1983433*n_)*n_+748608)-1161216)+524160)/1935360;
nx = nx*n_;
alp(3) = nx*(n_*(n_*(670412*n_+406647)-533952)+184464)/725760;
nx = nx*n_;
alp(4) = nx*(n_*(6601661*n_-7732800)+2230245)/7257600;
nx = nx*n_;
alp(5) = (3438171-13675556*n_)*nx/7983360;
nx = nx*n_;
alp(6) = 212378941*nx/319334400;

% Main Loop
%
for i=1:n2
    lat=lla(1,i);
    lon=lla(2,i);
    
    if((abs(lat)>90)||(abs(lon)>180))
        error('llaToUtm: invalid WGS84 coordinates');
    end
    
    zone = fix( ( lon / 6 ) + 31);
    lon0 = ( ( zone * 6 ) - 183 );
    
    % Avoid losing a bit of accuracy in lon (assuming lon0 is an integer)
    if (lon - lon0 > 180)
        lon = lon - (lon0 + 360);
    else if ((lon - lon0) <= -180)
            lon = lon -(lon0 - 360);
        else
            lon = lon - lon0;
        end
    end
    % Now lon in (-180, 180]
    % Explicitly enforce the parity
    if(lat < 0), latsign = -1; else latsign = 1; end
    if(lon < 0), lonsign = -1; else lonsign = 1; end
    
    lon = lon*lonsign;
    lat = lat*latsign;
    
    backside = (lon > 90);
    if (backside)
        if (lat == 0)
            latsign = -1;
        end
        lon = 180 - lon;
    end
    
    phi = lat * pi/180;
    lam = lon * pi/180;
    
    if (lat ~= 90)
        c = max([0,cos(lam)]); % cos(pi/2) might be negative
        tau = tan(phi);
        secphi = hypot(1, tau);
        sig = sinh(e*atanh(e*tau / secphi));
        taup = hypot(1, sig) * tau - sig * secphi;
        xip = atan2(taup, c);
        etap =asinh(sin(lam) / hypot(taup, c));
        %gamma = atan(tan(lam) * taup / hypot(1, taup)); % Krueger p 22 (44)
        %k = sqrt(e2m + e2 * cos(phi)^2) * secphi / hypot(taup, c);
    else
        xip = pi/2;
        etap = 0;
        %gamma = lam;
        %k = sqrt( (1 + e)^(1 + e) * (1 - e)^(1 - e));
    end
    c0 = cos(2 * xip); ch0 = cosh(2 * etap);
    s0 = sin(2 * xip); sh0 = sinh(2 * etap);
    ar = 2 * c0 * ch0; ai = -2 * s0 * sh0; % 2 * cos(2*zeta')
    n = maxpow;
    if(bitand(n,1))
        xi0 = alp(n);
    else
        xi0 = 0;
    end
    eta0 = 0;
    xi1 = 0;
    eta1 = 0;
    % Accumulators for dzeta/dzeta'

    if(bitand(n,1))
        yr0 =2 * maxpow * alp(n);
        n = n-1;
    else
        yr0 = 0;
    end
    yi0 = 0;
    yr1 = 0;
    yi1 = 0;
    while (n>0)
        %fprintf('a) n=%d\n',n);
        xi1  = ar * xi0 - ai * eta0 - xi1 + alp(n);
        eta1 = ai * xi0 + ar * eta0 - eta1;
        yr1 = ar * yr0 - ai * yi0 - yr1 + 2 * n * alp(n);
        yi1 = ai * yr0 + ar * yi0 - yi1;
        n = n-1;
        % fprintf('b) n=%d\n',n);
        xi0  = ar * xi1 - ai * eta1 - xi0 + alp(n);
        eta0 = ai * xi1 + ar * eta1 - eta0;
        yr0 = ar * yr1 - ai * yi1 - yr0 + 2 * n * alp(n);
        yi0 = ai * yr1 + ar * yi1 - yi0;
        n=n-1;
        % fprintf('c) n=%d\n',n);
    end
    %ar = ar/2;
    %ai = ai/2;           % cos(2*zeta')
    %yr1 = 1 - yr1 + ar * yr0 - ai * yi0;
    %yi1 =   - yi1 + ai * yr0 + ar * yi0;
    ar = s0 * ch0;
    ai = c0 * sh0; % sin(2*zeta')
    
    xi  = xip  + ar * xi0 - ai * eta0;
    eta = etap + ai * xi0 + ar * eta0;
    % Fold in change in convergence and scale for Gauss-Schreiber TM to
    % Gauss-Krueger TM.
    %gamma = gamma - atan2(yi1, yr1);
    %k = k*b1 * hypot(yr1, yi1);
    %gamma = gamma/(pi/180);
    
    if(backside)
        y = a1 * k0 * (pi - xi) * latsign;
    else
        y = a1 * k0 * xi * latsign;
    end
    x = a1 * k0 * eta * lonsign;
    %if (backside)
    %    gamma = 180 - gamma;
    %end
    %gamma = gamma*latsign * lonsign;
    %k = k*k0;
    
    if(y>0)
        FN = 0;
    else
        FN = 10000000;
    end
    
    x= x+ FE;
    y= y+ FN;
    
    lat = lat*latsign;
    if (lat<-72), letter='C';
    elseif (lat<-64), letter='D';
    elseif (lat<-56), letter='E';
    elseif (lat<-48), letter='F';
    elseif (lat<-40), letter='G';
    elseif (lat<-32), letter='H';
    elseif (lat<-24), letter='J';
    elseif (lat<-16), letter='K';
    elseif (lat<-8), letter='L';
    elseif (lat<0), letter='M';
    elseif (lat<8), letter='N';
    elseif (lat<16), letter='P';
    elseif (lat<24), letter='Q';
    elseif (lat<32), letter='R';
    elseif (lat<40), letter='S';
    elseif (lat<48), letter='T';
    elseif (lat<56), letter='U';
    elseif (lat<64), letter='V';
    elseif (lat<72), letter='W';
    else letter='X';
    end
    
    E(i)=x;
    N(i)=y;
    utmzone(:,i)=sprintf('%02d%c',zone,letter);
end

h=lla(3,:);

end