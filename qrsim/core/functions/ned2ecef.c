#include <math.h>
#include "mex.h"

#define c 6.399593625758674e+06
#define e2 0.082094437950043
#define e22 0.006739496742333

#define aa   6378137               /*Semimajor axis*/
#define e21  0.006694379990141     /*Square of first eccentricity*/
#define deg2rad  0.017453292519943


void mexFunction( int nlhs, mxArray *plhs[],
        int nrhs, const mxArray *prhs[] ) {
    
    /* Check for proper number and size of arguments */
    if (nrhs != 2) {
        mexErrMsgTxt("Two inputs arguments required.");
    }
    
    if (nlhs != 1) {
        mexErrMsgTxt("One output argument required.");
    }
    
    int cols = mxGetN(prhs[0]);
    int rows = mxGetM(prhs[0]);
    
    if (rows != 3) {
        mexErrMsgTxt("Input has wrong dimensions.");
    }
    
    /* get pointers */
    double* NED = mxGetPr(prhs[0]);
    
    double* utmoriginE = mxGetPr(mxGetFieldByNumber(prhs[1], 0, 0));
    double* utmoriginN = mxGetPr(mxGetFieldByNumber(prhs[1], 0, 1));
    double* utmoriginH = mxGetPr(mxGetFieldByNumber(prhs[1], 0, 2));
    mxChar* utmzone = mxGetChars(mxGetFieldByNumber(prhs[1], 0, 3));
    
    /* Create a matrix for the return argument */
    plhs[0] = mxCreateDoubleMatrix(3, cols, mxREAL);
    double* ecef = mxGetPr(plhs[0]);
    
    int i;
    for(i=0; i<cols; i++){
        
        double X=utmoriginE[0] + NED[1+3*i]- 500000;
        double Y=utmoriginN[0] + NED[3*i];
        double h = utmoriginH[0]-NED[2+3*i];
        
        if (utmzone[2]>'X' || utmzone[2]<'C'){
            mexPrintf("utm2lla: Warning utmzone should be a vector of strings like 30T, not 30t\n");
        }
        
        if (utmzone[2]<'M'){
            Y-=10000000;   /* Southern hemisphere*/
        }
        
        int zone=(utmzone[0]-'0')*10+(utmzone[1]-'0');
        
        double S = ( ( zone * 6 ) - 183 );
        double lat =  Y / ( 6366197.724 * 0.9996 );
        double clat = cos(lat);
        double clat2 = clat * clat;
        double v = ( c / sqrt( ( 1 + ( e22 * clat2 ) ) ) ) * 0.9996;
        double a = X / v;
        double a1 = sin( 2 * lat );
        double a2 = a1 * clat2;
        double j2 = lat + ( a1 / 2 );
        double j4 = ( ( 3 * j2 ) + a2 ) / 4;
        double j6 = ( ( 5 * j4 ) + ( a2 * clat2) ) / 3;
        double alpha = ( 3 / 4.0 ) * e22;
        double beta = ( 5 / 3.0 ) * alpha * alpha;
        double gamma = ( 35 / 27.0 ) * alpha * alpha* alpha;
        double Bm = 0.9996 * c * ( lat - alpha * j2 + beta * j4 - gamma * j6 );
        double b = ( Y - Bm ) / v;
        double Epsi = ( ( e22 * a*a ) / 2 ) * clat2;
        double Eps = a * ( 1 - ( Epsi / 3 ) );
        double nab = ( b * ( 1 - Epsi ) ) + lat;
        double sineps = ( exp(Eps) - exp(-Eps) ) / 2;
        double Delt = atan(sineps / (cos(nab) ) );
        double TaO = atan(cos(Delt) * tan(nab));
        
        double phi = ( lat + ( 1 + e22* clat2 - ( 3 / 2.0 ) * e22 * sin(lat) * clat * ( TaO - lat ) ) * ( TaO - lat ) );
        double lambda = Delt + deg2rad*S;
        double sinphi = sin(phi);
        double cosphi = cos(phi);
        double n  = aa / sqrt(1 - e21 * sinphi* sinphi);
        
        ecef[i*3]= (n + h) * cosphi * cos(lambda);
        ecef[1+i*3] = (n + h) * cosphi * sin(lambda);
        ecef[2+i*3] = (n*(1 - e21) + h) * sinphi;
    }
    
}