function  lla = utm2lla(E,N,utmzone,h)
%  UTM2LLA Converts UTM coordinates to geodetic coordinates .
%   LLA = UTM2LLA(E,N,UTMZONE,H) converts 4 1-by-N arrays of UTM coordinates to a 3-by-N 
%   array of geodetic coordinates (latitude, longitude and altitude), LLA.  
%   LLA is in [degrees degrees meters].  E is in meters, N is in meters, H is in meters,
%   UTMZONE is a 3char string. 
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


% Memory pre-allocation
%
lla=zeros(3,n1);


% Main Loop
%
for i=1:n1
   if (utmzone(3,i)>'X' || utmzone(3,i)<'C')
      error('utm2lla: utmzone should be a vector of strings like "30T"\n');
   end
   if (utmzone(3,i)>'M')
      hemis='N';   % Northern hemisphere
   else
      hemis='S';
   end

   x=E(i);
   y=N(i);
   zone=str2double(utmzone(1:2,i));

   sa = 6378137.000000 ; sb = 6356752.314245;

   e2 = ( ( ( sa ^ 2 ) - ( sb ^ 2 ) ) ^ 0.5 ) / sb;
   e2squared = e2 ^ 2;
   c = ( sa ^ 2 ) / sb;

   X = x - 500000;
   
   if hemis == 'S' || hemis == 's'
       Y = y - 10000000;
   else
       Y = y;
   end
  
   
   S = ( ( zone * 6 ) - 183 );
   lat =  Y / ( 6366197.724 * 0.9996 );
   v = ( c / ( ( 1 + ( e2squared * ( cos(lat) ) ^ 2 ) ) ) ^ 0.5 ) * 0.9996;
   a = X / v;
   a1 = sin( 2 * lat );
   a2 = a1 * ( cos(lat) ) ^ 2;
   j2 = lat + ( a1 / 2 );
   j4 = ( ( 3 * j2 ) + a2 ) / 4;
   j6 = ( ( 5 * j4 ) + ( a2 * ( cos(lat) ) ^ 2) ) / 3;
   alpha = ( 3 / 4 ) * e2squared;
   beta = ( 5 / 3 ) * alpha ^ 2;
   gamma = ( 35 / 27 ) * alpha ^ 3;
   Bm = 0.9996 * c * ( lat - alpha * j2 + beta * j4 - gamma * j6 );
   b = ( Y - Bm ) / v;
   Epsi = ( ( e2squared * a^ 2 ) / 2 ) * ( cos(lat) )^ 2;
   Eps = a * ( 1 - ( Epsi / 3 ) );
   
   nab = ( b * ( 1 - Epsi ) ) + lat;
   sinheps = ( exp(Eps) - exp(-Eps) ) / 2;
   Delt = atan(sinheps / (cos(nab) ) );
   TaO = atan(cos(Delt) * tan(nab));
   longitude = (Delt *(180 / pi ) ) + S;
   latitude = ( lat + ( 1 + e2squared* (cos(lat)^ 2) - ( 3 / 2 ) * e2squared *...
       sin(lat) * cos(lat) * ( TaO - lat ) ) * ( TaO - lat ) ) * (180 / pi);
   
   lla(:,i)=[latitude;longitude;h(i)];
   
end