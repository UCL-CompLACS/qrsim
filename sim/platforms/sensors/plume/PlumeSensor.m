classdef PlumeSensor<Sensor
    % Class for a noiseless plume sensor
    %
    % PlumeSensor Methods:
    %    PlumeSensor(objparams)     - constructs the object
    %    getMeasurement(X)          - returns the noiseless plume concentration value at the current location
    %    update(X)                  - stores current state
    %    reset()                    - does nothing
    %    setState(X)                - re-initialise the state to a new value
    %
    properties (Access=protected)
        estimatedConc;  % current estimated concentration
    end
    
    methods (Access=public)
        function obj = PlumeSensor(objparams)
            % constructs the object
            %
            % Example:
            %
            %   obj=PlumeSensor(objparams)
            %                objparams.on - 0 to have this type of object
            %
            obj = obj@Sensor(objparams);
        end
        
        function conc = getMeasurement(obj,~)
            % returns the noiseless concentration estimate
            %
            % Example:
            %
            %   conc = obj.getMeasurement(~)
            %       conc  - plume concentration
            %
            conc = obj.estimatedConc;
        end
        
        function obj = setState(obj,X)
            % re-initialise the state to a new value
            obj.estimatedConc = obj.simState.environment.area.getSamples(X(1:3));
            obj.bootstrapped = 0;
        end
        
        function obj = reset(obj)
            % reset
            obj.bootstrapped = 1;
        end
        
    end
    
    methods (Access=protected)
        function obj=update(obj,X)
            % simply stores the concentration to be used by getMeasurement()
            %
            % Note: this method is called by step() if the time is a multiple
            % of this object dt, therefore it should not be called directly.
            
            obj.estimatedConc = obj.simState.environment.area.getSamples(X(1:3));
        end
    end
end

