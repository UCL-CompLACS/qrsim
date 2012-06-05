classdef PelicanForTesting<Pelican
    %PELICANFORTESTING pelican class with a bunch of methods useful for testing
    
    methods (Sealed,Access=public)
        function obj=PelicanForTesting(objparams)
           obj = obj@Pelican(objparams); 
        end     
        
        function ahars = getAHARS(obj)
            ahars = obj.ahars;
        end
        
        function gpsreceiver = getGPSReceiver(obj)
            gpsreceiver = obj.gpsreceiver;
        end
        
        function graphics = getGraphics(obj)
            graphics = obj.graphics;
        end        
                
        function aerodynamicTurbulence = getAerodynamicTurbulence(obj)
            aerodynamicTurbulence = obj.aerodynamicTurbulence;
        end
        
        function limits = getStateLimits(obj)
           limits = obj.stateLimits;            
        end
                        
        function a = getA(obj)
           a = obj.a;            
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
                [obj.X obj.a] = ruku2('pelicanODEnoDrag', obj.X, [US;meanWind + turbWind; obj.MASS; accNoise], obj.dt);
                
                
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
                    
                    obj.printStateNotValidError();
                end                
            end
        end        
    end
    
end

