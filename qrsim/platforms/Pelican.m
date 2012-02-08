classdef Pelican<Steppable & Platform
    % Class that implementatios dynamic and sensors of an AscTec Pelican quadrotor
    % The parameters are derived from the system identification of one of
    % the UCL quadrotors
    %
    % Pelican Properties:
    % X   - state = [px;py;pz;phi;theta;psi;u;v;w;p;q;r;thrust]
    %       px,py,pz         [m]     position (NED coordinates)
    %       phi,theta,psi    [rad]   attitude in Euler angles right-hand ZYX convention
    %       u,v,w            [m/s]   velocity in body coordinates
    %       p,q,r            [rad/s] rotational velocity  in body coordinates
    %       thrust           [N]     rotors thrust
    %
    % eX  - estimated state = [~px;~py;~pz;~phi;~theta;~psi;0;0;0;~p;~q;~r;0;~ax;~ay;~az;
    %                          ~h;~pxdot;~pydot;~hdot]
    %       ~px,~py,~pz      [m]     position estimated by GPS (NED coordinates)
    %       ~phi,~theta,~psi [rad]   estimated attitude in Euler angles right-hand ZYX convention
    %       0,0,0                    placeholder (the uav does not provide velocity estimation)
    %       ~p,~q,~r         [rad/s] measured rotational velocity in body coordinates
    %       0                        placeholder (the uav does not provide thrust estimation)
    %       ~ax,~ay,~az      [m/s^2] measured acceleration in body coordinates
    %       ~h               [m]     estimated altitude from altimeter NED, POSITIVE UP!
    %       ~pxdot           [m/s]   x velocity from GPS (NED coordinates)
    %       ~pydot           [m/s]   y velocity from GPS (NED coordinates)
    %       ~hdot            [m/s]   altitude rate from altimeter (NED coordinates)
    %
    % U   - controls  = [pt,rl,th,ya,bat]
    %       pt  [-0.89..0.89]  [rad]   commanded pitch
    %       rl  [-0.89..0.89]  [rad]   commanded roll
    %       th  [0..1]         unitless commanded throttle
    %       ya  [-4.4,4.4]     [rad/s] commanded yaw velocity
    %       bat [9..12]        [Volts] battery voltage
    %
    % Pelican Methods:
    %    Pelican(objparams) - constructs object
    %    reset()            - resets all the platform subcomponents
    %    setState(state)    - reinitialise the current state and noise
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
        gpsreceiver; % handle to the gps receiver
        aerodynamicTurbulence;  % handle to the aerodynamic turbulence
        ahars ;      % handle to the attitude heading altitude reference system
        graphics;    % handle to the quadrotor graphics
        meanWind;    % mean wind vector
        turbWind;    % turbulence vector
        a;           % linear accelerations in body coordinates [ax;ay;az]
        collisionD;  % distance from any other object that defines a collision
        dynNoise;    % standard deviation of the noise dynamics
    end
    
    properties
        stateLimits; % 13 by 2 vector of allowed values of the state
        X;           % state [px;py;pz;phi;theta;psi;u;v;w;p;q;r;thrust]
        eX ;         % estimated state  [~px;~py;~pz;~phi;~theta;~psi;0;0;0;~p;~q;~r;0;~ax;~ay;~az;~h;~pxdot;~pydot;~hdot]
        valid;       % the state of the platform is invalid
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
            %                objparams.on - 1 if the object is active
            %                objparams.aerodynamicturbulence - aerodynamicturbulence parameters
            %                objparams.sensors.ahars - ahrs parameters
            %                objparams.sensors.gpsreceiver - gps receiver parameters
            %                objparams.graphics - graphics parameters
            %                objparams.stateLimits - 13 by 2 vector of allowed values of the state
            %                objparams.collisionDistance - distance from any other object that defines a collision
            %                objparams.dynNoise -  standard deviation of the noise dynamics
            %
            
            obj=obj@Platform(objparams);
            obj=obj@Steppable(objparams);
            
            assert(isfield(objparams,'stateLimits'),'pelican:nostatelimits',...
                'the platform config file must define the stateLimits parameter');
            obj.stateLimits = objparams.stateLimits;
            
            assert(isfield(objparams,'collisionDistance'),'pelican:nocollisiondistance',...
                'the platform config file must define the collisionDistance parameter');
            obj.collisionD = objparams.collisionDistance;
            
            assert(isfield(objparams,'dynNoise'),'pelican:nodynnoise',...
                'the platform config file must define the dynNoise parameter');
            obj.dynNoise = objparams.dynNoise;
            
            %instantiation of sensor and wind objects, with some "manual" type checking
            
            % TURBULENCE
            objparams.aerodynamicturbulence.DT = objparams.DT;
            objparams.aerodynamicturbulence.dt = objparams.dt;
            if(objparams.aerodynamicturbulence.on)
                
                assert(isfield(objparams.aerodynamicturbulence,'type'),'pelican:noaerodynamicturbulencetype',...
                    'the platform config file must define an aerodynamicturbulence.type ');
                tmp = feval(objparams.aerodynamicturbulence.type, objparams.aerodynamicturbulence);
                if(isa(tmp,'AerodynamicTurbulence'))
                    obj.aerodynamicTurbulence = tmp;
                else
                    error('c.aerodynamicturbulence.type has to extend the class AerodynamicTurbulence');
                end
            else
                obj.aerodynamicTurbulence = feval('AerodynamicTurbulence', objparams.aerodynamicturbulence);
            end
            
            % AHARS
            assert(isfield(objparams.sensors,'ahars')&&isfield(objparams.sensors.ahars,'on'),'pelican:noahars',...
                'the platform config file must define an ahars');
            objparams.sensors.ahars.DT = objparams.DT;
            assert(isfield(objparams.sensors.ahars,'type'),'pelican:noaharstype',...
                'the platform config file must define an ahars.type');
            tmp = feval(objparams.sensors.ahars.type,objparams.sensors.ahars);
            if(isa(tmp,'AHARS'))
                obj.ahars = tmp;
            else
                error('c.sensors.ahars.type has to extend the class AHRS');
            end
            
            % GPS
            assert(isfield(objparams.sensors,'gpsreceiver')&&isfield(objparams.sensors.gpsreceiver,'on'),'pelican:nogpsreceiver',...
                'the platform config file must define a gps receiver if not needed set gpsreceiver.on = 0');
            objparams.sensors.gpsreceiver.DT = objparams.DT;
            if(objparams.sensors.gpsreceiver.on)
                assert(isfield(objparams.sensors.gpsreceiver,'type'),'pelican:nogpsreceivertype',...
                    'the platform config file must define a gpsreceiver.type');
                tmp = feval(objparams.sensors.gpsreceiver.type,objparams.sensors.gpsreceiver);
                if(isa(tmp,'GPSReceiver'))
                    obj.gpsreceiver = tmp;
                else
                    error('c.sensors.gpsreceiver.type has to extend the class GPSReceiver');
                end
            else
                obj.gpsreceiver = feval('GPSReceiver',objparams.sensors.gpsreceiver);
            end
            
            % GRAPHICS
            assert(isfield(objparams,'graphics')&&isfield(objparams.graphics,'on'),'pelican:nographics',...
                'the platform config file must define a graphics parameter if not needed set graphics.on = 0');
            objparams.graphics.DT = objparams.DT;
            if(objparams.graphics.on)
                assert(isfield(objparams.graphics,'type'),'pelican:nographicstype',...
                    'the platform config file must define a graphics.type');
                obj.graphics=feval(objparams.graphics.type,objparams.graphics,objparams.X);
            else
                obj.graphics=feval('QuadrotorGraphics',objparams.graphics,objparams.X);
            end
        end
        
        function obj = setState(obj,X)
            % reinitialise the current state and noise
            %
            % Example:
            %
            %   obj.setState(X)
            %       X - platform new state vector [px,py,pz,phi,theta,psi,u,v,w,p,q,r,thrust]
            %           if the length of the X vector is 12, thrust is initialized automatically
            %           if the length of the X vector is 6, all the velocities are set to zero
            global state;
            
            assert((size(X,1)==6)||(size(X,1)==12)||(size(X,1)==13),'pelican:wrongsetstate',...
                'setState() on a pelican object requires an input of length 6, 12 or 13 instead we have %d',size(X,1));

            assert(obj.thisStateIsWithinLimits(X),'pelican:settingoobstate',...
                'the state passed through setState() is not valid (i.e. out of limits)');
            
            if(size(X,1)==6)
                X = [X;zeros(6,1)];
            end
            
            if(size(X,1)==12)
                X = [X;abs(obj.MASS*obj.G)];
            end
            
            obj.X = X;
            
            % set things
            obj.gpsreceiver.setState(X);
            obj.ahars.setState(X);
            
            obj.meanWind = state.environment.wind.getLinear(obj.X);
            obj.aerodynamicTurbulence.setState([obj.X;obj.meanWind]);
            obj.turbWind = obj.aerodynamicTurbulence.getLinear(obj.X);
            
            obj.a  = zeros(3,1);
            
            % get measurements
            estimatedAHA = obj.ahars.getMeasurement([obj.X;obj.a]);
            estimatedPosNED = obj.gpsreceiver.getMeasurement(obj.X);
            
            obj.eX = [estimatedPosNED(1:3);estimatedAHA(1:3);zeros(3,1);...
                estimatedAHA(4:6);0;estimatedAHA(7:10);estimatedPosNED(4:5);estimatedAHA(11)];
            
            obj.valid = 1;
            
            % clean the trajectory plot if any
            obj.graphics.reset();
        end
        
        function obj = reset(obj)
            % resets all the platform subcomponents
            %
            % Example:
            %   obj.reset();
            %
            obj.gpsreceiver.reset();
            obj.aerodynamicTurbulence.reset();
            obj.ahars.reset();
            obj.graphics.reset();
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
            assert(size(U(:),1)==5 && all(U>=obj.CONTROL_LIMITS(:,1)) && all(U<=obj.CONTROL_LIMITS(:,2)),...
                'pelican:inputoob',['wrong size of control inputs or values not within limits \n',...
                '\tU = [pt;rl;th;ya;bat] \n\n',...
                '\tpt  [-0.89..0.89] rad commanded pitch \n',...
                '\trl  [-0.89..0.89] rad commanded roll \n',...
                '\tth  [0..1] unitless commanded throttle \n',...
                '\tya  [-4.4..4.4] rad/s commanded yaw velocity \n',...
                '\tbat [9..12] Volts battery voltage \n']);
            
            US = U.*obj.SI_2_UAVCTRL;
        end
        
        function valid = thisStateIsWithinLimits(obj,X)
            % returns 0 if the state is out of bounds
            to = min(size(X,1),size(obj.stateLimits,1));
            
            valid = all(X(1:to)>=obj.stateLimits(1:to,1)) && all(X(1:to)<=obj.stateLimits(1:to,2));
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
                
                obj.aerodynamicTurbulence.step([obj.X;obj.meanWind]);
                obj.turbWind = obj.aerodynamicTurbulence.getLinear(obj.X);
                
                accNoise = obj.dynNoise.*randn(state.rStream,6,1);
                
                % dynamics
                [obj.X obj.a] = ruku2('pelicanODE', obj.X, [US;obj.meanWind + obj.turbWind; obj.MASS; accNoise], obj.dt);
                
                
                if(obj.thisStateIsWithinLimits(obj.X) && ~obj.inCollision())
                    
                    % AHARS
                    obj.ahars.step([obj.X;obj.a]);
                    
                    estimatedAHA = obj.ahars.getMeasurement([obj.X;obj.a]);
                    
                    % GPS
                    obj.gpsreceiver.step(obj.X);
                    
                    estimatedPosNED = obj.gpsreceiver.getMeasurement(obj.X);
                    
                    %return values
                    obj.eX = [estimatedPosNED(1:3);estimatedAHA(1:3);zeros(3,1);...
                        estimatedAHA(4:6);0;estimatedAHA(7:10);estimatedPosNED(4:5);estimatedAHA(11)];
                    
                    % graphics
                    obj.graphics.update(obj.X);
                    
                    obj.valid = 1;
                else
                    obj.eX = nan(20,1);
                    obj.valid=0;
                end
                
            end
        end
        
    end
end

