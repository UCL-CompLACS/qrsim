#include <math.h>
#include "mex.h"


#define aa   6378137               /*Semimajor axis*/
#define f   0.003352810664747     /*Flattening*/
#define e21  0.006694379990141     /*Square of first eccentricity*/
#define ep2 0.006739496742276     /*Square of second eccentricity*/
#define b   6356752.314245179     /*Semiminor axis*/
#define rad2deg  57.295779513082323


#define c 6.399593625758674e+06
#define e2 0.082094437950043
#define e22 0.006739496742333


char getLetter(double la){
    
    if (la<-72) return 'C';
    if (la<-64) return 'D';
    if (la<-56) return 'E';
    if (la<-48) return 'F';
    if (la<-40) return 'G';
    if (la<-32) return 'H';
    if (la<-24) return 'J';
    if (la<-16) return 'K';
    if (la<-8) return 'L';
    if (la<0) return 'M';
    if (la<8) return 'N';
    if (la<16) return 'P';
    if (la<24) return 'Q';
    if (la<32) return 'R';
    if (la<40) return 'S';
    if (la<48) return 'T';
    if (la<56) return 'U';
    if (la<64) return 'V';
    if (la<72) return 'W';
    return 'X';
}

void mexFunction( int nlhs, mxArray *plhs[],
        int nrhs, const mxArray *prhs[] ) {
    
    /* Check for proper number and size of arguments */
    if (nrhs != 2) {
        mexErrMsgTxt("Two input arguments required.");
    }
    
    if (nlhs > 1) {
        mexErrMsgTxt("Too many output arguments.");
    }
    
    int rows = mxGetM(prhs[0]);
    int cols = mxGetN(prhs[0]);

    if (rows != 3) {
        mexErrMsgTxt("Input has wrong dimensions.");
    }
   
    /* get pointers */
    double* ecef = mxGetPr(prhs[0]);
    
    
    int E_field_num = mxGetFieldNumber(prhs[1], "E");
    double* utmoriginE = mxGetPr(mxGetFieldByNumber(prhs[1], 0, E_field_num));
    int N_field_num = mxGetFieldNumber(prhs[1], "N");
    double* utmoriginN = mxGetPr(mxGetFieldByNumber(prhs[1], 0, N_field_num));
    int h_field_num = mxGetFieldNumber(prhs[1], "h");
    double* utmoriginH = mxGetPr(mxGetFieldByNumber(prhs[1], 0, h_field_num));
    int zone_field_num = mxGetFieldNumber(prhs[1], "zone");
    mxChar* utmoriginZONE = mxGetChars(mxGetFieldByNumber(prhs[1], 0, zone_field_num));
    
    
    /* Create a matrix for the return argument */
    plhs[0] = mxCreateDoubleMatrix(3,cols, mxREAL);
    double* NED = mxGetPr(plhs[0]);
    
    
    int i;
    
    for(i=0; i<cols; i++){
        double x = ecef[i*3];
        double y = ecef[i*3+1];
        double z = ecef[i*3+2];

        /* Longitude*/
        double lambda = atan2(y, x);
        
        /* Distance from Z-axis*/
        double rho = sqrt(x*x+y*y);
        
        /* Bowring's formula for initial parametric (beta) and geodetic (phi) latitudes*/
        double beta = atan2(z, (1 - f) * rho);
        double sbeta = sin(beta); double cbeta = cos(beta);
        
        double phi = atan2(z+b*ep2*sbeta*sbeta*sbeta, rho-aa*e21*cbeta*cbeta*cbeta);
        double sphi = sin(phi); double cphi = cos(phi);
        
        /* Fixed-point iteration with Bowring's formula*/
        /* (typically converges within two or three iterations)*/
        double betaNew = atan2((1 - f)*sin(phi), cos(phi));
        int count = 0;
        while ((beta!=betaNew) && count < 5){
            beta = betaNew;
            sbeta = sin(beta); cbeta = cos(beta);
            phi = atan2(z+b*ep2*sbeta*sbeta*sbeta, rho-aa*e21*cbeta*cbeta*cbeta);
            sphi = sin(phi); cphi = cos(phi);
            betaNew = atan2((1 - f)*sphi, cphi);
            count++;
        }
        
        /* Calculate ellipsoidal height from the final value for latitude*/
        double N = aa / sqrt(1 - e21 * sphi* sphi);
        double h = rho * cphi + (z + e21 * N* sphi) * sphi - N;
        
        double lat = phi;
        double lon = lambda;   
        
        double lo = lon * (180/ M_PI);
        
        int zone = (int)((lo/6) + 31);
        double S = ( ( zone * 6 ) - 183 );
        double deltaS = lon -  ( S * ( M_PI / 180 ) );
        
        char letter = getLetter(lat*(180/ M_PI));
        
        double clat = cos(lat);
        double clat2 = clat*clat;
        double a = clat * sin(deltaS);
        double epsilon = 0.5 * log( ( 1 +  a) / ( 1 - a ) );
        double nu = atan( tan(lat) / cos(deltaS) ) - lat;
        
        double v = (c / sqrt(( 1 + ( e22 * clat2 ) ))) * 0.9996;
        double ta = ( e22 / 2.0 ) * epsilon * epsilon * clat2;
        double a1 = sin( 2 * lat );
        double a2 = a1 * clat2;
        double j2 = lat + ( a1 / 2.0 );
        double j4 = ( ( 3 * j2 ) + a2 ) / 4.0;
        double j6 = ( ( 5 * j4 ) + ( a2 * clat2) ) / 3.0;
        double alpha = ( 3.0 / 4.0 ) * e22;
        double betaa = ( 5.0 / 3.0 ) * alpha * alpha;
        double gamma = ( 35.0 / 27.0 ) * alpha * alpha* alpha;
        double Bm = 0.9996 * c * ( lat - alpha * j2 + betaa * j4 - gamma * j6 );
        double xx = epsilon * v * ( 1 + ( ta / 3.0 ) ) + 500000;
        double yy = nu * v * ( 1 + ta ) + Bm;
        
        if (yy<0){
            yy=9999999+yy;
        }
        
        NED[3*i] = yy - utmoriginN[0];
        NED[1+3*i] = xx- utmoriginE[0];
        NED[2+3*i] = utmoriginH[0]-h;
      
        //char utmzone[] = {(char)((zone/10) +'0'),(char)((zone%10) +'0'),(char)(letter)};
        //
        //if((utmzone[0]!=utmoriginZONE[0])||(utmzone[1]!=utmoriginZONE[1])||(utmzone[2]!=utmoriginZONE[2])){
        //    mexPrintf("zone %c%c%c    origin_zone%c%c%c\n",utmzone[0],utmzone[1],utmzone[2],utmoriginZONE[0],utmoriginZONE[1],utmoriginZONE[2]);
        //    mexErrMsgTxt("something went horribly wrong with the coord converion the timezones do not match.");
        //}
       
    }
    
}