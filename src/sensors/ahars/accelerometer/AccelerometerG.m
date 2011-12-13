classdef AccelerometerG<Accelerometer
    % Simple accelerometer noise model.
    % The noise is modelled as additive white Gaussian.
    %
    % AccelerometerG Properties:
    %   SIGMA                            - noise standard deviation
    %
    % AccelerometerG Methods:
    %   AccelerometerG(objparams)        - constructs the object 
    %   getMeasurement(a)                - returns a noisy acceleration measurement
    %   update([])                       - updates the accelerometer sensor noise state
    %
    properties (Access = private)
        SIGMA                            % noise standard deviation
        n = zeros(3,1);                  % noise sample at current timestep
    end
    
    methods (Sealed)        
        function obj = AccelerometerG(objparams)
            % constructs the object 
            %
            % Example:
            %
            %   obj=AccelerometerG(objparams)
            %       objparams - configuration parameters 
            %                   objparams.on - 1 if active
            %                   objparams.dt - object's timestep
            %                   objparams.seed - prng seed
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
            %       a  - 3 by 1 vector of "noisy" acceleration in body frame [\~ax;\~ay;\~az] m/s^2
            %
            if(obj.active==1)    %noisy
                measurementAcceleration = obj.n + a(1:3);
            else                 %noiseless
                measurementAcceleration = a(1:3);
            end    
        end
    end
    
    methods (Sealed,Access=protected)        
        function obj=update(obj,~)
            % updates the accelerometer noise state
            % Note: this method is called by step() if the time is a multiple
            % of this object dt, therefore it should not be called directly. 
            obj.n = obj.SIGMA.*randn(obj.rStream,3,1);
        end
        
    end
    
end

