classdef BoxArea<EnvironmentObject
    % defines an empty area in which the platforms can fly
    %
    % BoxArea Methods:
    %    BoxArea(objparams)   - constructs the object
    %    reset()              - does nothing
    %    getOriginUTMCoords() - returns origin
    %    getLimits()          - returns limits
    %    isGraphicsOn()       - returns true if there is a graphics objec associate with the area
    %           
    properties (Access=private)
        graphics;         % handle to the graphics object
        originUTMCoords;  % origin
        limits;           % are limits
    end
    
    methods (Sealed,Access=public)
        function obj = BoxArea(objparams)
            % constructs the object
            %
            % Example:
            %
            %   obj=BoxArea(objparams)
            %                objparams - object parameters
            %
            obj=obj@EnvironmentObject(objparams);
            
            assert(isfield(objparams,'limits'),'boxarea:nolimits','The task must define environment.area.limits');
            obj.limits = objparams.limits;
            
            assert(isfield(objparams,'originutmcoords'),'boxarea:nooriginutmcoords','The task must define environment.area.originutmcoords');
            obj.originUTMCoords = objparams.originutmcoords;
            
            assert(isfield(objparams,'graphics')&&isfield(objparams.graphics,'on'),'boxarea:nographics',['The task must define environment.area.graphics\n',...
                ' this could be environment.area.graphics.on=0; if no graphics is needed']);
            if(objparams.graphics.on)
                assert(isfield(objparams.graphics,'type'),'boxarea:nographicstype','Since the display3d is on the task must define environment.area.graphics.type');
                obj.graphics=feval(objparams.graphics.type,objparams.limits);
            end
        end
        
        function on = isGraphicsOn(obj)
           % returns true if there is a graphics objec associate with the area
           on = ~isempty(obj.graphics); 
        end 
        
        function coords = getOriginUTMCoords(obj)
            % returns origin
            coords = obj.originUTMCoords ;
        end
        
        function limits = getLimits(obj)
            % returns limits
            limits = obj.limits;
        end
        
        function obj = reset(obj)
            % does nothing
        end
    end
end
