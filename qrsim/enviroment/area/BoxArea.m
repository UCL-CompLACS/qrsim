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
            obj.graphics=feval(objparams.graphics.type,objparams.limits);            
        end
    end
end
