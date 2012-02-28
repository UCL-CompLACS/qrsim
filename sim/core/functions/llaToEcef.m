function ecef = llaToEcef(lla)
% LLATOECEF Converts geodetic coordinates to Earth-centered Earth-fixed (ECEF) coordinates.
%
% P = LLATOECEF( LLA ) converts an 3-by-N array of geodetic coordinates (latitude, 
% longitude and altitude), LLA, to an 3-by-N array of ECEF coordinates, P.  
% LLA is in [degrees; degrees; meters].  P is in meters. The ellipsoid planet is WGS84. 
%
% Examples:
%
%   ecef = llaToEcef( [51.71190;-0.21052;0] )
%

if (size(lla, 1) ~= 3)
    error('Position input dimension is not 3xN.');
end

% flattening
f  = 1/298.257223563;

% equatorial radius
R =  6378137;

phi = degsToRads(lla(1,:));
lambda = degsToRads(lla(2,:));
h = lla(3,:);

a  = R;
e2 = ( 1 - ( 1 - f )^2 );
sinphi = sin(phi);
cosphi = cos(phi);
N  = a ./ sqrt(1 - e2 * sinphi.^2);
x = (N + h) .* cosphi .* cos(lambda);
y = (N + h) .* cosphi .* sin(lambda);
z = (N*(1 - e2) + h) .* sinphi;

ecef = [x;y;z];