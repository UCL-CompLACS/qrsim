#include <math.h>
#include "mex.h"

#define MAXPOW 6
#define f    3.35281066474748e-3
#define a1   6367449.14582
#define e  8.181919084262149e-02
#define e2 6.694379990141316e-03
#define n_ 1.679220386383705e-03
#define k0   0.9996
#define FE   500000
#define FN   10000000
#define alp1 8.377318206244698e-04
#define alp2 7.608527773572309e-07
#define alp3 1.197645503329453e-09
#define alp4 2.429170607201359e-12
#define alp5 5.711757677865804e-15
#define alp6 1.491117731258390e-17

#if !defined(MAX)
#define    MAX(A, B)    ((A) > (B) ? (A) : (B))
#endif

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
    plhs[0] = mxCreateDoubleMatrix(1, cols, mxREAL);
    plhs[1] = mxCreateDoubleMatrix(1, cols, mxREAL);
    int dims[2]={rows, 1};
    plhs[2] = mxCreateCharArray(2, dims);
    plhs[3] = mxCreateDoubleMatrix(1, cols, mxREAL);
    double* E = mxGetPr(plhs[0]);
    double* N = mxGetPr(plhs[1]);
    mxChar* utmzone = mxGetChars(plhs[2]);
    double* h = mxGetPr(plhs[3]);
    
    double alp[7] = {0,alp1,alp2,alp3,alp4,alp5,alp6};
    
    int i;
    
    for(i=0; i<cols; i++){
        
        double lat=lla[i*3];
        double lon=lla[1+i*3];
        
        char letter = getLetter(lat);
        
        if ((lat < -90)||(lat > 90)) {
            mexErrMsgTxt("Invalid WGS84 latitude. \n");
        }
        
        if ((lon < -180)||(lon > 180)) {
            mexErrMsgTxt("Invalid WGS84 longitude.\n");
        }
        
        int zone = (int)((lon/6)+31);
        int lon0 = ((zone*6) - 183);
        
        /*Avoid losing a bit of accuracy in lon (assuming lon0 is an integer)*/
        if (lon - lon0 > 180){
            lon = lon - (lon0 + 360);
        } else {
            if ((lon - lon0) <= -180){
                lon = lon -(lon0 - 360);
            }else{
                lon = lon - lon0;
            }
        }
        /*Now lon in (-180, 180]*/
        /*Explicitly enforce the parity*/
        int latsign = (lat < 0) ? -1 : 1;
        int lonsign = (lon < 0) ? -1 : 1;
        
        lon = lon*lonsign;
        lat = lat*latsign;
        
        int backside = (lon > 90);
        if (backside){
            if (lat == 0){
                latsign = -1;
            }
            lon = 180 - lon;
        }
        
        double phi = lat * M_PI/180;
        double lam = lon * M_PI/180;
        
        double xip;
        double etap;
        
        if (lat != 90){
            const double c = MAX(0, cos(lam)); /*cos(M_PI/2) might be negative*/
            const double tau = tan(phi);
            const double secphi = hypot(1, tau);
            const double sig = sinh(e*atanh(e*tau / secphi));
            const double taup = hypot(1, sig) * tau - sig * secphi;
            xip = atan2(taup, c);
            etap =asinh(sin(lam) / hypot(taup, c));
        }else{
            xip = M_PI/2;
            etap = 0;
        }
        const double c0 = cos(2 * xip);
        const double ch0 = cosh(2 * etap);
        const double s0 = sin(2 * xip);
        const double sh0 = sinh(2 * etap);
        double ar = 2 * c0 * ch0;
        double ai = -2 * s0 * sh0; /*2 * cos(2*zeta')*/
        
        int n = MAXPOW;
        double xi0 = (n & 1 ? alp[n] : 0);
        double eta0 = 0;
        double xi1 = 0;
        double eta1 = 0;
        
        /*Accumulators for dzeta/dzeta'*/
        double yr0 = (n & 1 ? 2 * MAXPOW * alp[n--] : 0);
        double yi0 = 0;
        double yr1 = 0;
        double yi1 = 0;
        
        while (n>0){
            xi1  = ar * xi0 - ai * eta0 - xi1 + alp[n];
            eta1 = ai * xi0 + ar * eta0 - eta1;
            yr1 = ar * yr0 - ai * yi0 - yr1 + 2 * n * alp[n];
            yi1 = ai * yr0 + ar * yi0 - yi1;
            n = n-1;

            xi0  = ar * xi1 - ai * eta1 - xi0 + alp[n];
            eta0 = ai * xi1 + ar * eta1 - eta0;
            yr0 = ar * yr1 - ai * yi1 - yr0 + 2 * n * alp[n];
            yi0 = ai * yr1 + ar * yi1 - yi0;
            n=n-1;
        }
        ar = s0 * ch0;
        ai = c0 * sh0;

        const double xi  = xip  + ar * xi0 - ai * eta0;
        const double eta = etap + ai * xi0 + ar * eta0;
        
        double y = a1 * k0 * (backside ? M_PI - xi : xi) * latsign;
        double x = a1 * k0 * eta * lonsign;

        x = x+ FE;
        y = (y>0) ? y : y+FN;
        
        E[i] = x;
        N[i]=y;
        utmzone[i*3]= (char)((zone/10) +'0');
        utmzone[1+i*3]= (char)((zone%10) +'0');
        utmzone[2+i*3]= (char)(letter);
        h[i]=lla[2+i*3];
    }
    
}