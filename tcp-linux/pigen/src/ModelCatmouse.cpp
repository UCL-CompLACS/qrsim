/*
 * ModelCatmouse.cpp
 *
 *  Created on: Mar 31, 2013
 *      Author: vgomez, Sep Thijssen
 */

#include "PIController.h"

using namespace std;

class ModelCatmouse : public PIController::Model{
   public:

    double immediateStateReward() const
    {
    	// Immediate state reward of the state.
    	// Returns the negative of the cost c in this case.
    	double d,c = 0;
    
    	// cost per unit
    	for(int i=0; i<PIController::units; i++)
    	{
    		if (i != PIController::units-1) { // i.e. not the mouse
    			double speed = sqrt(state[4*i+2]*state[4*i+2] + state[4*i+3]*state[4*i+3]);
    			// penalty for low or high speeds
    			c += exp(speed-5); 		// determines max allowed speed
    			c += exp(-speed+0);		// determines min allowed speed
    		}
    		
    		// penalty for going too far away
    		d = sqrt(state[4*i+0]*state[4*i+0] + state[4*i+1]*state[4*i+1]);
    		if (i == PIController::units-1) { // i.e. the nouse
    			c += d;
    		}
    		else c += exp(d-6);		// max allowed distance 
    
    		// penalty for relative distances
    		for(int j=i+1; j<PIController::units; j++)
    		{	d = 0;
    			d += (state[4*i+0]-state[4*j+0])*(state[4*i+0]-state[4*j+0]);
    			d += (state[4*i+1]-state[4*j+1])*(state[4*i+1]-state[4*j+1]);
    			if (0.00001 > d) d = 0.00001;
    			c+=1/d;		// collision penalty
    			if (j == PIController::units-1) { 	// i.e. j is mouse
    				c += d; 			// cost cat i for distance to mouse
    			}	
    		}
    	}
    	return -c;
    }

       
   
   void step( const vec& A) {
 	
    	// mouse :
    	double dx,dy,DX,DY,d,speed;
    	DX=DY=0;
    	for(int i=0; i<PIController::units-1; i++) {
    		dx = state[4*PIController::units-4] - state[4*i+0];
    		dy = state[4*PIController::units-3] - state[4*i+1];
    		d = dx*dx+dy*dy;	// distance to cat
    		DX += dx/d;			// X away from cat inv proportional to distance
    		DY += dy/d;			// Y away from cat inv proportional to distance
    	}
    	speed = sqrt(DX*DX+DY*DY); // speed of mouse
    	// The speed of the mouse will be capped at max_speed.
    	double max_speed = 1;
    	if (speed > max_speed) {	
    		DX *= max_speed/speed;
    		DY *= max_speed/speed;
    	}
    	state[4*PIController::units-2] = DX;	// mouse speed X direction
    	state[4*PIController::units-1] = DY;	// mouse speed Y direction
    	state[4*PIController::units-4] += state[4*PIController::units-2]*PIController::dt;	//  X position
    	state[4*PIController::units-3] += state[4*PIController::units-1]*PIController::dt;	//  Y position
    	
    	// cats :
    	for(int i=0; i<PIController::units-1; i++) {
    
    		state[4*i+0] += state[4*i+2]*PIController::dt;	//  X position
    		state[4*i+1] += state[4*i+3]*PIController::dt;	//  Y position
    
    		state[4*i+2] += A[2*i+0]*PIController::dt;		//  X velocity
    		state[4*i+3] += A[2*i+1]*PIController::dt;		//  Y velocity
    
    	}
    }      
        
};


void PIController::setModel()
{
    sampl.model = new ModelCatmouse();
};

void PIController::unsetModel()
{
    delete sampl.model;
};

