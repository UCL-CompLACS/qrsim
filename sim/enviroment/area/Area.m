classdef Area<Steppable & EnvironmentObject
    % Base class for any area in which the platforms can fly
    %
    % Area Methods:
    %    Area(objparams)      - constructs the object
    %    reset()              - does nothing
    %    getOriginUTMCoords() - returns origin
    %    getLimits()          - returns limits
    %    isGraphicsOn()       - returns true if there is a graphics object associate with the area
    %           
    properties (Access=protected)
        graphics;         % handle to the graphics object
        originUTMCoords;  % origin
        limits;           % are limits
        graphicsOn;
    end
    
    methods (Sealed,Access=public)
        function obj = Area(objparams)
            % constructs the object
            %
            % Example:
            %
            %   obj=Area(objparams)
            %               objparams.limits - x,y,z limits of the area 
            %               objparams.originutmcoords - structure containing the origin in utm coord
            %               objparams.graphics.type - class type for thegraphics object 
            %                                         (only needed if the 3D displayis active)
            %               objparams.state - handle to the simulator state
            %
            
            if(~isfield(objparams,'dt'))            
                % this is a static object
                objparams.dt = intmax*objparams.DT; 
            end
            objparams.on = 1;
            
            % call parents constructors
            obj=obj@Steppable(objparams);
            obj=obj@EnvironmentObject(objparams);
                        
            assert(isfield(objparams,'limits'),'area:nolimits','The task must define environment.area.limits');
            obj.limits = objparams.limits;
            
            assert(isfield(objparams,'originutmcoords'),'area:nooriginutmcoords','The task must define environment.area.originutmcoords');
            obj.originUTMCoords = objparams.originutmcoords;
            
            assert(isfield(objparams,'graphics')&&isfield(objparams.graphics,'on'),'area:nographics',['The task must define environment.area.graphics\n',...
                ' this could be environment.area.graphics.on=0; if no graphics is needed']);
            if(objparams.graphics.on)
                obj.graphicsOn = 1;
                assert(isfield(objparams.graphics,'type'),'area:nographicstype','Since the display3d is on the task must define environment.area.graphics.type');
            else
                obj.graphicsOn = 0;
            end
        end
        
        function coords = getOriginUTMCoords(obj)
            % returns origin
            coords = obj.originUTMCoords ;
        end
        
        function limits = getLimits(obj)
            % returns limits
            limits = obj.limits;
        end
    end
    
    methods (Access=public)
        function obj = reset(obj)
            % does nothing
        end
    end
          
    methods (Access=protected)

        function obj = update(obj, ~)
            % no updates are carries out.
            %
            % Note:
            %  this method is called automatically by the step() of the Steppable parent
            %  class and should not be called directly.
            %
        end
    end
end
