#include <math.h>
#include "mex.h"


#define a   6378137               /*Semimajor axis*/
#define e2  0.006694379990141     /*Square of first eccentricity*/
#define deg2rad  0.017453292519943

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
    double* lla = mxGetPr(prhs[0]);
    
    /* Create a matrix for the return argument */
    plhs[0] = mxCreateDoubleMatrix(3,cols, mxREAL);
    double* ecef = mxGetPr(plhs[0]);
      
    
    int i;
    
    for(i=0; i<cols; i++){        
        
        double phi = deg2rad*lla[i*3];
        double lambda = deg2rad*lla[1+i*3];
        double h = lla[2+i*3];        
        
        double sinphi = sin(phi);
        double cosphi = cos(phi);
        double N  = ((double)a) / sqrt(1 - e2 * sinphi* sinphi);
        
        ecef[i*3]= (N + h) * cosphi * cos(lambda);
        ecef[1+i*3] = (N + h) * cosphi * sin(lambda);
        ecef[2+i*3] = (N*(1 - e2) + h) * sinphi;        
    }
    
}