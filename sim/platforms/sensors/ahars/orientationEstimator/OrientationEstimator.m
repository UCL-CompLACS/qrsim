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
    
    properties (Access=protected)
        estimatedOrientation = zeros(3,1);% measurement at last valid timestep
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
    
    methods (Access=public)
        function estimatedOrientation = getMeasurement(obj,~)
            % returns a noiseless orientation measurement
            %
            % Example:
            %   mo = obj.getMeasurement(X)
            %        X - platform noise free state vector [px;py;pz;phi;theta;psi;u;v;w;p;q;r;thrust]
            %        mo - 3 by 1 "noiseless" orientation in global frame,
            %             Euler angles ZYX [phi;theta;psi] rad
            %
            estimatedOrientation = obj.estimatedOrientation;
        end
        
        function obj=reset(obj)
            % reset
            obj.bootstrapped = obj.bootstrapped +1;
        end
        
        function obj = setState(obj,X)
            % re-initialise the state to a new value
            %
            % Example:
            %
            %   obj.setState(X)
            %       X - platform state
            %
            obj.estimatedOrientation = X(4:6);
            obj.bootstrapped = 0;
        end
    end
    
    methods (Access=protected)
        function obj=update(obj,X)
            % stores the orientation
            % Note: this method is called by step() if the time is a multiple
            % of this object dt, therefore it should not be called directly.
            obj.estimatedOrientation = X(4:6);
        end
    end
end

