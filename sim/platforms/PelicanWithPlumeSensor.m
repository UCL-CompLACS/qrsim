classdef PelicanWithPlumeSensor<Pelican
    % Class that implementatios dynamic and sensors of an AscTec Pelican quadrotor
    % with an onboard plume sensor.
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
    %    setX(X)            - reinitialise the current state and noise
    %    isValid()          - true if the state is valid
    %    getX()             - returns the state (noiseless)
    %    getEX()            - returns the estimated state (noisy)
    %    getEXasX()         - returns the estimated state (noisy) formatted as the noiseless state    
    %    getPlumeSensorOutput() - returns current plume sensor output
    
    properties (Access = protected)
        plumeSensor;       % handle to the plume sensor
        plumeSensorOutput; % last valid measurement from the plume sensor
    end
    
    methods (Access = public)
        function obj = PelicanWithPlumeSensor(objparams)
            % constructs the platform object and initialises its subcomponent
            % The configuration of the type and parameters of the subcomponents are read
            % from the platform config file e.g. pelican_config.m
            %
            % Example:
            %
            %   obj=PelicanWithPlumeSensor(objparams);
            %                objparams.dt - timestep of this object
            %                objparams.on - 1 if the object is active
            %                objparams.aerodynamicturbulence - aerodynamicturbulence parameters
            %                objparams.sensors.ahars - ahrs parameters
            %                objparams.sensors.gpsreceiver - gps receiver parameters
            %                objparams.graphics - graphics parameters
            %                objparams.sensors.plumesensor - plume sensor parameters
            %                objparams.stateLimits - 13 by 2 vector of allowed values of the state
            %                objparams.collisionDistance - distance from any other object that defines a collision
            %                objparams.dynNoise -  standard deviation of the noise dynamics
            %                objparams.state - handle to simulator state
            %
            
            obj=obj@Pelican(objparams);
            
            % plumesensor
            assert(isfield(objparams.sensors,'plumesensor')&&isfield(objparams.sensors.plumesensor,'on'),'pelicanwithplumesensor:noplumesensor',...
                'since the platform is of type PelicanWithPlumeSensor the config file must define the plume sensor parameters');
            objparams.sensors.plumesensor.state = objparams.state;
            if(objparams.sensors.plumesensor.on)
                assert(isfield(objparams.sensors.plumesensor,'type'),'pelicanwithplumesensor:noplumesensortype',...
                'if the plume sensor is on a the platform config file must specify plumesensor.type');
                obj.plumeSensor = feval(objparams.sensors.plumesensor.type,objparams.sensors.plumesensor);    
            else
                obj.plumeSensor = feval('PlumeSensor', objparams.sensors.plumesensor);
            end
        end      
        
        function o = getPlumeSensorOutput(obj)
            % return the last result from the plume sensor, mind that this is
            % updated at the sensor rate
            o = obj.plumeSensorOutput; 
        end    
    end
    
    methods (Access=protected)
        function obj = updateAdditional(obj,~)
            % updates the plume sensor 
            %
            % Note:
            %  this method is called automatically by update() of the
            %  parent class
            %
            
            % plume sensor
            obj.plumeSensor.step(obj.X);
                    
            obj.plumeSensorOutput = obj.plumeSensor.getMeasurement(obj.X);
        end         
                
        function obj = resetAdditional(obj)
            % resets plume sensor subcomponents
            %
            % Example:
            %   obj.reset();
            %
            obj.plumeSensor.reset();
        end 
    end
end

