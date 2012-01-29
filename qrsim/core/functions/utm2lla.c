#include <math.h>
#include "mex.h"

#define c 6.399593625758674e+06
#define e2 0.082094437950043
#define e22 0.006739496742333

#define f    3.35281066474748e-3
#define a    6378137
#define n    1.67922038638370e-3
#define ahat 6.36744914582342e+6
#define k0   0.9996
#define FE   500000
#define delta1 837.732164060057e-006
#define delta2 59.0586956793399e-009
#define delta3 167.348888035485e-012
#define delta4 216.773776302204e-015
#define Astar 6.73949672874110e-003
#define Bstar -53.1439050575023e-006
#define Cstar 574.891266998559e-009
#define Dstar -68.2045240928268e-009

void mexFunction( int nlhs, mxArray *plhs[],
        int nrhs, const mxArray *prhs[] ) {
    
    /* Check for proper number and size of arguments */
    if (nrhs != 4) {
        mexErrMsgTxt("Four input arguments required.");
    }
    
    if (nlhs != 1) {
        mexErrMsgTxt("One output argument required.");
    }
    
    int cols = mxGetN(prhs[0]);
    int rowsE = mxGetM(prhs[0]);
    int rowsN = mxGetM(prhs[1]);
    int rowsZ = mxGetM(prhs[2]);
    int rowsH = mxGetM(prhs[3]);
    
    if ((rowsE != 1)||(rowsN != 1)||(rowsZ != 3)||(rowsH != 1)) {
        mexErrMsgTxt("Input has wrong dimensions.");
    }
    
    /* get pointers */
    double* E = mxGetPr(prhs[0]);
    double* N = mxGetPr(prhs[1]);
    mxChar* utmzone = mxGetChars(prhs[2]);
    double* h = mxGetPr(prhs[3]);
    
    /* Create a matrix for the return argument */
    plhs[0] = mxCreateDoubleMatrix(3, cols, mxREAL);
    double* lla = mxGetPr(plhs[0]);
    
    int i;
    
    for(i=0; i<cols; i++){
        
        if (utmzone[2+3*i]>'X' || utmzone[2+3*i]<'C'){
            mexPrintf("utm2lla: Warning utmzone should be a vector of strings like 30T, not 30t\n");
        }
        
        double FN;
        if (utmzone[2+3*i]>'M'){
            FN = 0;
        } else {
            FN = 10000000;
        }
        
        const long double y=E[i];
        const long double x=N[i];
        const long double zone = (utmzone[3*i]-'0')*10+(utmzone[1+3*i]-'0');
        const long double lambda0 = ( ( zone * 6 ) - 183 );
        
        const long double xi = (x-FN)/(k0*ahat);
        const long double eta = (y-FE)/(k0*ahat);
        
        const long double  xiprime  =  xi - delta1*sin(2*xi)*cosh(2*eta)-
                delta2*sin(4*xi)*cosh(4*eta)-
                delta3*sin(6*xi)*cosh(6*eta)-
                delta4*sin(8*xi)*cosh(8*eta);
        
        const long double etaprime = eta - delta1*cos(2*xi)*sinh(2*eta)-
                delta2*cos(4*xi)*sinh(4*eta)-
                delta3*cos(6*xi)*sinh(6*eta)-
                delta4*cos(8*xi)*sinh(8*eta);
        
        const long double phistar = asin(sin(xiprime)/cosh(etaprime));
        
        const long double deltaLambda = atan(sinh(etaprime)/cos(xiprime));
        
        const long double sps = sin(phistar);
        const long double sps2 = sps*sps;
        const long double sps4 = sps2*sps2;
        const long double sps6 = sps2*sps4;
        
        const long double phi = phistar + sps*cos(phistar)*(Astar+Bstar*sps2+Cstar*sps4+Dstar*sps6);
        
        const long double lat = phi*(180/M_PI);
        const long double lon = deltaLambda*(180/M_PI) + lambda0;
        
        lla[3*i] = lat;
        lla[1+3*i] = lon;
        lla[2+3*i] = h[i];
        
        
        /*        double X=E[i]- 500000;
        double Y=N[i];
 
        if (utmzone[2+3*i]>'X' || utmzone[2+3*i]<'C'){
            mexPrintf("utm2lla: Warning utmzone should be a vector of strings like 30T, not 30t\n");
        }
 
        if (utmzone[2+3*i]<'M'){
            Y-=10000000;
        }
 
        int zone=(utmzone[3*i]-'0')*10+(utmzone[1+3*i]-'0');
 
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
 
        lla[3*i] = ( lat + ( 1 + e22* clat2 - ( 3 / 2.0 ) * e22 * sin(lat) * clat * ( TaO - lat ) ) * ( TaO - lat ) ) * (180 / M_PI);
        lla[1+3*i] = (Delt *(180 / M_PI ) ) + S;
        lla[2+3*i] = h[i];
         */
    }
    
}