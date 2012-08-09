classdef QuadrotorGraphics<handle
    % Class that handles the case in which the 3D visualization is turned off
    % basically an empty shell mostly useful for type checking.
    %
    % QuadrotorGraphics Methods:
    %   QuadrotorGraphics(params)  - constructs the object
    %   update()                         - does nothing
    %
       
    properties (Access = protected)
        simState;
    end
    
    methods (Sealed)
        function obj=QuadrotorGraphics(objparams)
            % constructs the object
            obj.simState = objparams.state;
        end
    end
    
    methods
        function obj = update(obj,~)
            % does nothing
        end
        
        function obj = reset(obj)
             % does nothing       
        end
    end
    
end

