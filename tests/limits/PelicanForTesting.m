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
    
end

