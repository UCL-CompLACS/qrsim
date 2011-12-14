classdef Sensor<SteppablePRNG
    % Abstract class for a generic sensor.
    % This is a simple wrapper, it does not include any code, its only purpouse is to
    % allow for runtime type checking.
    %
    % Sensor Methods:
    %    Sensor(objparams)      - constructs the object, to be called only from derived
    %                             subclasses.
    %    getMeasurement(state)* - given a current state of the system returns a measurement
    %                             or an estimate
    %
    %                           *hyperlink broken because the method is abstract
    methods
        function obj = Sensor(objparams)
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
            obj=obj@SteppablePRNG(objparams);
        end
    end
    
    methods (Abstract)
        meas=getMeasurement(obj,state);
        % given a current state of the system returns a measurement or an estimate
    end
    
end

