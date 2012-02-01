classdef QuadrotorGraphics<handle
    % Class that handles the case in which the 3D visualization is turned off
    % basically an empty shell mostly useful for type checking.
    %
    % QuadrotorGraphics Methods:
    %   QuadrotorGraphics(initX,params)  - constructs the object
    %   update()                         - does nothing
    %
       
    methods (Sealed)
        function obj=QuadrotorGraphics(~,~)
            % constructs the object
        end
    end
    
    methods
        function obj = update(obj,~)
            % does nothing
            %
        end
    end
    
end

