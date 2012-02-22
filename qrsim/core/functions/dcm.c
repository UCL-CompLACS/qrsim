#include <math.h>
#include "mex.h"


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

    if (rows != 1) {
        mexErrMsgTxt("Input has wrong dimensions.");
    }

    if (cols < 6) {
        mexErrMsgTxt("Input has wrong dimensions.");
    }    
    
    /* get pointers */
    double* X = mxGetPr(prhs[0]);
    
    /* Create a matrix for the return argument */
    plhs[0] = mxCreateDoubleMatrix(3,3, mxREAL);
    double* d = mxGetPr(plhs[0]);
    
    /*   [          cy*cz,          cy*sz,            -sy]
         [ sy*sx*cz-sz*cx, sy*sx*sz+cz*cx,          cy*sx]
         [ sy*cx*cz+sz*sx, sy*cx*sz-cz*sx,          cy*cx]
    */
    
    const double sph = sin(X[3]); const double cph = cos(X[3]);
    const double sth = sin(X[4]); const double cth = cos(X[4]); 
    const double sps = sin(X[5]); const double cps = cos(X[5]);
    
    d[0] =  cth*cps;
    d[3] = cth*sps;
    d[6] = -sth;
    d[1] = sph*sth*cps - cph*sps;
    d[4] = sph*sth*sps + cph*cps;
    d[7] = sph*cth;
    d[2] = cph*sth*cps + sph*sps;
    d[5] = cph*sth*sps - sph*cps;
    d[8] = cph*cth;
    
}