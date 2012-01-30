classdef BoxArea<EnvironmentObject
    % defines an empty area in which the platforms can fly
    %
    % BoxArea Methods:
    %    BoxArea(objparams) -  constructs the object
    %
    properties (Access=private)
       graphics % handle to the graphics object
    end
    
    methods (Sealed)
        function obj = BoxArea(objparams)
            % constructs the object
            %
            % Example:
            %
            %   obj=BoxArea(objparams)
            %                objparams - object parameters
            %
            obj=obj@EnvironmentObject(objparams);
            
            assert(isfield(objparams,'limits'),'The task must define environment.area.limits');
            assert(isfield(objparams,'originutmcoords'),'The task must define environment.area.originutmcoords');
            
            if(objparams.graphics.on)
                obj.graphics=feval(objparams.graphics.type,objparams.limits);            
            end
        end
    end
end
