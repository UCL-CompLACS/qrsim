#include <math.h>
#include "mex.h"

#define c    6.399593625758674e+6
#define e2   0.082094437950043
#define e22  0.006739496742333

#define f    (3.35281066474748e-3)
#define a    6378137
#define A    (6.69437999014132e-3)
#define B    (37.2956017456798e-006)
#define C    (259.252748095067e-009)
#define D    (1.97169890868957e-009)
#define n    (1.67922038638370e-3)
#define beta1   (837.731820630353e-006)
#define beta2   (760.852771424900e-009)
#define beta3 (1.20933757363281e-009)
#define beta4 (2.44337619452206e-012)
#define ahat (6.36744914582342e+6)
#define k0   0.9996
#define FE   500000 

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
    if (nrhs != 1) {
        mexErrMsgTxt("One input argument required.");
    }
    
    if (nlhs != 4) {
        mexErrMsgTxt("Four output argument required.");
    }
    
    int rows = mxGetM(prhs[0]);
    int cols = mxGetN(prhs[0]);
    
    if (rows != 3) {
        mexErrMsgTxt("Input has wrong dimensions.");
    }
    
    /* get pointers */
    double* lla = mxGetPr(prhs[0]);
    
    /* Create a matrix for the return argument */
    plhs[0] = mxCreateDoubleMatrix(1,cols, mxREAL);
    plhs[1] = mxCreateDoubleMatrix(1,cols, mxREAL);
    int dims[2]={rows, 1};
    plhs[2] = mxCreateCharArray(2, dims);
    plhs[3] = mxCreateDoubleMatrix(1,cols, mxREAL);
    double* E = mxGetPr(plhs[0]);
    double* N = mxGetPr(plhs[1]);
    mxChar* utmzone = mxGetChars(plhs[2]);
    double* h = mxGetPr(plhs[3]);
    
    int i;
    
    for(i=0; i<cols; i++){
        
        const long double la=lla[i*3];
        const long double lo=lla[1+i*3];
        
        char letter = getLetter(la);

        if ((la < -90)||(la > 90)) {
            mexErrMsgTxt("Invalid WGS84 latitude. \n");
        }
        
        if ((lo < -180)||(lo > 180)) {
            mexErrMsgTxt("Invalid WGS84 longitude.\n");
        }
        
        const long double FN = (la>0) ? 0 : 10000000;
        
        const long double lat = la * ( M_PI / 180 );
        const long double lon = lo * ( M_PI / 180 );
   
        const long double sl = sin(lat);
        const long double sl2 = sl*sl;
        const long double sl4 = sl2*sl2;
        const long double sl6 = sl2*sl4;

        const long double phistar = lat - sl*cos(lat)*(A+B*sl2+C*sl4+D*C*sl6);
        /*mexPrintf("phistar: %6.10f \n",phistar);*/
              
        int zone = (int)( ( lo / 6 ) + 31);
        const long double lambda0 = ( ( zone * 6 ) - 183 );
        const long double deltaLambda = lon - ( lambda0 * ( M_PI / 180 ) );
        
        /* mexPrintf("deltaLambda: %6.10f \n",deltaLambda);  */
        
        const long double xiprime = atan(tan(phistar)/cos(deltaLambda));
        const long double etaprime = atanh(cos(phistar)*sin(deltaLambda));
        
        /*mexPrintf("xiprime: %6.10f etaprime: %6.10f \n",xiprime,etaprime);*/
        
        const long double x = k0*ahat*(xiprime+beta1*sin(2*xiprime)*cosh(2*etaprime)+
                            beta2*sin(4*xiprime)*cosh(4*etaprime)+
                            beta3*sin(6*xiprime)*cosh(6*etaprime)+
                            beta4*sin(8*xiprime)*cosh(8*etaprime)) + FN;
            
        const long double y = k0*ahat*(etaprime+beta1*cos(2*xiprime)*sinh(2*etaprime)+
                            beta2*cos(4*xiprime)*sinh(4*etaprime)+
                            beta3*cos(6*xiprime)*sinh(6*etaprime)+
                            beta4*cos(8*xiprime)*sinh(8*etaprime)) + FE;    
        
/*      int zone = (int)((lo/6) + 31);
        double S = ( ( zone * 6 ) - 183 );
        double deltaS = lon -  ( S * ( M_PI / 180 ) );
        
        char letter = getLetter(la);
        
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
        double beta = ( 5.0 / 3.0 ) * alpha * alpha;
        double gamma = ( 35.0 / 27.0 ) * alpha * alpha* alpha;
        double Bm = 0.9996 * c * ( lat - alpha * j2 + beta * j4 - gamma * j6 );
        double xx = epsilon * v * ( 1 + ( ta / 3.0 ) ) + 500000;
        double yy = nu * v * ( 1 + ta ) + Bm;
        
        if (yy<0){
            yy=9999999+yy;
        }
        
        E[i]=xx;
        N[i]=yy;
 */
        E[i]=y;
        N[i]=x;
                
        utmzone[i*3]= (char)((zone/10) +'0');
        utmzone[1+i*3]= (char)((zone%10) +'0');
        utmzone[2+i*3]= (char)(letter);
        h[i]=lla[2+i*3];
    }

}