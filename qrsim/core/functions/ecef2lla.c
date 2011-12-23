#include <math.h>
#include "mex.h"


#define a   6378137               /*Semimajor axis*/
#define f   0.003352810664747     /*Flattening*/
#define e2  0.006694379990141     /*Square of first eccentricity*/
#define ep2 0.006739496742276     /*Square of second eccentricity*/
#define b   6356752.314245179     /*Semiminor axis*/
#define rad2deg  57.295779513082323

void mexFunction( int nlhs, mxArray *plhs[],
        int nrhs, const mxArray *prhs[] ) {
    
    /* Check for proper number and size of arguments */
    if (nrhs != 1) {
        mexErrMsgTxt("One input arguments required.");
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
    
    /* Create a matrix for the return argument */
    plhs[0] = mxCreateDoubleMatrix(3,cols, mxREAL);
    double* lla = mxGetPr(plhs[0]);
    
    
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
        
        double phi = atan2(z+b*ep2*sbeta*sbeta*sbeta, rho-a*e2*cbeta*cbeta*cbeta);
        double sphi = sin(phi); double cphi = cos(phi);
        
        /* Fixed-point iteration with Bowring's formula*/
        /* (typically converges within two or three iterations)*/
        double betaNew = atan2((1 - f)*sin(phi), cos(phi));
        int count = 0;
        while ((beta!=betaNew) && count < 5){
            beta = betaNew;
            sbeta = sin(beta); cbeta = cos(beta);
            phi = atan2(z+b*ep2*sbeta*sbeta*sbeta, rho-a*e2*cbeta*cbeta*cbeta);
            sphi = sin(phi); cphi = cos(phi);
            betaNew = atan2((1 - f)*sphi, cphi);
            count++;
        }
        
        /* Calculate ellipsoidal height from the final value for latitude*/
        double N = a / sqrt(1 - e2 * sphi* sphi);
        double h = rho * cphi + (z + e2 * N* sphi) * sphi - N;
        
        lla[i*3] = rad2deg*phi;
        lla[i*3+1] = rad2deg*lambda;
        lla[i*3+2] =h;
    }
    
}