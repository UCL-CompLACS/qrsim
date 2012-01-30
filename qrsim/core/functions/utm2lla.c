#include <math.h>
#include "mex.h"

#define MAXPOW 6
#define f    3.35281066474748e-3
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
    
    double bet[7] = {0, bet1, bet2, bet3, bet4, bet5, bet6};
    
    int i;
    
    for(i=0; i<cols; i++){
        
        if (utmzone[2+3*i]>'X' || utmzone[2+3*i]<'C'){
            mexPrintf("utm2lla: Warning utmzone should be a vector of strings like 30T, not 30t\n");
        }
        
        double x=E[i];
        double y=N[i];
        
        x = x -FE;
        y = (utmzone[2+3*i]>'M') ? y : y-FN;
        
        const double zone = (utmzone[3*i]-'0')*10+(utmzone[1+3*i]-'0');
        const double lon0 = ( ( zone * 6 ) - 183 );
        
        
        double xi = y / (a1*k0);
        double eta = x / (a1*k0);
        
        /* Explicitly enforce the parity*/
        const int xisign = (xi < 0) ? -1 : 1;
        const int etasign = (eta < 0) ? -1 : 1;
        
        xi = xi*xisign;
        eta = eta*etasign;
        
        int backside = (xi > M_PI/2);
        
        if (backside){
            xi = M_PI - xi;
        }
        double c0 = cos(2 * xi);
        double ch0 = cosh(2 * eta);
        double s0 = sin(2 * xi);
        double sh0 = sinh(2 * eta);
        double ar = 2 * c0 * ch0;
        double ai = -2 * s0 * sh0;
        int n = MAXPOW;
        
        /* Accumulators for zeta'*/
        double xip0 = (n & 1 ? -bet[n] : 0);
        
        double etap0 = 0;
        double xip1 = 0;
        double etap1 = 0;
        /* Accumulators for dzeta'/dzeta*/
        double yr0 = (n & 1 ? - 2 * MAXPOW * bet[n--] : 0);
        
        double yi0 = 0;
        double yr1 = 0;
        double yi1 = 0;
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
        const double xip  = xi  + ar * xip0 - ai * etap0;
        const double etap = eta + ai * xip0 + ar * etap0;
        
        /* Convergence and scale for Gauss-Schreiber TM to Gauss-Krueger TM.*/
        const double s = sinh(etap);
        const double c = MAX(0, cos(xip)); /* cos(M_PI/2) might be negative*/
        const double r = hypot(s, c);
        double lam;
        double phi;
        if (r != 0){
            lam = atan2(s, c);        /* Krueger p 17 (25)*/
            /* Use Newton's method to solve for tau*/
            
            const double taup = sin(xip)/r;
            /* To lowest order in e^2, taup = (1 - e^2) * tau = _e2m * tau; so use
             * % tau = taup/_e2m as a starting guess.  Only 1 iteration is needed for
             * % |lat| < 3.35 deg, otherwise 2 iterations are needed.  If, instead,
             * % tau = taup is used the mean number of iterations increases to 1.99
             * % (2 iterations are needed except near tau = 0).*/
            double tau = taup/e2m;
            const double stol = tol_ * MAX(1, fabs(taup));
            
            int j;
            for (j = 1; j<=5;j++){
                double tau1 = hypot(1, tau);
                const double sig = sinh( e*atanh(e* tau / tau1 ) );
                const double taupa = hypot(1, sig) * tau - sig * tau1;
                const double dtau = (taup-taupa)*(1+e2m*tau*tau)/(e2m*tau1*hypot(1, taupa));
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
        
        double lat = phi / (M_PI/180) * xisign;
        double lon = lam / (M_PI/180);
        
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
        
        lla[3*i] = lat;
        lla[1+3*i] = lon;
        lla[2+3*i] = h[i];
    }
}