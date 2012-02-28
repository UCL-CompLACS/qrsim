#include <math.h>
#include "mex.h"


#define a   6378137               /*Semimajor axis*/
#define f   0.003352810664747     /*Flattening*/
#define e2  0.006694379990141     /*Square of first eccentricity*/
#define ep2 0.006739496742276     /*Square of second eccentricity*/
#define b   6356752.314245179     /*Semiminor axis*/
#define radsToDegs  57.295779513082323

void mexFunction( int nlhs, mxArray *plhs[],
        int nrhs, const mxArray *prhs[] ) {

    int rows;
    int cols;
    double* ecef;
    double* lla;
    int i;
    double x,y,z;
    double lambda;
    double rho;
    double beta;
    double sbeta; 
    double cbeta;
    double phi;
    double sphi;
    double betaNew; 
    int count;
    double N;
    double h;
    double cphi;

    /* Check for proper number and size of arguments */
    if (nrhs != 1) {
        mexErrMsgTxt("One input arguments required.");
    }
    
    if (nlhs > 1) {
        mexErrMsgTxt("Too many output arguments.");
    }
    
    rows = mxGetM(prhs[0]);
    cols = mxGetN(prhs[0]);

    if (rows != 3) {
        mexErrMsgTxt("Input has wrong dimensions.");
    }
    
    /* get pointers */
    ecef = mxGetPr(prhs[0]);
    
    /* Create a matrix for the return argument */
    plhs[0] = mxCreateDoubleMatrix(3,cols, mxREAL);
    lla = mxGetPr(plhs[0]);

    
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
        
        phi = atan2(z+b*ep2*sbeta*sbeta*sbeta, rho-a*e2*cbeta*cbeta*cbeta);
        sphi = sin(phi); 
        cphi = cos(phi);
        
        /* Fixed-point iteration with Bowring's formula*/
        /* (typically converges within two or three iterations)*/
        betaNew = atan2((1 - f)*sin(phi), cos(phi));
        count = 0;
        while ((beta!=betaNew) && count < 5){
            beta = betaNew;
            sbeta = sin(beta); cbeta = cos(beta);
            phi = atan2(z+b*ep2*sbeta*sbeta*sbeta, rho-a*e2*cbeta*cbeta*cbeta);
            sphi = sin(phi); cphi = cos(phi);
            betaNew = atan2((1 - f)*sphi, cphi);
            count++;
        }
        
        /* Calculate ellipsoidal height from the final value for latitude*/
        N = a / sqrt(1 - e2 * sphi* sphi);
        h = rho * cphi + (z + e2 * N* sphi) * sphi - N;
        
        lla[i*3] = radsToDegs*phi;
        lla[i*3+1] = radsToDegs*lambda;
        lla[i*3+2] =h;
    }
    
}
