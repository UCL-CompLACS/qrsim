function [ ecef ] = nedToEcef( ned, utmorigin )
% NEDTOECEF local cartesian NED coordinates to Earth-centered Earth-fixed (ECEF) coordinates. 
%
% P = NEDTOECEF( NED,UTMORIGIN ) converts the 3-by-N array of cartesian coordinates (north,
% east, down) about the origin UTMORIGIN, to a 3-by-N array of ECEF coordinates P. 
% To do so we pass through geodetic coordinates. The ellipsoid planet is WGS84. 
% NED is in meters.  P is in meters. UTMORIGIN is a structure: UTMORIGIN.N = northing in
% meters, UTMORIGIN.E = easting in meters, UTMORIGIN.h = height above ellipsoid in meters,
% UTMORIGIN.zone = utm zone 3 char string.
%
% Examples:
%
%   ecef = nedToEcef( [ 5;10;0 ],utmorigin )
%          utmorigin.N = 6.927085783032901e+05;
%          utmorigin.E = 5.732679017252645e+06;
%          utmorigin.zone = '30U';
%          utmorigin.h = 0;
%
    lla = utmToLla(utmorigin.E+ned(2),utmorigin.N+ned(1),utmorigin.zone,utmorigin.h-ned(3));
    ecef = llaToEcef(lla);
end

