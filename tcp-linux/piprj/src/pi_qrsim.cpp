//============================================================================
// Name        : pi_qrsim.cpp
// Author      : Vicenç Gomez
// Version     :
// Copyright   : 
// Description : Hello World in C++, Ansi-style
//============================================================================

#include "PIController.h"
#include <QRSimTCPClient.h>
#include <string>
#include <boost/property_tree/xml_parser.hpp>
#include <boost/property_tree/ptree.hpp>
#include <boost/foreach.hpp> 
#include <iostream>
#include <list>

using namespace std;

int main(int argc, char *argv[]) {

    if (argc!=2)
        cout << "Usage ./pi_qrsim xml_file" << endl;
    else {
    	try {
    		ifstream is(argv[1]);
    		// read parameters from xml file
    		using boost::property_tree::ptree;
    		ptree pt;
    		if (!is.is_open()) cout << "file not found" << endl;
    		else {
    			read_xml(is, pt);
    
    			// task parameters
    			string ip = pt.get<string>("ip");
    			int port = pt.get<int>("port");
    			string taskfile = pt.get<string>("taskfile");
    			double dt = pt.get<double>("dt");
    			int units = pt.get<int>("units");
    			double R = pt.get<double>("R");
    			int dtperstep = pt.get<int>("dtperstep");
    			int H = pt.get<int>("H");
    			double nu = pt.get<double>("nu");
    			double T = pt.get<double>("T");
    			int seed = pt.get<int>("seed");
    			int N = pt.get<int>("N");
    			int dimUAVx = pt.get<int>("dimUAVx");
    			int dimUAVu = pt.get<int>("dimUAVu");
    
    			cout << "Connecting to " << ip.c_str() << ":" << port << endl;
    
    		//	GOOGLE_PROTOBUF_VERIFY_VERSION;
    
    			QRSimTCPClient c;
    			int numErrors = 0;
    			c.connectTo(ip.c_str(), port);
    
    			vvec X_qrsim,eX;
    			cout << "QRSIM init test" << endl;
    			cout.flush();
    			double dt_qrsim;
    			int units_qrsim;
    			bool err = c.init(taskfile, X_qrsim, eX, dt_qrsim, units_qrsim, true);
    			if (err) cout << taskfile << " initialized" << endl;
    			double dS = dt*dtperstep;
    			int dtperstep_qrsim = int(dS/dt_qrsim);
    			double dS_qrsim = dt_qrsim*dtperstep_qrsim;
    			
    			// Check for mismatches in Task0.m and pi_qrsim.xml
    			if (dS != dS_qrsim) {	
    				std::cout << "WARNING, mismatch in dS.\n dS (model) = " << dS <<"\n dS (QRsim) = " << dS_qrsim << std::endl;
    			}			
    			if (units != units_qrsim) {	
    				std::cout << "WARNING, mismatch in number of UAV.\n units (model) = " << units <<"\n units (QRsim) = " << units_qrsim << std::endl;
    				std::cout << "Setting units (model) to units (QRsim)...\n";
    				units = units_qrsim;
    			}
    			
    
    			// initialize static variables
    			PIController::dt = dt;			
    			PIController::units = units;		
    			PIController::R = R;
    			PIController::nu = nu;
    			PIController::lambda = R*nu;
    			PIController::dtperstep = dtperstep;
    			PIController::H = H;
    			PIController::dS = dt*dtperstep;
    			PIController::stdv = sqrt(nu/dS);
    			
    
    			// Initial state X should be input as well (don't forget tpo convert)
    			// create instance of PIController
    			PIController pi(
    				dimUAVx,
    				dimUAVu,
    				seed,
    				N
    			);
    
    			////////////////////////////////
    
    			int nsteps = (int)((T/dt)/(double)dtperstep);
    			for (int t=0; t<nsteps; t++) {
    				vvec A_qrsim = pi.computeControl(X_qrsim);
    				err = c.stepVel(dS_qrsim, A_qrsim, X_qrsim, eX);
    				if (err)
    					std::cout << "[PASSED]" << std::endl;
    				else {
    					std::cout << "[FAILED]" << std::endl;
    					numErrors++;
    				}
    				cout << t << " of "<< nsteps << endl;
    			}
    			err = c.quit();
    			if (err)
    				std::cout << "quitting..." << std::endl;
    			else
    				std::cout << "not able to quit!" << std::endl;
    			cout << "END" << endl;
    		}
    
    	} catch (int e) {
    		cout << "Exception " << e << endl;
    	}
    }

	return 0;

}
