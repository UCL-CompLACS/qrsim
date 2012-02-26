#include <math.h>
#include "mex.h"

#define LOW_THROTTLE_LIMIT 300
#define MAX_ANGVEL  2.617993877991494
#define G     9.81

/* rotational params */
#define pq0  -3.25060e-04
#define pq1   1.79797e+02
#define pq2  -24.3536
#define r0   -4.81783e-03
#define r1   -5.08944

/* thrust params */
#define Cth0  6.63881e-01
#define Cth1  7.44649e-04
#define Cth2  2.39855e-06
#define Cvb0 -18.0007
#define Cvb1  4.23754
#define tau0  3.07321
#define tau1  46.8004

/* linear drag params*/
#define kuv  -4.97391e-01
#define kw   -1.35341

void mexFunction( int nlhs, mxArray *plhs[],
        int nrhs, const mxArray *prhs[] ) {
    
    double* X;
    double* U;
    double dt;
    double* Xdot;  
    double* a;     
    double pt,rl,th,ya,vb;    
    double windx,windy,windz;
    double mass;    
    double phi,theta,psi;
    double u,v,w;
    double p,q,r;
    double Fth;
    double sph,cph;
    double sth,cth,tth;
    double sps,cps;        
    double dcm[3][3];
    double dFth;
    double tau;
    double gb[3];
    double ra[3];    
    int i;    
    
    /* Check for proper number and size of arguments */
    if (nrhs != 3) {
        mexErrMsgTxt("Three input arguments required.");
    } else if (nlhs != 2) {
        mexErrMsgTxt("Two output arguments required.");
    }
    
    if (mxGetM(prhs[0]) != 13 || mxGetN(prhs[0]) != 1) {
        mexErrMsgTxt("State X has wrong dimensions.");
    }
    
    if (mxGetM(prhs[1]) != 15 || mxGetN(prhs[1]) != 1) {
        mexErrMsgTxt("Augmented Control U has wrong dimensions.");
    }
    
    if (mxGetM(prhs[2]) != 1 || mxGetN(prhs[2]) != 1) {
        mexErrMsgTxt("time t has wrong dimensions.");
    }
    
    /* get pointers */
    X = mxGetPr(prhs[0]);
    U = mxGetPr(prhs[1]);
    dt = *mxGetPr(prhs[2]);
    
    /* Create a matrix for the return arguments */
    plhs[0] = mxCreateDoubleMatrix(13, 1, mxREAL);
    Xdot = mxGetPr(plhs[0]);  
    plhs[1] = mxCreateDoubleMatrix(3, 1, mxREAL);  
    a = mxGetPr(plhs[1]); 
    
    pt = U[0];
    rl = U[1];
    th = U[2];
    ya = U[3];
    vb = U[4];
    
    windx = U[5];
    windy = U[6];    
    windz = U[7];
    mass = U[8];
    
    phi = X[3];
    theta = X[4];
    psi = X[5];
    u = X[6];
    v = X[7];
    w = X[8];
    p = X[9];
    q = X[10];
    r = X[11];
    Fth = X[12];
    
    /* handy values */
    sph = sin(phi); cph = cos(phi);
    sth = sin(theta); cth = cos(theta); tth = sth/cth;
    sps = sin(psi); cps = cos(psi);
           
    dcm[0][0] = cth*cps;
    dcm[0][1] = -cph*sps+sph*sth*cps;
    dcm[0][2] = sph*sps+cph*sth*cps;
    
    dcm[1][0] = cth*sps;
    dcm[1][1] = cph*cps+sph*sth*sps;
    dcm[1][2] = -sph*cps+cph*sth*sps;
    
    dcm[2][0] = -sth;
    dcm[2][1] = sph*cth;
    dcm[2][2] = cph*cth;
    
    /* angles */
    Xdot[3] = p+q*sph*tth+r*cph*tth;
    Xdot[4] = q*cph - r*sph;
    Xdot[5] = q*sph/cth+r*cph/cth;
    
    /* angular velocities (body frame) */
    Xdot[9] = pq1*(pq0*rl - phi) + pq2*p;    
    if((p>MAX_ANGVEL && (Xdot[9]>0))||(p<-MAX_ANGVEL && (Xdot[9]<0))){
        Xdot[9] = 0;
    }
    
    Xdot[10] = pq1*(pq0*pt - theta) + pq2*q;    
    if((q>MAX_ANGVEL && (Xdot[10]>0))||(q<-MAX_ANGVEL && (Xdot[10]<0))){
        Xdot[10] = 0;
    }
    
    Xdot[11] = r0*ya + r1*r;
    
    /* position */
    Xdot[0] =  u*dcm[0][0]+v*dcm[0][1]+w*dcm[0][2];
    Xdot[1] =  u*dcm[1][0]+v*dcm[1][1]+w*dcm[1][2];
    Xdot[2] =  u*dcm[2][0]+v*dcm[2][1]+w*dcm[2][2];
    
    /*linear velocities (body frame) */
    
    /* first we update the thrust force */
    dFth = ((Cth0 + Cth1*th + Cth2*th*th)-Fth);
        
    if (th<LOW_THROTTLE_LIMIT){
        Xdot[12] = tau0*dFth;
    } else {
        if (abs(dFth)<(tau1*dt)){
            tau=dFth/dt;
        } else {
            if (dFth>0){
                tau = tau1;
            } else {
                tau = -tau1;
            }
        }
        
        if((Fth + tau*dt) > (Cvb0+Cvb1*vb)){
            Xdot[12] = (Cvb0+Cvb1*vb - Fth)/dt;
        }else{
            Xdot[12] = tau;
        }
    }
    
    /* gravity in body frame */
    gb[0] = dcm[2][0]*G; gb[1] = dcm[2][1]*G; gb[2] = dcm[2][2]*G;
    
    /*resultant acceleration in body frame */
    /*note: thrust force always orthogonal to the rotor */
    /*plane i.e. in the  -Z body direction */
    ra[0] = gb[0]; ra[1] = gb[1]; ra[2] = gb[2]-((Fth+Xdot[12]*dt)/mass);
    
    Xdot[6] = -q*w + r*v + ra[0] + kuv*(u-windx);
    Xdot[7] = -r*u + p*w + ra[1] + kuv*(v-windy);
    Xdot[8] = -p*v + q*u + ra[2] + kw*(w-windz);
    
    a[0]=Xdot[6]-gb[0];
    a[1]=Xdot[7]-gb[1];   
    a[2]=Xdot[8]-gb[2];    
    
    for(i=0; i<6; i++){
        Xdot[6+i]+=U[9+i];
    }
}

