classdef AHARS<Sensor
    % Abstract class for a generic attitude-heading-altitude reference system.
    % This is a simple wrapper, it does not include any code, its only purpouse is to 
    % allow for runtime type checking.
    %
    % AHARS Methods:
    %    AHARS(params) - constructs the object, to be called only from derived subclasses.
    %
    methods (Sealed)
        function obj = AHARS(objparams)       
            % constructs the object
            % Calls the Steppable constructor
            % 
            % Note: this class is abstract so this constructor is meant to be called only 
            % by derived subclasses.
            %
            obj = obj@Sensor(objparams);
        end
    end    
end

