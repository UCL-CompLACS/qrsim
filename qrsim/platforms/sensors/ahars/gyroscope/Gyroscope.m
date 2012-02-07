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
    
    properties (Access=private)
        angularVelocity; % last angular velocity
    end
    
    methods (Sealed)
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
    
    methods 
         function measurementAngularVelocity = getMeasurement(obj,~)
            % returns a noisy angular velocity measurement
            %
            % Example:
            %   ma = obj.getMeasurement(X)
            %        X - platform noise free state vector [px;py;pz;phi;theta;psi;u;v;w;p;q;r;thrust]
            %        ma - 3 by 1 noiseless angular velocity in body frame [p;q;r] rad/s
            %
            measurementAngularVelocity = obj.angularVelocity;
         end
                 
        function obj=reset(obj)
            % does nothing            
        end
        
        function obj = setState(obj,X)
            % sets the current angular velocity and resets
            obj.reset();            
            obj.update(X);
        end
    end
    
    methods (Access=protected)
        function obj=update(obj,X)
            % stores the angular velocity
            % Note: this method is called by step() if the time is a multiple
            % of this object dt, therefore it should not be called directly.
            obj.angularVelocity = X(10:12);
        end
    end
end

