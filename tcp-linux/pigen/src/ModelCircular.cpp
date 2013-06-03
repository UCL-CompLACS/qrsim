/*
 * ModelCircular.cpp
 *
 *  Created on: Mar 31, 2013
 *      Author: vgomez, Sep Thijssen
 */

#include "PIController.h"

using namespace std;

class ModelCircular : public PIController::Model{
   public:

    double immediateStateReward() const
    {
    	// Immediate state reward of the state X.
    	// Returns the negative of the cost c in this case.
    	double c=0;
    
    	// cost per unit
    	for(int i=0; i<PIController::units; i++)
    	{
    		double speed = sqrt(state[4*i+2]*state[4*i+2] + state[4*i+3]*state[4*i+3]);
    		// penalty for low or high speeds
    		c += exp(speed-3); 		// determines max allowed speed
    		c += exp(-speed+1);		// determines min allowed speed
    
    		// penalty for going to far away
    		double d;
    		d = sqrt(state[4*i+0]*state[4*i+0] + state[4*i+1]*state[4*i+1]);
    		c+= exp(d-4);				// max allowed distance ~= 4
    
    		// penalty for collision
    		for(int j=i+1; j<PIController::units; j++)
    		{	d=0;
    			d+=(state[4*i+0]-state[4*j+0])*(state[4*i+0]-state[4*j+0]);
    			d+=(state[4*i+1]-state[4*j+1])*(state[4*i+1]-state[4*j+1]);
    			if (0.00001 > d) d=0.00001;
    			c+=1/d;
    		}
    	}
    	return -c;
    }   
   
   void step( const vec& A) { 
    	for(int i=0; i<PIController::units; i++) {

		state[4*i+0] += state[4*i+2]*PIController::dt;	//  X position
		state[4*i+1] += state[4*i+3]*PIController::dt;	//  Y position

		state[4*i+2] += A[2*i+0]*PIController::dt;		//  X velocity
		state[4*i+3] += A[2*i+1]*PIController::dt;		//  Y velocity
    	}
    };
};


void PIController::setModel()
{
    sampl.model =new ModelCircular();
};

void PIController::unsetModel()
{
    delete sampl.model;
};
