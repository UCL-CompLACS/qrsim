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
            %
            % Example:
            %
            %   obj=OrientationEstimator(objparams)
            %                objparams.dt - timestep of this object
            %                objparams.on - 1 if the object is active
            %
            % Note:
            % this is an abstract class so this contructor is meant to be called by any
            % subclass.
            %
            obj = obj@Sensor(objparams);
        end
    end
end

