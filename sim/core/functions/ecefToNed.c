#define _USE_MATH_DEFINES
#include <math.h>
#include "mex.h"


#define aa   6378137               
#define ep2 0.006739496742276    
#define b   6356752.314245179

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

#if defined(_WIN32) || defined(_WIN64)
double atanh(double z){
   return 0.5*log((1+z)/(1-z));
}

double asinh(double z){
    return log(z+sqrt(z*z+1));
}
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

    int rows;
    int cols;
    double* ecef;
    int E_field_num;
    double* utmoriginE;
    int N_field_num;
    double* utmoriginN;
    int h_field_num;
    double* utmoriginH;
    int zone_field_num;
    mxChar* utmoriginZONE;
    double* NED;    
    double alp[7] = {0, alp1, alp2, alp3, alp4, alp5, alp6};    
    int i;
    double x;
    double y;
    double z;
    double lambda;
    double rho;
    double beta;
    double sbeta;
    double cbeta;
    double phi;
    double cphi;
    double sphi;
    double betaNew;
    int count;
    double N;
    double h;        
    double lat;
    double lon;        
    int zone;
    int lon0;
    int latsign;
    int lonsign;
    int backside;
    double lam;
    double xip;
    double etap;
    double c;
    double tau;
    double secphi;
    double sig;
    double taup;
    double c0;
    double ch0;
    double s0;
    double sh0;
    double ar;
    double ai;        
    int n;
    double xi0;
    double eta0;
    double xi1;
    double eta1;
    double yr0;
    double yi0;
    double yr1;
    double yi1;        
    double xi;
    double eta;        
    double yy;
    double xx;

    /* Check for proper number and size of arguments */
    if (nrhs != 2) {
        mexErrMsgTxt("Two input arguments required.");
    }
    
    if (nlhs > 1) {
        mexErrMsgTxt("Too many output arguments.");
    }
    
    rows = (int)mxGetM(prhs[0]);
    cols = (int)mxGetN(prhs[0]);
    
    if (rows != 3) {
        mexErrMsgTxt("Input has wrong dimensions.");
    }
    
    /* get pointers */
    ecef = mxGetPr(prhs[0]);
    
    
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
    NED = mxGetPr(plhs[0]);
    
    for(i=0; i<cols; i++){
        x = ecef[i*3];
        y = ecef[i*3+1];
        z = ecef[i*3+2];
        
        /* Longitude*/
        lambda = atan2(y, x);
        
        /* Distance from Z-axis*/
        rho = sqrt(x*x+y*y);
        
        /* Bowring's formula for initial parametric (beta) and geodetic (phi) latitudes*/
        beta = atan2(z, (1 - f) * rho);
        sbeta = sin(beta); 
        cbeta = cos(beta);
        
        phi = atan2(z+b*ep2*sbeta*sbeta*sbeta, rho-aa*e2*cbeta*cbeta*cbeta);
        sphi = sin(phi); 
        cphi = cos(phi);
        
        /* Fixed-point iteration with Bowring's formula*/
        /* (typically converges within two or three iterations)*/
        betaNew = atan2((1 - f)*sin(phi), cos(phi));
        count = 0;
        while ((beta!=betaNew) && count < 5){
            beta = betaNew;
            sbeta = sin(beta); cbeta = cos(beta);
            phi = atan2(z+b*ep2*sbeta*sbeta*sbeta, rho-aa*e2*cbeta*cbeta*cbeta);
            sphi = sin(phi); cphi = cos(phi);
            betaNew = atan2((1 - f)*sphi, cphi);
            count++;
        }
        
        /* Calculate ellipsoidal height from the final value for latitude*/
        N = aa / sqrt(1 - e2 * sphi* sphi);
        h = rho * cphi + (z + e2 * N* sphi) * sphi - N;
        
        lat = phi * 180/M_PI;
        lon = lambda * 180/M_PI;
        
        zone = (int)((lon/6)+31);
        lon0 = ((zone*6) - 183);
        
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
        latsign = (lat < 0) ? -1 : 1;
        lonsign = (lon < 0) ? -1 : 1;
        
        lon = lon*lonsign;
        lat = lat*latsign;
        
        backside = (lon > 90);
        if (backside){
            if (lat == 0){
                latsign = -1;
            }
            lon = 180 - lon;
        }
        
        phi = lat * M_PI/180;
        lam = lon * M_PI/180;
        
        if (lat != 90){
            c = MAX(0, cos(lam)); /*cos(M_PI/2) might be negative*/
            tau = tan(phi);
            secphi = hypot(1, tau);
            sig = sinh(e*atanh(e*tau / secphi));
            taup = hypot(1, sig) * tau - sig * secphi;
            xip = atan2(taup, c);
            etap =asinh(sin(lam) / hypot(taup, c));
        }else{
            xip = M_PI/2;
            etap = 0;
        }
        c0 = cos(2 * xip);
        ch0 = cosh(2 * etap);
        s0 = sin(2 * xip);
        sh0 = sinh(2 * etap);
        ar = 2 * c0 * ch0;
        ai = -2 * s0 * sh0; /*2 * cos(2*zeta')*/
        
        n = MAXPOW;
        xi0 = (n & 1 ? alp[n] : 0);
        eta0 = 0;
        xi1 = 0;
        eta1 = 0;
        
        /*Accumulators for dzeta/dzeta'*/
        yr0 = (n & 1 ? 2 * MAXPOW * alp[n--] : 0);
        yi0 = 0;
        yr1 = 0;
        yi1 = 0;
        
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
        
        xi  = xip  + ar * xi0 - ai * eta0;
        eta = etap + ai * xi0 + ar * eta0;
        
        yy = a1 * k0 * (backside ? M_PI - xi : xi) * latsign;
        xx = a1 * k0 * eta * lonsign;
        
        xx = xx + FE;
        yy = (yy>0) ? yy : yy+FN;
        
        NED[3*i] = yy - utmoriginN[0];
        NED[1+3*i] = xx - utmoriginE[0];
        NED[2+3*i] = utmoriginH[0]-h;
        
    }
    
}
