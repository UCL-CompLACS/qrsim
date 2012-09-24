classdef PelicanWithCamera<Pelican
    % Class that implementatios dynamic and sensors of an AscTec Pelican quadrotor
    % with an onboard visual camera.
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
    %
    
    properties (Access = protected)
        camera;      % handle to the camera
        cameraOutput; % last valid measurement from the camera
    end
    
    methods (Access = public)
        function obj = PelicanWithCamera(objparams)
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
            %                objparams.camera - camera parameters
            %                objparams.stateLimits - 13 by 2 vector of allowed values of the state
            %                objparams.collisionDistance - distance from any other object that defines a collision
            %                objparams.dynNoise -  standard deviation of the noise dynamics
            %                objparams.state - handle to simulator state
            %
            
            obj=obj@Pelican(objparams);
            
            % camera
            assert(isfield(objparams,'camera')&&isfield(objparams.camera,'on'),'pelican:nocamera',...
                'the platform config file must define a camera parameter');
            obj.camera = feval(objparams.sensors.camera.type,objparams.sensors.camera);           
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
            obj.camera.reset();
            obj.graphics.reset();
            obj.valid = 1;
        end        
        
        function o = getCameraOutput(obj)
            % return the last result from the camera, mind that this is
            % updated on at the camera frame rate
            o = obj.cameraOutput; 
        end    
    end
    
    methods (Access=protected)
        function obj = update(obj,U)
            % updates the state of the platform and of its components
            %
            % In turns this:
            %  updates turbulence model
            %  updates the state of the platform applying controls
            %  updates local part of gps model
            %  updates ahars noise model
            %  updates the graphics
            %
            % Note:
            %  this method is called automatically by the step() of the Steppable parent
            %  class and should not be called directly.
            %
            
            if(obj.valid)
                
                % do scaling of inputs
                US = obj.scaleControls(U);
                
                if (size(U,1)~=5)
                    error('a 5 element column vector [-2048..2048;-2048..2048;0..4096;-2048..2048;9..12] is expected as input ');
                end
                
                %wind and turbulence this closely mimic the Simulink example "Lightweight Airplane Design"
                % asbSkyHogg/Environment/WindModels
                meanWind = obj.simState.environment.wind.getLinear(obj.X);
                
                obj.aerodynamicTurbulence.step(obj.X);
                turbWind = obj.aerodynamicTurbulence.getLinear(obj.X);
                    
                accNoise = obj.dynNoise.*[randn(obj.simState.rStreams{obj.prngIds(1)},1,1);
                                          randn(obj.simState.rStreams{obj.prngIds(2)},1,1);
                                          randn(obj.simState.rStreams{obj.prngIds(3)},1,1);
                                          randn(obj.simState.rStreams{obj.prngIds(4)},1,1);
                                          randn(obj.simState.rStreams{obj.prngIds(5)},1,1);
                                          randn(obj.simState.rStreams{obj.prngIds(6)},1,1)];
                
                % dynamics
                [obj.X obj.a] = ruku2('pelicanODE', obj.X, [US;meanWind + turbWind; obj.MASS; accNoise], obj.dt);
                
                if(isreal(obj.X)&& obj.thisStateIsWithinLimits(obj.X) && ~obj.inCollision())
                    
                    % AHARS
                    obj.ahars.step([obj.X;obj.a]);
                    
                    estimatedAHA = obj.ahars.getMeasurement([obj.X;obj.a]);
                    
                    % GPS
                    obj.gpsreceiver.step(obj.X);
                    
                    estimatedPosNED = obj.gpsreceiver.getMeasurement(obj.X);
                    
                    %return values
                    obj.eX = [estimatedPosNED(1:3);estimatedAHA(1:3);zeros(3,1);...
                        estimatedAHA(4:6);0;estimatedAHA(7:10);estimatedPosNED(4:5);estimatedAHA(11)];
                                                            
                    % camera
                    obj.camera.step(obj.X);
                    
                    obj.cameraOutput = obj.camera.getMeasurement(obj.X);
                    
                    % graphics
                    obj.graphics.update(obj.X);
                    
                    obj.valid = 1;
                else
                    obj.eX = nan(20,1);
                    obj.valid=0;
                    
                    obj.printStateNotValidError();
                end                
            end
        end        
    end
end

