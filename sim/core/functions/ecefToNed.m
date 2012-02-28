function ned = ecefToNed( ecef , utmorigin)
%  ECEFTONED Convert Earth-centered Earth-fixed (ECEF) local cartesian NED coordinates. 
%
%  NED = ECEFTONED( P,UTMORIGIN ) converts the 3-by-N array of ECEF coordinates, P, to an 
%  3-by-N array of cartesian coordinates (north, east, down) about the origin UTMORIGIN.
%  To do so we pass through geodetic coordinates. The ellipsoid planet is WGS84. 
%  NED is in meters.  P is in meters. UTMORIGIN is a structure: UTMORIGIN.N = northing in
%  meters, UTMORIGIN.E = easting in meters, UTMORIGIN.h = height above ellipsoid in meters,
%  UTMORIGIN.zone = utm zone 3 char string.
%
%  Examples:
%
%      ned = ecefToNed( [ 4510731;4510731;0 ], utmorigin )
%           utmorigin.N = 6.927085783032901e+05;
%           utmorigin.E = 5.732679017252645e+06;
%           utmorigin.zone = '30U';
%           utmorigin.h = 0;
%
    lla = ecefToLla(ecef);
    [E,N,zone,h] = llaToUtm(lla);
    
%    if (zone~= utmorigin.zone)
%        error('the timezones in the coord conversion do not match %s ~= %s',zone,utmorigin.zone);
%    end
    
    ned = [ N - utmorigin.N; E - utmorigin.E; utmorigin.h - h ];
end

