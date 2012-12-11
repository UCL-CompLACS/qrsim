classdef AHARSPelican<AHARS
    % Simulates the attitude-heading-altitude reference system present on an AscTec Pelican Quadrotor.
    % This class allows to compute estimated (noisy) measurements of orientation, altitude,
    % accelerations and angular velocity of a platform given its noise free state vector.
    % The types of sensors are instantiated according to the configuration parameters
    % passed to the constructor
    %
    % AHARSPelican Methods:
    %   AHARSPelican(objparams) - constructs the object
    %   reset()                 - resets all sensors
    %   setState(X)             - reinitialises the current state and noise
    %
    properties (Access=protected)
        accelerometer;              % accelerometer sensor
        orientationEstimator;       % orientation estimator
        gyroscope;                  % gyroscope sensor
        altimeter;                  % altimeter sensor
    end
    
    methods (Sealed)
        function obj = AHARSPelican(objparams)
            % constructs the object
            %
            % Example:
            %
            %   obj = AHARS(objparams)
            %                   objparams.on - 1 if the object is active
            %                   objparams.gyroscope - gyroscope parameters
            %                   objparams.accelerometer - accelerometer parameters
            %                   objparams.altimeter - altimeter parameters
            %                   objparams.orientationEstimator - orientationEstimator parameters
            %
            
            %we temporarily set dt to the sim time step, we will set
            %it appropriately after initialising the various objects
            objparams.dt = objparams.DT;
            
            obj = obj@AHARS(objparams);
            
            % turn off all sensors if AHARS is not active
            if(objparams.on==0)
                objparams.accelerometer.on = 0;
                objparams.gyroscope.on = 0;
                objparams.altimeter.on = 0;
                objparams.orientationEstimator.on = 0;
            end
            
            %instantiation of sensors with some "manual" type checking
            %if obj.active==0 we instantiate the sensor as their noiseless base class
            
            objparams.accelerometer.DT = objparams.DT;
            objparams.accelerometer.state = objparams.state;
            assert(isfield(objparams,'accelerometer')&&isfield(objparams.accelerometer,'on'),'ahahrspelican:noaccelerometer',...
                'the platform config file must define an accelrometer if not needed set accelrometer.on = 0');
            
            if(objparams.accelerometer.on)
                assert(isfield(objparams.accelerometer,'type'),'ahahrspelican:noaccelerometertype',...
                    'the platform config file must define an accelerometer.type ');
                tmp = feval(objparams.accelerometer.type,objparams.accelerometer);
                if(isa(tmp,'Accelerometer'))
                    obj.accelerometer=tmp;
                else
                    error('params.platform.sensors.ahars.accelerometer.type has to extend the class Accelerometer');
                end
            else
                obj.accelerometer=feval('Accelerometer',objparams.accelerometer);
            end
            
            
            objparams.gyroscope.DT = objparams.DT;
            objparams.gyroscope.state = objparams.state;
            assert(isfield(objparams,'gyroscope')&&isfield(objparams.gyroscope,'on'),'ahahrspelican:nogyroscope',...
                'the platform config file must define an gyroscope if not needed set gyroscope.on = 0');
            
            if(objparams.gyroscope.on)
                assert(isfield(objparams.gyroscope,'type'),'ahahrspelican:nogyroscopetype',...
                    'the platform config file must define an gyroscope.type ');
                tmp = feval(objparams.gyroscope.type, objparams.gyroscope);
                if(isa(tmp,'Gyroscope'))
                    obj.gyroscope=tmp;
                else
                    error('params.platform.sensors.ahars.gyroscope.type has to extend the class Gyroscope');
                end
            else
                obj.gyroscope=feval('Gyroscope',objparams.gyroscope);
            end
            
            objparams.altimeter.DT = objparams.DT;
            objparams.altimeter.state = objparams.state;
            assert(isfield(objparams,'altimeter')&&isfield(objparams.altimeter,'on'),'ahahrspelican:noaltimeter',...
                'the platform config file must define an altimeter if not needed set altimeter.on = 0');
            
            if(objparams.altimeter.on)
                assert(isfield(objparams.altimeter,'type'),'ahahrspelican:noaltimetertype',...
                    'the platform config file must define an altimeter.type ');
                tmp = feval(objparams.altimeter.type, objparams.altimeter);
                if(isa(tmp,'Altimeter'))
                    obj.altimeter=tmp;
                else
                    error('params.platform.sensors.ahars.altimeter.type has to extend the class Altimeter');
                end
            else
                obj.altimeter=feval('Altimeter',objparams.altimeter);
            end
            
            objparams.orientationEstimator.DT = objparams.DT;
            objparams.orientationEstimator.state = objparams.state;
            assert(isfield(objparams,'orientationEstimator')&&isfield(objparams.orientationEstimator,'on'),'ahahrspelican:noorientationestimator',...
                'the platform config file must define an orientationEstimator if not needed set orientationEstimator.on = 0');
            
            if(objparams.orientationEstimator.on)
                assert(isfield(objparams.orientationEstimator,'type'),'ahahrspelican:noorientationestimatortype',...
                    'the platform config file must define an orientationEstimator.type ');
                tmp = feval(objparams.orientationEstimator.type,objparams.orientationEstimator);
                if(isa(tmp,'OrientationEstimator'))
                    obj.orientationEstimator=tmp;
                else
                    error('params.platform.sensors.ahars.orientationEstimator.type has to extend the class OrientationEstimator');
                end
            else
                obj.orientationEstimator=feval('OrientationEstimator',objparams.orientationEstimator);
            end
            
            % now we are dead sure that all the dt are proper, let's init
            % the dt of the ahars
            obj.dt = min([objparams.accelerometer.dt,objparams.gyroscope.dt,...
                objparams.altimeter.dt, objparams.orientationEstimator.dt]);
            
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
            %        eAHA- [~phi,~theta,~psi,~p,~q,~r,~ax,~ay,~az,~h,~hdot];
            %
            %fprintf('get measurement AHARSPelican active=%d\n',obj.active);
            measurementAcceleration = obj.accelerometer.getMeasurement(stateAndAccelerations(end-2:end));
            
            measurementAngularVelocity = obj.gyroscope.getMeasurement(stateAndAccelerations(1:13));
            
            estimatedAltitude = obj.altimeter.getMeasurement(stateAndAccelerations(1:13));
            
            estimatedOrientation = obj.orientationEstimator.getMeasurement(stateAndAccelerations(1:13));
            
            estimatedAHA = [estimatedOrientation;measurementAngularVelocity;...
                measurementAcceleration;estimatedAltitude];
        end
        
        function obj = setState(obj,X)
            % reinitialises the current state and noise
            %
            % Example:
            %
            %   obj.setState(X)
            %       X - platform new state vector [px,py,pz,phi,theta,psi,u,v,w,p,q,r,thrust]
            %           if the length of the X vector is 12, thrust is initialized automatically
            %           if the length of the X vector is 6, all the velocities are set to zero
            %
            
            obj.accelerometer.setState(zeros(3,1));
            obj.gyroscope.setState(X);
            obj.altimeter.setState(X);
            obj.orientationEstimator.setState(X);
            
            obj.bootstrapped = 0;
        end
        
        function obj = reset(obj)
            % resets all the sensors
            %
            % Example:
            %   obj.reset();
            %
            
            obj.accelerometer.reset();
            obj.gyroscope.reset();
            obj.altimeter.reset();
            obj.orientationEstimator.reset();
            
            obj.bootstrapped = obj.bootstrapped +1;
        end
        
    end
    
    methods (Sealed,Access=protected)
        function obj = update(obj, stateAndAccelerations)
            % updates the ahars state
            % Calls an update on accelerometer,gyroscope,altimeter and orientationEstimator
            % Note: this method is called by step() if the time is a multiple of this object dt,
            % therefore it should not be called directly.
            obj.accelerometer.step(stateAndAccelerations(end-2:end));
            obj.gyroscope.step(stateAndAccelerations(1:13));
            obj.altimeter.step(stateAndAccelerations(1:13));
            obj.orientationEstimator.step(stateAndAccelerations(1:13));
        end
    end
end

