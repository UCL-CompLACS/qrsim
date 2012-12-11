classdef Gyroscope<Sensor
    % Base class for a generic noiseless Gyroscope sensor.
    %
    % Gyroscope Methods:
    %   Gyroscope(objparams)             - constructs the object
    %   getMeasurement(X)                - returns a noiseless angular velocity measurement
    %   update(X)                        - stores teh current rotational velocity
    %   reset()                          - does nothing
    %   setState(X)                      - sets the current angular velocity and resets
    %
    
    properties (Access=protected)
        measurementAngularVelocity = zeros(3,1); % measurement at last valid timestep
    end
    
    methods (Sealed,Access=public)
        function obj = Gyroscope(objparams)
            % constructs the object
            %
            % Example:
            %
            %   obj=Gyroscope(objparams)
            %                objparams.dt - timestep of this object
            %                objparams.on - 0 for this object
            %
            obj = obj@Sensor(objparams);
        end
    end
    
    methods (Access=public)
        function measurementAngularVelocity = getMeasurement(obj,~)
            % returns a noisy angular velocity measurement
            %
            % Example:
            %   ma = obj.getMeasurement(X)
            %        X - platform noise free state vector [px;py;pz;phi;theta;psi;u;v;w;p;q;r;thrust]
            %        ma - 3 by 1 noiseless angular velocity in body frame [p;q;r] rad/s
            %
            measurementAngularVelocity = obj.measurementAngularVelocity;
        end
        
        function obj=reset(obj)
            % reset
            obj.bootstrapped = 1;
        end
        
        function obj = setState(obj,X)
            % re-initialise the state to a new value
            %
            % Example:
            %
            %   obj.setState(X)
            %       X - platform state
            %
            obj.measurementAngularVelocity = X(10:12);
            obj.bootstrapped = 0;
        end
    end
    
    methods (Access=protected)
        function obj=update(obj,X)
            % stores the angular velocity
            % Note: this method is called by step() if the time is a multiple
            % of this object dt, therefore it should not be called directly.
            obj.measurementAngularVelocity = X(10:12);
        end
    end
end

