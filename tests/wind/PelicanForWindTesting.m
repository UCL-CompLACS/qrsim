classdef PelicanForWindTesting<Pelican
    % Class that extend Pelican to save wind data useful for wind testing
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
    methods (Access = public)
        function obj = PelicanForWindTesting(objparams)
            % simply calls the Pelican constructor
            %
            obj=obj@Pelican(objparams);            
        end
        
        function aerodynamicTurbulence = getAerodynamicTurbulence(obj)
            aerodynamicTurbulence = obj.aerodynamicTurbulence;
        end
    end
        
    methods (Sealed,Access=protected)
        function obj = update(obj,U)
            % updates the state of the platform and of its components
            % This is a clone of the Pelican update method with additional harness to write out data logs 
            %
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
            global windstate;
            
            if(obj.valid)
                
                % do scaling of inputs
                US = obj.scaleControls(U);
                
                if (size(U,1)~=5)
                    error('a 5 element column vector [-2048..2048;-2048..2048;0..4096;-2048..2048;9..12] is expected as input ');
                end
                
                %wind and turbulence this closely mimic the Simulink example "Lightweight Airplane Design"
                % asbSkyHogg/Environment/WindModels
                windstate.i=windstate.i+1;
                windstate.simin(windstate.i,:)=[obj.simState.t-obj.dt,mToFt(-obj.X(3)),mToFt(norm(obj.X(7:9))),obj.X(4),obj.X(5),obj.X(6)];
                
                meanWind = obj.simState.environment.wind.getLinear(obj.X);                
                windstate.meanwindfts(windstate.i,:)=mToFt(meanWind');
                
                obj.aerodynamicTurbulence.step(obj.X);
                turbWind = obj.aerodynamicTurbulence.getLinear(obj.X);                               
                windstate.turbwindfts(windstate.i,:)=mToFt(turbWind');
                
                accNoise = obj.dynNoise.*[randn(obj.simState.rStreams{obj.prngIds(1)},1,1);
                                          randn(obj.simState.rStreams{obj.prngIds(2)},1,1);
                                          randn(obj.simState.rStreams{obj.prngIds(3)},1,1);
                                          randn(obj.simState.rStreams{obj.prngIds(4)},1,1);
                                          randn(obj.simState.rStreams{obj.prngIds(5)},1,1);
                                          randn(obj.simState.rStreams{obj.prngIds(6)},1,1)];
            
                % dynamics
                [obj.X obj.a] = ruku2('pelicanODE', obj.X, [US;meanWind + turbWind; obj.MASS; accNoise], obj.dt);
                
                
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
                    
                    obj.updateAdditional(U);
                    
                    % graphics      
                    if(obj.graphicsOn)
                        obj.graphics.update(obj.X);
                        obj.updateAdditionalGraphics(obj.X);
                    end
                    
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

