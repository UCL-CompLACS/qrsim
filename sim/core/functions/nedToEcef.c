#define _USE_MATH_DEFINES
#include <math.h>
#include "mex.h"
 
#define MAXPOW 6
#define f    3.35281066474748e-3
#define aa   6378137  
#define a1   6367449.14582
#define e  8.181919084262149e-02
#define e2 6.694379990141316e-03
#define e2m 0.993305620009859 
#define n_ 1.679220386383705e-03
#define k0   0.9996
#define FE   500000
#define FN   10000000
#define bet1 8.3773216406e-04
#define bet2 5.9058701522e-08
#define bet3 1.6734826653e-10
#define bet4 2.1647980401e-13
#define bet5 3.7879780462e-16
#define bet6 7.2487488907e-19
#define tol_ 1.49011611938e-09

#if !defined(MAX)
#define    MAX(A, B)    ((A) > (B) ? (A) : (B))
#endif

#if defined(_WIN32) || defined(_WIN64)
double atanh(double z){
   return 0.5*log((1+z)/(1-z));
}
#endif

void mexFunction( int nlhs, mxArray *plhs[],
        int nrhs, const mxArray *prhs[] ) {
    int cols;
    int rows;
    double* NED;
    int E_field_num;
    double* utmoriginE;
    int N_field_num;
    double* utmoriginN;
    int h_field_num;
    double* utmoriginH;
    int zone_field_num;
    mxChar* utmoriginZONE;
    double* ecef;    
    double bet[7] = {0, bet1, bet2, bet3, bet4, bet5, bet6};    
    int i;
    double x;
    double y;
    double h;        
    double zone;
    double lon0;
    double xi;
    double eta;
    int xisign;
    int etasign;
    int backside;
    double c0;
    double ch0;
    double s0;
    double sh0;
    double ar;
    double ai;
    int n;
    double xip0;
    double etap0;
    double xip1;
    double etap1;
    double yr0;
    double yi0;
    double yr1;
    double yi1;
    double xip;
    double etap;
    double s;
    double c;
    double r;
    double lam;
    double phi;
    double taup;
    double tau;
    double stol;
    int j;
    double tau1;
    double sig;
    double taupa;
    double dtau;
    double lat;
    double lon;
    double sinphi;
    double cosphi;
    double N;

    /* Check for proper number and size of arguments */
    if (nrhs != 2) {
        mexErrMsgTxt("Two inputs arguments required.");
    }
    
    if (nlhs != 1) {
        mexErrMsgTxt("One output argument required.");
    }
    
    cols = (int)mxGetN(prhs[0]);
    rows = (int)mxGetM(prhs[0]);
    
    if (rows != 3) {
        mexErrMsgTxt("Input has wrong dimensions.");
    }
    
    /* get pointers */
    NED = mxGetPr(prhs[0]);
    
    E_field_num = mxGetFieldNumber(prhs[1], "E");
    utmoriginE = mxGetPr(mxGetFieldByNumber(prhs[1], 0, E_field_num));
    N_field_num = mxGetFieldNumber(prhs[1], "N");
    utmoriginN = mxGetPr(mxGetFieldByNumber(prhs[1], 0, N_field_num));
    h_field_num = mxGetFieldNumber(prhs[1], "h");
    utmoriginH = mxGetPr(mxGetFieldByNumber(prhs[1], 0, h_field_num));
    zone_field_num = mxGetFieldNumber(prhs[1], "zone");
    utmoriginZONE = mxGetChars(mxGetFieldByNumber(prhs[1], 0, zone_field_num));
    
    /* Create a matrix for the return argument */
    plhs[0] = mxCreateDoubleMatrix(3, cols, mxREAL);
    ecef = mxGetPr(plhs[0]);

    for(i=0; i<cols; i++){       
        
        if (utmoriginZONE[2]>'X' || utmoriginZONE[2]<'C'){
            mexPrintf("nedToEcef: Warning utmzone should be a vector of strings like 30T, not %c%c%c\n",utmoriginZONE[0],utmoriginZONE[1],utmoriginZONE[2]);
        }
        
        x = utmoriginE[0] + NED[1+3*i] -FE;
        y = utmoriginN[0] + NED[3*i];
        y = (utmoriginZONE[2]>'M') ? y : y-FN;
        h = utmoriginH[0]-NED[2+3*i];
        
        zone = (utmoriginZONE[0]-'0')*10+(utmoriginZONE[1]-'0');
        lon0 = ( ( zone * 6 ) - 183 );
                
        xi = y / (a1*k0);
        eta = x / (a1*k0);
        
        /* Explicitly enforce the parity*/
        xisign = (xi < 0) ? -1 : 1;
        etasign = (eta < 0) ? -1 : 1;
        
        xi = xi*xisign;
        eta = eta*etasign;
        
        backside = (xi > M_PI/2);
        
        if (backside){
            xi = M_PI - xi;
        }
        c0 = cos(2 * xi);
        ch0 = cosh(2 * eta);
        s0 = sin(2 * xi);
        sh0 = sinh(2 * eta);
        ar = 2 * c0 * ch0;
        ai = -2 * s0 * sh0;
        n = MAXPOW;
        
        /* Accumulators for zeta'*/
        xip0 = (n & 1 ? -bet[n] : 0);
        
        etap0 = 0;
        xip1 = 0;
        etap1 = 0;
        /* Accumulators for dzeta'/dzeta*/
        yr0 = (n & 1 ? - 2 * MAXPOW * bet[n--] : 0);
        
        yi0 = 0;
        yr1 = 0;
        yi1 = 0;
        while (n>0){
            xip1  = ar * xip0 - ai * etap0 - xip1 - bet[n];
            etap1 = ai * xip0 + ar * etap0 - etap1;
            yr1 = ar * yr0 - ai * yi0 - yr1 - 2 * n * bet[n];
            yi1 = ai * yr0 + ar * yi0 - yi1;
            n=n-1;
            xip0  = ar * xip1 - ai * etap1 - xip0 - bet[n];
            etap0 = ai * xip1 + ar * etap1 - etap0;
            yr0 = ar * yr1 - ai * yi1 - yr0 - 2 * n * bet[n];
            yi0 = ai * yr1 + ar * yi1 - yi0;
            n=n-1;
        }
        
        ar = s0 * ch0;
        ai = c0 * sh0;
        xip  = xi  + ar * xip0 - ai * etap0;
        etap = eta + ai * xip0 + ar * etap0;
        
        /* Convergence and scale for Gauss-Schreiber TM to Gauss-Krueger TM.*/
        s = sinh(etap);
        c = MAX(0, cos(xip)); /* cos(M_PI/2) might be negative*/
        r = hypot(s, c);

        if (r != 0){
            lam = atan2(s, c);        /* Krueger p 17 (25)*/
            /* Use Newton's method to solve for tau*/
            
            taup = sin(xip)/r;
            /* To lowest order in e^2, taup = (1 - e^2) * tau = _e2m * tau; so use
             * % tau = taup/_e2m as a starting guess.  Only 1 iteration is needed for
             * % |lat| < 3.35 deg, otherwise 2 iterations are needed. */
            tau = taup/e2m;
            stol = tol_ * MAX(1, fabs(taup));
            
            for (j = 1; j<=5;j++){
                tau1 = hypot(1, tau);
                sig = sinh( e*atanh(e* tau / tau1 ) );
                taupa = hypot(1, sig) * tau - sig * tau1;
                dtau = (taup-taupa)*(1+e2m*tau*tau)/(e2m*tau1*hypot(1, taupa));
                tau = tau + dtau;
                if (!(fabs(dtau) >= stol)){
                    break;
                }
            }
            phi = atan(tau);
        }else{
            phi = M_PI/2;
            lam = 0;
        }
            
        lat = phi / (M_PI/180) * xisign;
        lon = lam / (M_PI/180);
        
        if (backside){
            lon = 180 - lon;
        }
        lon = lon*etasign;
        
        /* Avoid losing a bit of accuracy in lon (assuming lon0 is an integer) */
        if (lon + lon0 >= 180){
            lon = lon + lon0 - 360;
        }else{
            if (lon + lon0 < -180){
                lon = lon + lon0 + 360;
            }else{
                lon = lon + lon0;
            }
        }
         
        phi = lat / (180/M_PI);
        lam = lon / (180/M_PI);
                
        sinphi = sin(phi);
        cosphi = cos(phi);
        N  = aa / sqrt(1 - e2 * sinphi* sinphi);
        
        ecef[i*3]= (N + h) * cosphi * cos(lam);
        ecef[1+i*3] = (N + h) * cosphi * sin(lam);
        ecef[2+i*3] = (N*(1 - e2) + h) * sinphi;
    }
    
}
