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
            % Calls the SteppablePRNG constructor
            % 
            % Note: this class is abstract so this constructor is meant to be called only 
            % by derived subclasses.
            %
            obj=obj@SteppablePRNG(objparams);
        end
    end
    
    methods (Abstract)        
        meas=getMeasurement(obj,state);
        % given a current state of the system returns a measurement or an estimate
    end
    
end

