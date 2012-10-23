classdef BoxArea<Area
    % Defines a simple box shaped empty area in which the platforms can fly
    %
    % BoxArea Methods:
    %    BoxArea(objparams)   - constructs the object
    %    reset()              - does nothing
    %    getOriginUTMCoords() - returns origin
    %    getLimits()          - returns limits
    %           
    
    methods (Sealed,Access=public)
        function obj = BoxArea(objparams)
            % constructs the object
            %
            % Example:
            %
            %   obj=BoxArea(objparams)
            %               objparams.limits - x,y,z limits of the area 
            %               objparams.originutmcoords - structure containing the origin in utm coord
            %               objparams.graphics.type - class type for thegraphics object 
            %                                         (only needed if the 3D displayis active)
            %               objparams.state - handle to the simulator state
            %
            obj=obj@Area(objparams);
            
            if(objparams.graphics.on)
                tmp.limits = objparams.limits;
                tmp.state = objparams.state;
                if(isfield(objparams,'graphics') && isfield(objparams.graphics,'backgroundimage'))
                    tmp.backgroundimage = objparams.graphics.backgroundimage;
                end
                obj.graphics=feval(objparams.graphics.type,tmp);
            end
        end
    end
end
