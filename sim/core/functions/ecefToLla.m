function lla = ecefToLla(p)
%  ECEFTOLLA Converts Earth-centered Earth-fixed (ECEF) coordinates to geodetic WGS84 coordinates. 
%
%  LLA = ECEFTOLLA( P ) converts the 3-by-N array of ECEF coordinates, P, to an 3-by-N array
%  of geodetic coordinates (latitude, longitude and altitude), LLA.
%  LLA is in [degrees; degrees; meters].  P is in meters.  The ellipsoid planet is WGS84. 
%
%  Examples:
%
%   lla = ecefToLla( [ 4510731;4510731;0 ] )
%

if (size( p, 1) ~= 3)
    error('Position input dimension is not 3xN.');
end

% flattening
f  = 1/298.257223563;

% equatorial radius
R =  6378137;

x = p(1,:);
y = p(2,:);
z = p(3,:);


% Ellipsoid constants
a  = R;                     % Semimajor axis
e2 = ( 1 - ( 1 - f )^2 );   % Square of first eccentricity
ep2 = e2 / (1 - e2);        % Square of second eccentricity
f = 1 - sqrt(1 - e2);       % Flattening
b = a * (1 - f);            % Semiminor axis

% Longitude
lambda = atan2(y,x);

% Distance from Z-axis
rho = hypot(x,y);

% Bowring's formula for initial parametric (beta) and geodetic (phi) latitudes
beta = atan2(z, (1 - f) * rho);
phi = atan2(z   + b * ep2 * sin(beta).^3,...
            rho - a * e2  * cos(beta).^3);

% Fixed-point iteration with Bowring's formula
% (typically converges within two or three iterations)
betaNew = atan2((1 - f)*sin(phi), cos(phi));
count = 0;
while any(beta(:) ~= betaNew(:)) && count < 5
    beta = betaNew;
    phi = atan2(z   + b * ep2 * sin(beta).^3,...
                rho - a * e2  * cos(beta).^3);
    betaNew = atan2((1 - f)*sin(phi), cos(phi));
    count = count + 1;
end

% Calculate ellipsoidal height from the final value for latitude
sinphi = sin(phi);
N = a ./ sqrt(1 - e2 * sinphi.^2);
h = rho .* cos(phi) + (z + e2 * N .* sinphi) .* sinphi - N;

lla = [radsToDegs(phi) radsToDegs(lambda) h]';
