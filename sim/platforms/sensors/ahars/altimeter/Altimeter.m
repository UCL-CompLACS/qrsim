classdef Altimeter<Sensor
    % Abstract class for a generic Altimeter sensor.
    % This is a simple wrapper, it does not include any code, its only purpouse is to
    % allow for runtime type checking.
    %
    % Altimeter Methods:
    %   Altimeter(objparams)       - constructs the object
    %   getMeasurement(X)          - returns a noiseless altitude measurement
    %   update(X)                  - stores the current altitude
    %   reset()                    - does nothing
    %   setState(X)                - sets the current altitude and its derivative and resets
    %
    properties (Access=protected)
        estimatedAltAndAltDot;     % measurement at valid timestep
    end
    
    methods (Sealed)
        function obj = Altimeter(objparams)
            % constructs the object
            %
            % Example:
            %
            %   obj=Altimeter(objparams)
            %                objparams.dt - timestep of this object
            %                objparams.on - 0 for this type ob object
            %
            obj = obj@Sensor(objparams);
        end
    end
    
    methods (Access=public)
        function altAndAltDot = getMeasurement(obj,~)
            % returns noiseless altitude
            altAndAltDot = obj.estimatedAltAndAltDot;
        end
        
        function obj=reset(obj)
            % reset
            obj.bootstrapped = 1;
        end
        
        function obj=setState(obj,X)
            % re-initialise the state to a new value
            %
            % Example:
            %
            %   obj.setState(X)
            %       X - platform state
            %
            gvel = (dcm(X)')*X(7:9);
            
            % crude init of past position
            obj.estimatedAltAndAltDot = [-X(3);-gvel(3)];
            obj.bootstrapped = 0;
        end
    end
    
    methods (Access=protected)
        
        function obj=update(obj,X)
            % stores altitude
            % Note: this method is called by step() if the time is a multiple
            % of this object dt, therefore it should not be called directly.
            
            % velocity in global frame
            gvel = (dcm(X)')*X(7:9);
            obj.estimatedAltAndAltDot = [-X(3);-gvel(3)];
        end
        
    end
end

