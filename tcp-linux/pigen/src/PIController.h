/*
 * PIController.h
 *
 *  Created on: Mar 31, 2013
 *      Author: vgomez, Sep Thijssen
 */

#ifndef PICONTROLLER_H_
#define PICONTROLLER_H_

#include "global.h"

#include <iostream>
#include <fstream>
#include <algorithm>
#include <gsl/gsl_rng.h>
#include <gsl/gsl_randist.h>

class PIController {
public:
	static double dt;		// time increment (required in Model)
	static int units;		// number of UAVs (required in Sampler and Model)
	static double R;	    // control (required in Model)
	static double nu;		// noise level
	static double lambda;  	// PI scalar ratio = nu*R
	static int dtperstep;	// number of dt per control step
	static int H;			// number of steps in horizon
	static double dS;		// duration of a control step = dt*dtperstep
	static double stdv;		// local standard deviation = sqrt(nu/dS)

	// nested class Model used by the sampler to simulate dynamics
	class Model {
	protected:
		vec state;			// [dimX] running state
	public:
		Model() {};
		virtual ~Model() {};

		// replaces the current state
		void setState(const vec& X0) { state = X0; }

		// returns the current state
		const vec getState() const { return state; }

		// Output is the immediate control cost. Input is a control action.
		double immediateControlCost(const vec&) const;

		// Output is the end state reward. Input is a state.
		double endStateReward() const { return immediateStateReward(); };

		// Output is the immediate state reward. Input is a state.
		virtual double immediateStateReward() const = 0;

		// apply control uuu on the current state
		virtual void step(const vec&) = 0;//, const double&);

	};

	// nested class Sampler used by PIController to sample trajectories
	class Sampler {
	public:
		Model *model;			// The dynamical model the sampler uses

		Sampler() : model() {};
		virtual ~Sampler() {};
		
//		vec getState() const { return model.getState(); }

		// Returns state based reward of a rollout
		double runningStateReward(const vec&, const vvec&);

		// Returns the cost of a control sequence.
		double runningControlCost(const vvec&) const;
		
		// used by convertControl:
		const vec predictState(const vec&, const vec&);

    };

public:
	Sampler sampl;

	PIController();
	PIController(
		const int&,
		const int&,
		const int&,
		const int&
	);
	virtual ~PIController();

	void printTime() const;
	
	void plotCurrent(const vec&, const vec&) const;

	void plotSetup() const;

	// The PI-control algorithm, input is a qrsim state, output is qrsim action.
	vvec computeControl(const vvec &);

    // to be implemented in the specific application
    void setModel();

    // to be implemented in the specific application
    void unsetModel();


protected:
	gsl_rng *r;				// Random seed.
	int dimX;				// dimension state
	int dimU;				// dimension control
	int N;					// number of rollouts applied each step
	vvec u_exp;				// [H][dimU] current best, used for exploring
	std::string outfile;				// name of the output .m file

private:
	// QRSim state to our-model state
	vec convertState(const vvec&) const;

	// our-model state + action to QRSim action
	vvec convertControl(const vec&, const vec&);
};

#endif /* PICONTROLLER_H_ */
