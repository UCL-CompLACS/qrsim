classdef AccelerometerG<Accelerometer
    % Simple accelerometer noise model.
    % The following assumptions are made:
    % - the noise is modelled as additive white Gaussian 
    % - the accelerometer refrence frame concides wih the body reference frame
    % - no time delays 
    %
    % AccelerometerG Properties:
    %   SIGMA                            - noise standard deviation
    %
    % AccelerometerG Methods:
    %   AccelerometerG(objparams)        - constructs the object
    %   getMeasurement(a)                - returns a noisy acceleration measurement
    %   update(a)                        - updates the accelerometer sensor noise state
    %
    properties (Access = private)
        SIGMA                            % noise standard deviation
        n = zeros(3,1);                  % noise sample at current timestep
        measurementAcceleration = zeros(3,1);% measurement at last valid timestep
    end
    
    methods (Sealed)
        function obj = AccelerometerG(objparams)
            % constructs the object
            %
            % Example:
            %
            %   obj=AccelerometerG(objparams)
            %                objparams.dt - timestep of this object
            %                objparams.on - 1 if the object is active
            %                objparams.SIGMA - noise standard deviation
            %
            obj = obj@Accelerometer(objparams);
            obj.SIGMA = objparams.SIGMA;
        end
        
        function measurementAcceleration = getMeasurement(obj,a)
            % returns a noisy acceleration measurement
            %
            % Example:
            %   ma = obj.getMeasurement(a)
            %       ma - 3 by 1 vector of noise free acceleration in body frame [ax;ay;az] m/s^2
            %       a  - 3 by 1 vector of "noisy" acceleration in body frame [~ax;~ay;~az] m/s^2
            %
            % Note: if active == 0, no noise is added, in other words:
            % ma = a
            % 
            %fprintf('get measurement AccelerometerG active=%d\n',obj.active);
            if(obj.active==1)    %noisy
                measurementAcceleration = obj.measurementAcceleration;
            else                 %noiseless
                measurementAcceleration = a(1:3);
            end
        end
    end
    
    methods (Sealed,Access=protected)
        function obj=update(obj,a)
            % updates the accelerometer noise state
            % Note: this method is called by step() if the time is a multiple
            % of this object dt, therefore it should not be called directly.
            global state;
            obj.n = obj.SIGMA.*randn(state.rStream,3,1);
            obj.measurementAcceleration = obj.n + a(1:3);
        end
        
    end
    
end

