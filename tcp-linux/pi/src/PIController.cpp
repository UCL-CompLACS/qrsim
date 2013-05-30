/*
 * PIController.cpp
 *
 *  Created on: Mar 31, 2013
 *      Author: vgomez, Sep Thijssen
 */

#include "PIController.h"

using namespace std;

// static members initialization
double PIController::dt = .0;
int PIController::units = 0;
double PIController::R = .0;
double PIController::nu = .0;
double PIController::lambda = .0;
int PIController::dtperstep = 0;
int PIController::H = 0;
double PIController::dS = 0;
double PIController::stdv = 0;

//
// Model methods
//

void PIController::Model::step(	const vec& A ) {
	for(int i=0; i<units; i++) {

		state[4*i+0] += state[4*i+2]*dt;	//  X position
		state[4*i+1] += state[4*i+3]*dt;	//  Y position

		state[4*i+2] += A[2*i+0]*dt;		//  X velocity
		state[4*i+3] += A[2*i+1]*dt;		//  Y velocity

	}
}

double PIController::Model::immediateControlCost( const vec& A ) const
{
	// Immediate control cost of the control action A.
	double v=0;
	for(unsigned int i=0; i<A.size(); i++) {
		// v += R[i]*A[i]*A[i];
		v += R*A[i]*A[i];
	}
	return v*.5;
}

double PIController::Model::immediateStateReward( const vec &X ) const
{
	// Immediate state reward of the state X.
	// Returns the negative of the cost c in this case.
	double c=0;

	// cost per unit
	for(int i=0; i<units; i++)
	{
		double speed = sqrt(X[4*i+2]*X[4*i+2] + X[4*i+3]*X[4*i+3]);
		// penalty for low or high speeds
		c += exp(speed-3); 		// determines max allowed speed
		c += exp(-speed+1);		// determines min allowed speed

		// penalty for going to far away
		double d;
		d = sqrt(X[4*i+0]*X[4*i+0] + X[4*i+1]*X[4*i+1]);
		c+= exp(d-4);				// max allowed distance ~= 4

		// penalty for collision
		for(int j=i+1; j<units; j++)
		{	d=0;
			d+=(X[4*i+0]-X[4*j+0])*(X[4*i+0]-X[4*j+0]);
			d+=(X[4*i+1]-X[4*j+1])*(X[4*i+1]-X[4*j+1]);
			if (0.00001 > d) d=0.00001;
			c+=1/d;
		}
	}
	return -c;
}

//
// Sampler methods
//

double PIController::Sampler::runningStateReward(
		const vec& X0,
		const vvec& control
) {
	// Returns state based reward of a rollout.
	model.setState(X0);
	double v=0;
	for (int s=0; s<H; s++) {
		for (int i=0; i<dtperstep; i++){
			v += model.immediateStateReward(model.getState())*dt;
			model.step( control[s] );
		}
	}
	v += model.endStateReward(model.getState());
	return v;
}

double PIController::Sampler::runningControlCost( const vvec& control ) const
{
	// Returns the cost of a control sequence.
	double c=0;
	for (int s=0; s<H; s++)
		c += model.immediateControlCost(control[s]);
	return c*dS;
}


//
// PIController methods
//

PIController::PIController(
	const int& dimUAVx,
	const int& dimUAVu,
	const int& seed,
	const int& N
) :
		dimX(dimUAVx*units),
		dimU(dimUAVu*units),
		N(N),
		u_exp(H,vec(dimU,0)),
		sampl()
{
	gsl_rng_default_seed = seed;
	r = gsl_rng_alloc (gsl_rng_default);
	time_t timer;
	time(&timer);
	char name[20];
	sprintf(name,"experiment%d.m",(int)timer);
	outfile = name;
	plotSetup();
}

PIController::~PIController() {
	// TODO Auto-generated destructor stub
}

vvec PIController::computeControl(const vvec &X_qrsim) {
	// Input is qrsim state. 
	// Output is qrsim action.
	
	vec state = convertState(X_qrsim);
	vec action(dimU,0);

	// Move to horizon with exploring controls
	for (int s=1; s<H; s++) u_exp[s-1] = u_exp[s];
	u_exp[H-1] = vec(dimU,0);

	// Set value of exploring controls
	double v_exp = sampl.runningStateReward(state, u_exp);
	v_exp -= sampl.runningControlCost(u_exp);

	// define some algorithm variables:
	double v_max = -1e100;
	vec  v_roll(N);
	vvec u_roll(H, vec(dimU));
	vvec noise(H, vec(dimU));
	vvec u_init(N, vec(dimU));

	for (int n=0; n<N; n++) {

		// set exploring noise and perturb control.
		for (int s=0; s<H; s++) {
			for(int i=0; i<dimU; i++) {
				noise[s][i] = gsl_ran_gaussian(r,stdv);
				u_roll[s][i] = u_exp[s][i] + noise[s][i];
			}
		}

		// save initial direction
		u_init[n] = u_roll[0];

		// set value of random control
		v_roll[n] = sampl.runningStateReward(state, u_roll);
		v_roll[n] -= sampl.runningControlCost(u_roll);

		// improve exploring control if possible
		if ( v_roll[n] > v_exp ) {
			v_exp = v_roll[n];
			u_exp = u_roll;
		}

		// correct value of rollout for to get correct importance sampling.
		v_roll[n] += sampl.runningControlCost(noise);

		// save max for rescaling weights
		if (v_roll[n] > v_max) v_max = v_roll[n];
	}
	
	// PI update
	double sum1 = 0;	// sum of weights
	double sum2 = 0;	// sum of square weights
	for (int n=0; n<N; n++) {
		double W = v_roll[n] - v_max;
		if (W >= -20*lambda) {
			if (lambda == 0.) W = 1;
			else W = exp(W/lambda);
			sum1 += W;
			sum2 += W*W;
			for (int i=0; i<dimU; i++)
				action[i] += W*u_init[n][i];
		}
		else W = 0;
	}

	// normalization
	for (int i=0; i<dimU; i++)
		action[i] /= sum1;
	cout << " end " << endl;
	printTime();
	plotCurrent(state,action);
	return convertControl(action, X_qrsim);
}

// Real world state (X_qrsim) to simplified state (X).
vec PIController::convertState(const vvec& X_qrsim) const {
	vec X(units*4);
	for (int i=0; i<units; i++) {
		X[i*4+0] = X_qrsim[i][0];		// x position
		X[i*4+1] = X_qrsim[i][1];		// y position
		X[i*4+2] = X_qrsim[i][6];		// x velocity
		X[i*4+3] = X_qrsim[i][7];		// y velocity
	}
	return X;
}

// Simplified action A to real world action A_qrsim.
// Second input is a Real world state. 
vvec PIController::convertControl(const vec &A, const vvec &X_qrsim) const {
	vvec A_qrsim(units);
	for (int i=0; i<units; i++) {
		A_qrsim[i].push_back(X_qrsim[i][6] + dS*A[2*i+0]);	//  X velocity
		A_qrsim[i].push_back(X_qrsim[i][7] + dS*A[2*i+1]);	//  Y velocity
		A_qrsim[i].push_back(0.);              				//  Z velocity
	}
	return A_qrsim;
}

void PIController::printTime() const       // GENERAL
{
	clock_t t=clock();
	clock_t s=t/CLOCKS_PER_SEC;
	t=t%CLOCKS_PER_SEC;
	t=t*100;
	t=t/CLOCKS_PER_SEC;
	cout << "time: "<<s<<".";
	if (t<10) cout<<0;
	cout<<t<<endl;
}


void PIController::plotSetup() const 	// GENERAL
// For export and plotting in matlab.
{	
	// id number of experiment
	ofstream fout(outfile.c_str(),ios::trunc);
	fout << "%%matlab" << endl;
	fout << "%%This file is generated by pi_qrsim.cpp" << endl << endl;
	fout << "%%Moving Horizon stochastic PI control." << endl << endl;
	fout << "%%PARAMETERS:" << endl << endl;
	fout << "%%Horizon steps,\n H=" << H << ";"<< endl;
	fout << "%%Plant Precision" << endl << " dtperstep=" << dtperstep << ";"<< endl;
	fout << "%%Infinitessimal time, " << endl << "dt=" << dt << ";"<< endl;
	fout << "%%Time of a step, " << endl << "dS=dtperstep*dt;" << endl;
	fout << "%%Samples, " << endl << "N=" << N << ";"<< endl;
	fout << "%%DATA:" << endl;
	fout << "X = [];\n U = [];" << endl;
	fout.close();
}

void PIController::plotCurrent(const vec& state, const vec& action) const	
// For export and plotting in matlab
{
	// id number of experiment
	ofstream fout(outfile.c_str(),ios::app);
	fout << "X = [X; [";
	for(int i=0; i<dimX; i++)
		fout << state[i] << " ";
	fout << "]];" << endl;
	fout << "U = [U; [" << endl;
	for(int i=0; i<dimU; i++)
		fout << action[i] << " ";
	fout << "]];" << endl;
	fout.close();
}

