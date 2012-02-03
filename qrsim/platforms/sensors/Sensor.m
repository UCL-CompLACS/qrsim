classdef Sensor<Steppable
    % Abstract class for a generic sensor.
    % This is a simple wrapper, it does not include any code, its only purpouse is to
    % allow for runtime type checking.
    %
    % Sensor Methods:
    %    Sensor(objparams)      - constructs the object, to be called only from derived
    %                             subclasses.
    %    getMeasurement(state)* - given a current state of the system returns a measurement
    %                             or an estimate
    %    setState(state)*       - re-initialise the state to a new value
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
            %                objparams.on - 1 if the object is active
            %
            % Note:
            % this is an abstract class so this contructor is meant to be called by any
            % subclass.
            %
            obj=obj@Steppable(objparams);
        end
    end
    
    methods (Abstract)
        meas=getMeasurement(obj,state);
        % given a current state of the system returns a measurement or an estimate 

        obj=setState(obj,state);
        % re-initialise the state to a new value
    end
    
end

