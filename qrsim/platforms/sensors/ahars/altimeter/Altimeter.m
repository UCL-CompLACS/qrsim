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
    properties (Access=private)
        alt; % last altitude
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
    
    methods
        function estimatedAltitude = getMeasurement(obj,~)
            % returns noiseless altitude
            estimatedAltitude = obj.alt;
        end
                         
        function obj=reset(obj)
            % does nothing            
        end
        
        function obj = setState(obj,X)
            % sets the current altitude and its derivative and resets
            % handy values
            sph = sin(X(4)); cph = cos(X(4));
            sth = sin(X(5)); cth = cos(X(5));
            sps = sin(X(6)); cps = cos(X(6));
            
            dcm = [                (cth * cps),                   (cth * sps),      (-sth);
                (-cph * sps + sph * sth * cps), (cph * cps + sph * sth * sps), (sph * cth);
                (sph * sps + cph * sth * cps),(-sph * cps + cph * sth * sps), (cph * cth)];
            
            % velocity in global frame
            gvel = (dcm')*X(7:9);
            obj.alt = [-X(3);-gvel(3)];
            
            obj.reset();
        end  
    end
    
    methods (Access=protected)
        function obj=update(obj,X)
            % stores altitude
            % Note: this method is called by step() if the time is a multiple
            % of this object dt, therefore it should not be called directly.
            
            % handy values
            sph = sin(X(4)); cph = cos(X(4));
            sth = sin(X(5)); cth = cos(X(5));
            sps = sin(X(6)); cps = cos(X(6));
            
            dcm = [                (cth * cps),                   (cth * sps),      (-sth);
                (-cph * sps + sph * sth * cps), (cph * cps + sph * sth * sps), (sph * cth);
                (sph * sps + cph * sth * cps),(-sph * cps + cph * sth * sps), (cph * cth)];
            
            % velocity in global frame
            gvel = (dcm')*X(7:9);
            obj.alt = [-X(3);-gvel(3)];
        end
    end
end

