classdef Accelerometer<Sensor
    % Abstract class for a generic Accelerometer sensor.
    % This is a simple wrapper, it does not include any code, its only purpouse is to 
    % allow for runtime type checking.
    %
    % Accelerometer Methods:
    %    Accelerometer(objparams) - constructs the object, to be called only from derived subclasses.
    %
    methods (Sealed)
        function obj = Accelerometer(objparams)       
            % constructs the object
            % Calls the Sensor constructor
            % 
            % Note: this class is abstract so this constructor is meant to be called only 
            % by derived subclasses.
            %
            obj = obj@Sensor(objparams);
        end
    end    
end

