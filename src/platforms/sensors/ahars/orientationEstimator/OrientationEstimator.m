classdef OrientationEstimator<Sensor
    % Abstract class for a generic OrientationEstimator sensor.
    % This is a simple wrapper, it does not include any code, its only purpouse is to 
    % allow for runtime type checking.
    %
    % OrientationEstimator Methods:
    %    OrientationEstimator(objparams) - constructs the object, to be called only from derived subclasses.
    %
    methods (Sealed)
        function obj = OrientationEstimator(objparams)       
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

