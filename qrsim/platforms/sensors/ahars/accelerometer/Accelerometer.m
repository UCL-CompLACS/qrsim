classdef Accelerometer<Sensor
    % Class for a generic noiseless Accelerometer sensor.
    %
    % Accelerometer Methods:
    %   Accelerometer(objparams)         - constructs the object
    %   getMeasurement(a)                - returns a noiseless acceleration measurement
    %   update(a)                        - stores the current accelerations
    %   reset()                          - does nothing
    %   setState(a)                      - sets the current acceleration and resets
    %   
    properties (Access=private)
       a; % last acceleration 
    end    
    
    methods (Sealed)
        function obj = Accelerometer(objparams)
            % constructs the object
            %
            % Example:
            %
            %   obj=Accelerometer(objparams)
            %                objparams.dt - timestep of this object
            %                objparams.on - 0 to initialise this object
            %
            obj = obj@Sensor(objparams);
        end
    end
    
    methods 
        function measurementAcceleration = getMeasurement(obj,~)
            % returns a noiseless acceleration measurement
            %
            % Example:
            %   ma = obj.getMeasurement(a)
            %       a - 3 by 1 vector of noise free acceleration in body frame [ax;ay;az] m/s^2
            %       ma  - 3 by 1 vector of noise free acceleration in body frame [ax;ay;az] m/s^2
            % 
            measurementAcceleration = obj.a;
        end
        
        function obj=reset(obj)
            % does nothing            
        end
        
        function obj = setState(obj,a)
            % sets the current acceleration and resets
            obj.a = a;
            obj.reset();
        end
    end
    
    methods (Access=protected)
        function obj=update(obj,a)
            % saves the accelerometer noise state
            % Note: this method is called by step() if the time is a multiple
            % of this object dt, therefore it should not be called directly.
            obj.a = a(1:3);
        end
        
    end
end

