#include <math.h>
#include "mex.h"

void mexFunction( int nlhs, mxArray *plhs[],
        int nrhs, const mxArray *prhs[] ) {
    
    /* Check for proper number and size of arguments */
    if (nrhs != 4) {
        mexErrMsgTxt("Four input arguments required.");
    }
    
    if (nlhs > 1) {
        mexErrMsgTxt("One output argument required.");
    }
    
    int rows = mxGetM(prhs[1]);
    int nc = mxGetN(prhs[0]);
    
    /* get pointers */
    double* p = mxGetPr(prhs[0]);
    double* x = mxGetPr(prhs[1]);    
    double* mu = mxGetPr(prhs[3]);
    
    /* Create a matrix for the return argument */
    plhs[0] = mxCreateDoubleMatrix(rows, 1, mxREAL);
    double* y = mxGetPr(plhs[0]);

    
    int i;
    for(i=0; i<rows; i++){
        
        const double xi = (x[i] - mu[0])/mu[1];
        double yi=p[0];
        int j;
        for(j=1; j<nc; j++){
            yi = xi* yi + p[j];
        }
        y[i]=yi;
    }
}