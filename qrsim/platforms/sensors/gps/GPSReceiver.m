classdef GPSReceiver<Sensor
    % Abstract class for a generic GPS receiver.
    % This is a simple wrapper, it does not include any code, its only purpouse is to
    % allow for runtime type checking.
    %
    % GPSReceiver Methods:
    %    GPSReceiver(objparams) - constructs the object
    %
    methods
        function obj = GPSReceiver(objparams)
            % constructs the object
            %
            % Example:
            %
            %   obj=Sensor(objparams)
            %                objparams.dt - timestep of this object
            %                objparams.DT - global simulation timestep
            %                objparams.on - 1 if the object is active
            %                objparams.seed - prng seed, random if 0
            %
            % Note:
            % this is an abstract class so this contructor is meant to be called by any
            % subclass.
            %
            obj = obj@Sensor(objparams);
        end
    end
end

