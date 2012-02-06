classdef OrientationEstimator<Sensor
    % Base class for a generic noiseless OrientationEstimator sensor.
    %
    % OrientationEstimator Methods:
    %   OrientationEstimator(objparams) - constructs the object
    %   getMeasurement(X)                 - returns a noiseless orientation measurement
    %   update(X)                         - stores the current orientation
    %   reset()                           - does nothing
    %   setState(X)                       - sets the current orientation and resets
    %
    
    properties (Access=private)
        orientation; % last orientation
    end
    
    methods (Sealed)
        function obj = OrientationEstimator(objparams)
            % constructs the object
            %
            % Example:
            %
            %   obj=OrientationEstimator(objparams)
            %                objparams.dt - timestep of this object
            %                objparams.on - 0 for this object
            %
            obj = obj@Sensor(objparams);
        end
    end
    
    methods
        function estimatedOrientation = getMeasurement(obj,~)
            % returns a noiseless orientation measurement
            %
            % Example:
            %   mo = obj.getMeasurement(X)
            %        X - platform noise free state vector [px;py;pz;phi;theta;psi;u;v;w;p;q;r;thrust]
            %        mo - 3 by 1 "noiseless" orientation in global frame,
            %             Euler angles ZYX [phi;theta;psi] rad
            %
            estimatedOrientation = obj.orientation;
        end
        
        function obj=reset(obj)
            % does nothing            
        end
        
        function obj = setState(obj,X)
            % sets the current orientation and resets
            obj.orientation = X(4:6);
            
            obj.reset();
        end  
    end
    
    methods (Access=protected)
        function obj=update(obj,X)
            % stores the orientation
            % Note: this method is called by step() if the time is a multiple
            % of this object dt, therefore it should not be called directly.
            obj.orientation = X(4:6);
        end
    end
end

