classdef AHARSPelican<AHARS
    % Simulates the attitude-heading-altitude reference system present on an AscTec Pelican Quadrtor.
    % This class allows to compute estimated (noisy) measurements of orientation, altitude, 
    % accelerations and angular velocity of a platform given its noise free state vector. 
    % The types of sensors are instantiated according to the configuration parameters
    % passed to the constructor
    %
    % AHARSPelican Methods:
    %   obj=AHARSPelican(objparams) - constructs the object 
    %
    properties (Access=private)
        accelerometer              % accelerometer sensor
        orientationEstimator       % orientation estimator
        gyroscope                  % gyroscope sensor
        altimeter                  % altimeter sensor
    end
    
    methods (Sealed)                
        function obj = AHARSPelican(objparams)       
            % constructs the object
            %
            % Example:
            %
            %   obj = AHARS(objparams)
            %       objparams - configuration parameters 
            %                   objparams.on - 1 if active
            %                   objparams.dt - object's timestep
            %                   objparams.ahars - ahars parameters
            %                   objparams.gyroscope - gyroscope parameters
            %                   objparams.accelerometer - accelerometer parameters
            %                   objparams.altimeter - altimeter parameters
            %
            objparams.dt = min([objparams.accelerometer.dt,objparams.gyroscope.dt,...
                           objparams.altimeter.dt, objparams.orientationEstimator.dt]);
                       
            % useless but expected by superclass
            objparams.seed = 0;
            
            obj = obj@AHARS(objparams);
            
            % turn off sensors if AHARS is not active
            if(obj.active==0)
                objparams.accelerometer.on = 0;
                objparams.gyroscope.on = 0;
                objparams.altimeter.on = 0;
                objparams.orientationEstimator.on = 0;
            end    
                      
            %instantiation of sensors with some "manual" type checking
            %even if obj.active==0 we still need to instantiate the sensor
            %they will simply behave as "transparent"
            
            tmp = feval(objparams.accelerometer.type,objparams.accelerometer);            
            if(isa(tmp,'Accelerometer'))
                obj.accelerometer=tmp;
            else
                error('params.platform.sensors.ahars.accelerometer.type has to extend the class Accelerometer');
            end
            
            tmp = feval(objparams.gyroscope.type, objparams.gyroscope);
            if(isa(tmp,'Gyroscope'))
                obj.gyroscope=tmp;
            else
                error('params.platform.sensors.ahars.gyroscope.type has to extend the class Gyroscope');
            end
                        
            tmp = feval(objparams.altimeter.type, objparams.altimeter);
            if(isa(tmp,'Altimeter'))
                obj.altimeter=tmp;
            else
                error('params.platform.sensors.ahars.altimeter.type has to extend the class Altimeter');
            end
            
            tmp = feval(objparams.orientationEstimator.type,objparams.orientationEstimator);                                         
            if(isa(tmp,'OrientationEstimator'))
                obj.orientationEstimator=tmp;
            else
                error('params.platform.sensors.ahars.orientationEstimator.type has to extend the class OrientationEstimator');
            end
        end
        
        function estimatedAHA = getMeasurement(obj,stateAndAccelerations)
            % returns the estimated attitude, linear acceleration, agular velocity and altitude
            % The estimate are produced from stateAndAccelerations by calling getMeasurement()
            % on each of the sensor that composes the ahars. See specific sensor for details.
            %
            % Example:
            %   eAHA = obj.ahars.getMeasurement([X;a]);
            %        X   - platform noise free state vector [px,py,pz,phi,theta,psi,u,v,w,p,q,r,thrust]
            %        a   - 3 by 1 vector of noise free acceleration in body frame [ax,ay,az] m/s^2
            %        eAHA- [\~phi,\~theta,\~psi,\~p,\~q,\~r,\~ax,\~ay,\~az,\~h];
            %
            measurementAcceleration = obj.accelerometer.getMeasurement(stateAndAccelerations(end-2:end));
        
            measurementAngularVelocity = obj.gyroscope.getMeasurement(stateAndAccelerations(1:13));
       
            estimatedAltitude = obj.altimeter.getMeasurement(stateAndAccelerations(1:13));
        
            estimatedOrientation = obj.orientationEstimator.getMeasurement(stateAndAccelerations(1:13));
            
            estimatedAHA = [estimatedOrientation;measurementAngularVelocity;...
                            measurementAcceleration;estimatedAltitude;];
        end
    end    
        
    methods (Sealed,Access=protected)
        function obj = update(obj, ~)    
            % updates the ahars state
            % Calls an update on accelerometer,gyroscope,altimeter and orientationEstimator
            % Note: this method is called by step() if the time is a multiple of this object dt,
            % therefore it should not be called directly. 
            obj.accelerometer.step([]);
            obj.gyroscope.step([]);
            obj.altimeter.step([]);
            obj.orientationEstimator.step([]);                        
        end
    end    
end

