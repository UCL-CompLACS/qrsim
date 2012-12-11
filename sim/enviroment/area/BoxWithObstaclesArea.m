classdef BoxWithObstaclesArea<Area
    % Defines a simple box shaped area in which the platforms can fly and
    % in which there are column like object at prespecified positions.
    %
    % BoxWithObstaclesArea Methods:
    %    BoxWithObstaclesArea(objparams)   - constructs the object
    %    reset()              - does nothing
    %    getOriginUTMCoords() - returns origin
    %    getLimits()          - returns limits
    %    isGraphicsOn()       - returns true if there is a graphics objec associate with the area
    %
    
    methods (Sealed,Access=public)
        function obj = BoxWithObstaclesArea(objparams)
            % constructs the object
            %
            % Example:
            %
            %   obj=BoxWithObstaclesArea(objparams)
            %               objparams.limits - x,y,z limits of the area
            %               objparams.originutmcoords - structure containing the origin in utm coord
            %               objparams.graphics.type - class type for the graphics object
            %                                         (only needed if the 3D display is active)
            %               objparams.graphics.backgroundimage - background image
            %               objparams.state - handle to the simulator state
            %               objparams.obstacles - the array of obstacles
            %
            
            obj=obj@Area(objparams);
            
            if(objparams.graphics.on)
                tmp.limits = objparams.limits;
                tmp.state = objparams.state;
                if(isfield(objparams,'graphics') && isfield(objparams.graphics,'backgroundimage'))
                    tmp.backgroundimage = objparams.graphics.backgroundimage;
                end
                assert(isfield(objparams,'obstacles'),'boxwithobstaclesarea:noobstacles','for this type of flight area the task must define obstacles environment.area.obstacles');
                tmp.obstacles = objparams.obstacles;
                
                obj.graphics=feval(objparams.graphics.type,tmp);
            end
        end
        
        function obj = reset(obj)
            % reset area parameters
            % in this case nothing needs to be done
            obj.bootstrapped = 1;
        end
    end
end
