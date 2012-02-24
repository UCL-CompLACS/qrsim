classdef AerodynamicTurbulenceMILF8785ForTesting<AerodynamicTurbulenceMILF8785

    
    methods  (Sealed,Access=public)
        function obj = AerodynamicTurbulenceMILF8785ForTesting(objparams)
            % constructs the object and sets its main fields
            %
            % Example:
            %
            %   obj=AerodynamicTurbulenceMILF8785(objparams)
            %                objparams.dt - timestep of this object
            %                objparams.on - 1 if the object is active
            %                objparams.W6 - velocity at 6m from ground in m/s
            %                objparams.zOrigin - origin reference Z coord
            %                objparams.direction - main turbulence direction
            %
           
            obj=obj@AerodynamicTurbulenceMILF8785(objparams);
            obj.Vof = 0;
        end
        
        
        function dir = getDirection(obj)
            % reset wind direction if random;
            dir = obj.direction;
        end   
        
        function w6 = getW6(obj)
            % reset wind direction if random;
            w6 = obj.w6;
        end
    end
end

