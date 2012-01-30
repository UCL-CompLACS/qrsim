classdef AHARS<Sensor
    % Abstract class for a generic attitude-heading-altitude reference system.
    % This is a simple wrapper, it does not include any code, its only purpouse is to
    % allow for runtime type checking.
    %
    % AHARS Methods:
    %    AHARS(params) - constructs the object
    %
    methods (Sealed)
        function obj = AHARS(objparams)
            % constructs the object
            %
            % Example:
            %
            %   obj=AHARS(objparams)
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

