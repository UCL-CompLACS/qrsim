classdef PlumeArea<Area
    % Defines a simple box shaped area in which is present a plume
    %
    % PlumeArea Methods:
    %    PlumeArea(objparams)           - constructs the object
    %    reset()                        - does nothing
    %    getOriginUTMCoords()           - returns origin
    %    getLimits()                    - returns limits
    %    isGraphicsOn()                 - returns true if there is a graphics objec associate with the area
    %    getSamples(positions)          - returns concentration at positions
    %
    methods (Sealed,Access=public)
        function obj = PlumeArea(objparams)
            % constructs the object
            %
            % Example:
            %
            %   obj=PlumeArea(objparams)
            %               objparams.limits - x,y,z limits of the area 
            %               objparams.originutmcoords - structure containing the origin in utm coord
            %               objparams.graphics.type - class type for the graphics object 
            %                                         (only needed if the 3D display is active)
            %               objparams.state - handle to the simulator state
            %
            obj=obj@Area(objparams);
        end  
    end   
    
    methods (Abstract,Access=public)            
        samples = getSamples(obj,positions)
        % returns concentration at positions
    end
    
    methods (Abstract,Access=protected)
        obj=init(obj)
        % perform initialization 
    end
end
