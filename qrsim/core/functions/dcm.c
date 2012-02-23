#include <math.h>
#include "mex.h"


void mexFunction( int nlhs, mxArray *plhs[],
        int nrhs, const mxArray *prhs[] ) {

    int rows;
    int cols; 	    
    double* X;
    double* d;
    double sph; double cph;
    double sth; double cth; 
    double sps; double cps;

    /* Check for proper number and size of arguments */
    if (nrhs != 1) {
        mexErrMsgTxt("One input arguments required.");
    }
    
    if (nlhs > 1) {
        mexErrMsgTxt("Too many output arguments.");
    }
    
    rows = mxGetM(prhs[0]);
    cols = mxGetN(prhs[0]);

    if (cols != 1) {
        mexErrMsgTxt("Input has wrong dimensions.");
    }

    if (rows < 6) {
        mexErrMsgTxt("Input has wrong dimensions.");
    }    
    
    /* get pointers */
    X = mxGetPr(prhs[0]);
    
    /* Create a matrix for the return argument */
    plhs[0] = mxCreateDoubleMatrix(3,3, mxREAL);
    d = mxGetPr(plhs[0]);
    
    /*   [          cy*cz,          cy*sz,            -sy]
         [ sy*sx*cz-sz*cx, sy*sx*sz+cz*cx,          cy*sx]
         [ sy*cx*cz+sz*sx, sy*cx*sz-cz*sx,          cy*cx]
    */
    
    sph = sin(X[3]); cph = cos(X[3]);
    sth = sin(X[4]); cth = cos(X[4]); 
    sps = sin(X[5]); cps = cos(X[5]);
    
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
