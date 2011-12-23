classdef Pelican<Steppable
    % Class that implementatios dynamic and sensors of an AscTec Pelican quadrotor
    % The parameters are derived from the system identification of one of
    % the UCL quadrotors
    %
    % Pelican Properties:
    % X   - state = [px;py;pz;phi;theta;psi;u;v;w;p;q;r;thrust]
    %       px,py,pz           [m]     position (NED coordinates)
    %       phi,theta,psi      [rad]   attitude in Euler angles right-hand ZYX convention
    %       u,v,w              [m/s]   velocity in body coordinates
    %       p,q,r              [rad/s] rotational velocity  in body coordinates
    %       thrust             [N]     rotors thrust
    %
    % eX  - estimated state = [\~px;\~py;\~pz;\~phi;\~theta;\~psi;0;0;0;\~p;\~q;\~r;0;\~ax;\~ay;\~az;\~alt]
    %       \~px,\~py,\~pz     [m]     position estimated by GPS (NED coordinates)
    %       \~phi,\~theta,\~psi[rad]   estimated attitude in Euler angles right-hand ZYX convention
    %       0,0,0                      placeholder (the uav does not provide velocity estimation)
    %       \~p,\~q,\~r        [rad/s] measured rotational velocity in body coordinates
    %       0                          placeholder (the uav does not provide thrust estimation)
    %       \~ax,\~ay,\~az     [m/s^2] measured acceleration in body coordinates
    %       alt                [m]     estimated altitude from altimeter NED, POSITIVE UP! 
    % 
    % U   - controls  = [pt,rl,th,ya,bat]
    %       pt  [-0.89..0.89]  [rad]   commanded pitch
    %       rl  [-0.89..0.89]  [rad]   commanded roll
    %       th  [0..1]         unitless commanded throttle
    %       ya  [-4.4,4.4]     [rad/s] commanded yaw velocity
    %       bat [9..12]        [Volts] battery voltage
    %
    % Pelican Methods:
    % obj = Pelican(objparams) - constructs object
    % plotTrajectory(flag)     - enables/disables plotting of the uav trajectory
    %        
    
    properties (Constant)
        CONTROL_LIMITS = [-0.89,0.89; -0.89,0.89; 0,1; -4.4,4.4; 9,12]; %limits of the control inputs       
        SI_2_UAVCTRL = [-1/deg2rad(0.025);-1/deg2rad(0.025);4097;-1/deg2rad(254.760/2047);1]; % conversuion factors 
        BATTERY_RANGE = [9,12]; % range of valid battery values volts
        
        % The parameters of the system dynamics are defined in the
        % pelicanODE function
        G = 9.81;    %  gravity m/s^2
        MASS = 1.68; %  mass of the platform Kg
    end
    
    properties (Access = public)
        gpsreceiver % handle to the gps receiver
        turbulence  % handle to the aerodynamic turbulence
        ahars       % handle to the attitude heading altitude reference system
        graphics    % handle to the quadrotor graphics
        meanWind    % mean wind vector
        turbWind    % turbulence vector 
        a           % linear accelerations in body coordinates [ax;ay;az]
        valid       % the state of the platform is invalid
        stateLimits % 13 by 2 vector of allowed values of the state
        collisionD  % distance from any other object that defines a collision
        dynNoise    % standard deviation of the noise dynamics
    end
    
    properties
        X       % state [px;py;pz;phi;theta;psi;u;v;w;p;q;r;thrust]
        eX      % estimated state  [\~px;\~py;\~pz;\~phi;\~theta;\~psi;0;0;0;\~p;\~q;\~r;0;\~ax;\~ay;\~az;\~alt]
    end
    
    methods (Sealed)
        function obj = Pelican(objparams)
            % constructs the platform object and initialises its subcomponent
            % The configuration of the type and parameters of the subcomponents are read
            % from the platform config file e.g. pelican_config.m
            %
            % Example:
            %
            %   obj=Pelican(objparams);
            %                objparams.dt - timestep of this object
            %                objparams.DT - global simulation timestep
            %                objparams.on - 1 if the object is active
            %                objparams.aerodynamicturbulence - aerodynamicturbulence parameters
            %                objparams.sensors.ahars - ahrs parameters
            %                objparams.sensors.gpsreceiver - gps receiver parameters
            %                objparams.quadrotorgraphics - graphics parameters
            %                objparams.stateLimits - 13 by 2 vector of allowed values of the state
            %                objparams.collisionDistance - distance from any other object that defines a collision
            %                objparams.dynNoise -  standard deviation of the noise dynamics
            %
            obj=obj@Steppable(objparams);
            
            obj.X = [objparams.X(1:6); zeros(6,1); abs(obj.MASS*obj.G)];
            obj.valid = 1;
            
            obj.stateLimits = objparams.stateLimits;
            obj.collisionD = objparams.collisionDistance;
            obj.dynNoise = objparams.dynNoise;
            
            %instantiation of sensor and wind objects, with some "manual" type checking
            
            % WIND
            tmp = feval(objparams.aerodynamicturbulence.type, objparams.aerodynamicturbulence);
            if(isa(tmp,'AerodynamicTurbulence'))
                obj.turbulence = tmp;
            else
                error('c.aerodynamicturbulence.type has to extend the class AerodynamicTurbulence');
            end
            
            % AHARS
            tmp = feval(objparams.sensors.ahars.type,objparams.sensors.ahars);
            if(isa(tmp,'AHARS'))
                obj.ahars = tmp;
            else
                error('c.sensors.ahars.type has to extend the class AHRS');
            end
            
            % GPS
            tmp = feval(objparams.sensors.gpsreceiver.type,objparams.sensors.gpsreceiver);
            if(isa(tmp,'GPSReceiver'))
                obj.gpsreceiver = tmp;
            else
                error('c.sensors.gpsreceiver.type has to extend the class GPSReceiver');
            end
            
            obj.graphics=feval(objparams.quadrotorgraphics.type,objparams.quadrotorgraphics,obj.X);
        end
        
        function obj = plotTrajectory(obj,flag)
            % enables plotting of the uav trajectory
            %
            % Example:
            %   obj.plotTrajectory(flag)
            %       flag - 1 enables 0 disables
            %
            obj.graphics.plotTrajectory(flag);
        end
    end
    
    methods (Sealed,Access=private)
        
        function US = scaleControls(obj,U)
            % scales the controls from SI units to what required by the ODE model
            % The dynamic equations (and the real model) require the following input ranges
            % pt  [-2048..2048] 1=4.36332313e-4 rad = 0.25 deg commanded pitch
            % rl  [-2048..2048] 1=4.36332313e-4 rad = 0.25 deg commanded roll
            % th  [0..4096] 1=4.36332313e-4 rad = 0.25 deg commanded throttle
            % ya  [-2048..2048] 1=2.17109414e-3 rad/s = 0.124394531 deg/s commanded yaw velocity
            % bat [9..12] Volts battery voltage
            %
            if (size(U(:),1)~=5 || sum(U(:)>obj.CONTROL_LIMITS(:,1))~=5) || (sum(U(:)<obj.CONTROL_LIMITS(:,2))~=5),
                error('Pelican:input',['wrong size of control inputs or values not within limits \n'...
                    '\tU = [pt;rl;th;ya;bat] \n\n'...
                    '\tpt  [-0.89..0.89] rad commanded pitch \n'...
                    '\trl  [-0.89..0.89] rad commanded roll \n'...
                    '\tth  [0..1] unitless commanded throttle \n'...
                    '\tya  [-4.4..4.4] rad/s commanded yaw velocity \n'...
                    '\tbat [9..12] Volts battery voltage \n']);
            else
                US = U.*obj.SI_2_UAVCTRL;
            end
        end
        
        function valid = stateIsWithinLimits(obj)
            % returns 0 if the state is out of bounds
            valid =1;
            for i=1:length(obj.X),
                valid = valid || (obj.X(i)<obj.stateLimits(i,1)) ||(obj.X(i)>obj.stateLimits(i,2));
            end    
        end
        
        function coll = inCollision(obj)
            % returns 1 if a collision is occourring
            global state;
            coll = 0;
            for i=1:length(state.platforms),
                if(state.platforms(i) ~= obj)
                    if(norm(state.platforms(i).X(1:3)-obj.X(1:3))< obj.collisionD)
                        coll = 1;
                    end
                end
            end
        end
        
    end
    
    methods (Sealed,Access=protected)
        function obj = update(obj,U)
            % updates the state of the platform and of its components
            % In turns this
            % updates turbulence model
            % updates the state of the platform applying controls
            % updates local part of gps model
            % updates ahars noise model
            % updates the graphics
            %
            % Note:
            %  this method is called automatically by the step() of the Steppable parent
            %  class and should not be called directly.
            %
            global state;
            
            if(obj.valid)
                
                % do scaling of inputs
                US = obj.scaleControls(U);
                
                if (size(U,1)~=5)
                    error('a 5 element column vector [-2048..2048;-2048..2048;0..4096;-2048..2048;9..12] is expected as input ');
                end
                
                %turbulence
                obj.meanWind = state.environment.wind.getLinear(obj.X);
                
                obj.turbulence.step([obj.X;obj.meanWind]);                
                obj.turbWind = obj.turbulence.getLinear(obj.X);
                                
                accNoise = obj.dynNoise.*randn(state.rStream,6,1);
                
                % dynamics
                [obj.X obj.a] = ruku2('pelicanODE', obj.X, [US;obj.meanWind + obj.turbWind; obj.MASS; accNoise], obj.dt);
                
                
                if(obj.stateIsWithinLimits() && ~obj.inCollision())
                    
                    % AHARS
                    obj.ahars.step([obj.X;obj.a]);
                    
                    estimatedAHA = obj.ahars.getMeasurement([obj.X;obj.a]);
                    
                    % GPS
                    obj.gpsreceiver.step(obj.X);
                    
                    estimatedPosNED = obj.gpsreceiver.getMeasurement(obj.X);
                    
                    %return values
                    obj.eX = [estimatedPosNED;estimatedAHA(1:3);zeros(3,1);...
                        estimatedAHA(4:6);0;estimatedAHA(7:end)];
                    
                    % graphics
                    obj.graphics.update(obj.X);
                    
                    obj.valid = 1;
                else
                    obj.eX = nan(17,1);
                    obj.valid=0;
                end
                
            end
        end
        
    end
end

