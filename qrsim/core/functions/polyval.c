#include <math.h>
#include "mex.h"

void mexFunction( int nlhs, mxArray *plhs[],
        int nrhs, const mxArray *prhs[] ) {
    int rows;
    int nc;
    double* p;
    double* x;
    double* mu;
    double* y;
    double xi;
    double yi;
    int i,j;

    /* Check for proper number and size of arguments */
    if (nrhs != 4) {
        mexErrMsgTxt("Four input arguments required.");
    }
    
    if (nlhs > 1) {
        mexErrMsgTxt("One output argument required.");
    }
    
    rows = mxGetM(prhs[1]);
    nc = mxGetN(prhs[0]);
    
    if (mxGetM(prhs[0])!=1){
        mexErrMsgTxt("P must be a row vector.");
    }
    
    /* get pointers */
    p = mxGetPr(prhs[0]);
    x = mxGetPr(prhs[1]);    
    mu = mxGetPr(prhs[3]);
    
    /* Create a matrix for the return argument */
    plhs[0] = mxCreateDoubleMatrix(rows, 1, mxREAL);
    y = mxGetPr(plhs[0]);

    for(i=0; i<rows; i++){
        
        xi = (x[i] - mu[0])/mu[1];
        yi=p[0];
        for(j=1; j<nc; j++){
            yi = xi* yi + p[j];
        }
        y[i]=yi;
    }
}
