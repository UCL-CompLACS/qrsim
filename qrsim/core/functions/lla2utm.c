#include <math.h>
#include "mex.h"

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
    
    for(i=0; i<rows; i++){
        
        double la=lla[i*3];
        double lo=lla[1+i*3];
        
        double lat = la * ( M_PI / 180 );
        double lon = lo * ( M_PI / 180 );
        
        int zone = (int)((lo/6) + 31);
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
        utmzone[i*3]= (char)((zone/10) +'0');
        utmzone[1+i*3]= (char)((zone%10) +'0');
        utmzone[2+i*3]= (char)(letter);
        h[i]=lla[2+i*3];
    }

}