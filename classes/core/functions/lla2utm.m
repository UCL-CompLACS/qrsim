function  [E,N,utmzone,h] = lla2utm(lla)
%  LLA2UTM Converts geodetic coordinates to UTM coordinates.
%   [E,N,UTMZONE,H] = LLA2UTM( LLA ) converts an 3-by-N array of geodetic coordinates
%   (latitude, longitude and altitude), LLA, to 4 1-by-N arrays of UTM coordinates.  
%   LLA is in [degrees degrees meters].  E is in meters, N is in meters, H is in meters,
%   UTMZONE is a 3char string. 
%
%   Examples:
%
%      [E,N,utmzone,h] = lla2utm([51.71190;-0.21052;0])
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

% Main Loop
%
for i=1:n2
   la=lla(1,i);
   lo=lla(2,i);

   sa = 6378137.000000 ; sb = 6356752.314245;
         
   e2 = ( ( ( sa ^ 2 ) - ( sb ^ 2 ) ) ^ 0.5 ) / sb;
   e2squared = e2 ^ 2;
   c = ( sa ^ 2 ) / sb;

   lat = la * ( pi / 180 );
   lon = lo * ( pi / 180 );

   zone = fix( ( lo / 6 ) + 31);
   S = ( ( zone * 6 ) - 183 );
   deltaS = lon - ( S * ( pi / 180 ) );

   if (la<-72), letter='C';
   elseif (la<-64), letter='D';
   elseif (la<-56), letter='E';
   elseif (la<-48), letter='F';
   elseif (la<-40), letter='G';
   elseif (la<-32), letter='H';
   elseif (la<-24), letter='J';
   elseif (la<-16), letter='K';
   elseif (la<-8), letter='L';
   elseif (la<0), letter='M';
   elseif (la<8), letter='N';
   elseif (la<16), letter='P';
   elseif (la<24), letter='Q';
   elseif (la<32), letter='R';
   elseif (la<40), letter='S';
   elseif (la<48), letter='T';
   elseif (la<56), letter='U';
   elseif (la<64), letter='V';
   elseif (la<72), letter='W';
   else letter='X';
   end

   a = cos(lat) * sin(deltaS);
   epsilon = 0.5 * log( ( 1 +  a) / ( 1 - a ) );
   nu = atan( tan(lat) / cos(deltaS) ) - lat;
   v = ( c / ( ( 1 + ( e2squared * ( cos(lat) ) ^ 2 ) ) ) ^ 0.5 ) * 0.9996;
   ta = ( e2squared / 2 ) * epsilon ^ 2 * ( cos(lat) ) ^ 2;
   a1 = sin( 2 * lat );
   a2 = a1 * ( cos(lat) ) ^ 2;
   j2 = lat + ( a1 / 2 );
   j4 = ( ( 3 * j2 ) + a2 ) / 4;
   j6 = ( ( 5 * j4 ) + ( a2 * ( cos(lat) ) ^ 2) ) / 3;
   alpha = ( 3 / 4 ) * e2squared;
   beta = ( 5 / 3 ) * alpha ^ 2;
   gamma = ( 35 / 27 ) * alpha ^ 3;
   Bm = 0.9996 * c * ( lat - alpha * j2 + beta * j4 - gamma * j6 );
   xx = epsilon * v * ( 1 + ( ta / 3 ) ) + 500000;
   yy = nu * v * ( 1 + ta ) + Bm;

   if (yy<0)
       yy=9999999+yy;
   end

   E(i)=xx;
   N(i)=yy;
   utmzone(:,i)=sprintf('%02d%c',zone,letter);
end

h=lla(3,:);

