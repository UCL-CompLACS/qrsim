classdef Pelican<Steppable
    %PELICAN
    % implementation of the dynamics of a AscTec Pelican quadrotor
    % the parameters are derived from the system identification of one of
    % the UCL quadrotors
    %
    %
    % state X = [px,py,pz,phi,theta,psi,u,v,w,p,q,r,thrust]
    % px,py,pz      [m]     position (NED coordinates)
    % phi,theta,psi [rad]   attitude in Euler angles right-hand ZYX convention
    % u,v,w         [m/s]   velocity in body coordinates
    % p,q,r         [rad/s] rotational velocity  in body coordinates
    % thrust        [N]     rotors thrust
    %
    % controls U = [pt,rl,th,ya,bat]
    % pt  [-0.89..0.89] rad commanded pitch
    % rl  [-0.89..0.89] rad commanded roll
    % th  [0..1] unitless commanded throttle
    % ya  [-4.4,4.4] rad/s commanded yaw velocity
    % bat [9..12] Volts battery voltage
    
    properties (Constant)
        CONTROL_LIMITS = [-0.89,0.89; -0.89,0.89; 0,1; -4.4,4.4; 9,12];
        %UAV_CTRL_2_RAD = deg2rad(0.025);
        %UAV_CTRL_2_RADS = deg2rad(254.760/2047);
        %UAV_THROTTLE_MAX = 4097;
        
        SI_2_UAVCTRL = [-1/deg2rad(0.025);-1/deg2rad(0.025);4097;-1/deg2rad(254.760/2047);1];
        BATTERY_RANGE = [9,12];
        
        % The parameters of the system dynamics are defined in the
        % pelicanODE function
        G = 9.81;
        MASS = 1.68; %this is only for the initial state
    end
    
    properties (Access = public)
        gpsreceiver
        turbulence
        ahars
        meanWind
        turbWind
        graphics
    end
    
    properties
        X
        pseudoX
        a
    end
    
    methods (Sealed)
        function obj = Pelican(objparams)
            % constructs the platform object and initialises its subcomponent
            % The configuration of the type and parameters of the subcomponents are read
            % from the platform config file e.g. pelican_config.m
            %
            obj=obj@Steppable(objparams);
            
            obj.X = [objparams.X(1:6); zeros(6,1); abs(obj.MASS*obj.G)];
            
            %instantiation of sensor and wind objects, with some "manual"
            %type checking
            
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
    end
    
    methods (Sealed,Access=protected)
        function obj = update(obj,U)
            % updates the state of the platform and of its components
            % In turns this 
            % updates turbulence model
            % updates the state of the platform
            % updates local part of gps model
            % updates ahars noise model
            %
            % Note:
            %  this method is called automatically by the step() of the Steppable parent
            %  class and should not be called directly.
            
            global state;
            
            % do scaling of inputs
            US = obj.scaleControls(U);
            
            if (size(U,1)~=5)
                error('a 5 element column vector [-2048..2048;-2048..2048;0..4096;-2048..2048;9..12] is expected as input ');
            end
            
            %turbulence
            obj.turbulence.step(obj.X);
            
            obj.turbWind = obj.turbulence.getLinear(obj.X);
            obj.meanWind = state.environment.wind.getLinear(obj.X);
            
            obj.X(7:9)=obj.X(7:9)+obj.meanWind + obj.turbWind;
            
            % dynamics
            [obj.X obj.a] = ruku2('pelicanODE', obj.X, US, obj.dt);
            
            % AHARS
            obj.ahars.step([]);
            
            %aharsn = obj.ahars.getNoise(obj.X);          
            estimatedAHA = obj.ahars.getMeasurement([obj.X;obj.a]);
            
            % GPS noise
            obj.gpsreceiver.step([]);
            
            estimatedPosNED = obj.gpsreceiver.getMeasurement(obj.X(1:3));
            
            obj.pseudoX = [estimatedPosNED;estimatedAHA(1:3);zeros(3,1);estimatedAHA(4:end)];
            
            obj.graphics.update(obj.X);
        end
        
    end
end

