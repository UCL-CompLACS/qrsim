classdef GyroscopeG<Gyroscope
    % Simple gyroscope noise model.
    % The noise is modelled as additive white Gaussian.
    %
    % GyroscopeG Properties:
    %   SIGMA                            - noise standard deviation
    %
    % GyroscopeG Methods:
    %   GyroscopeG(objparams)            - constructs the object
    %   getMeasurement(X)                - returns a noisy angular velocity measurement
    %   update([])                       - updates the gyroscope sensor noise state
    %
    properties (Access = private)
        SIGMA = [0.0005;0.0005;0.0005]; % noise standard deviation
        n = zeros(3,1);                 % noise sample at current timestep
    end
    
    methods (Sealed)
        
        function obj = GyroscopeG(objparams)
            % constructs the object
            %
            % Example:
            %
            %   obj=GyroscopeG(objparams)
            %                objparams.dt - timestep of this object
            %                objparams.DT - global simulation timestep
            %                objparams.on - 1 if the object is active
            %                objparams.seed - prng seed, random if 0
            %                objparams.SIGMA - noise standard deviation
            %
            obj=obj@Gyroscope(objparams);
            obj.SIGMA = objparams.SIGMA;
        end
        
        function measurementAngularVelocity = getMeasurement(obj,X)
            % returns a noisy angular velocity measurement
            %
            % Example:
            %   ma = obj.getMeasurement(X)
            %        X - platform noise free state vector [px;py;pz;phi;theta;psi;u;v;w;p;q;r;thrust]
            %        ma - 3 by 1 "noisy" angular velocity in body frame [\~p;\~q;\~r] rad/s
            %
            
            if(obj.active==1)  %noisy
                measurementAngularVelocity = obj.n + X(10:12);
            else               %noiseless
                measurementAngularVelocity = X(10:12);
            end
        end
    end
    
    methods (Sealed,Access=protected)
        function obj=update(obj,~)
            % updates the gyroscope noise state
            % Note: this method is called by step() if the time is a multiple
            % of this object dt, therefore it should not be called directly.
            obj.n = obj.SIGMA.*randn(obj.rStream,3,1);
        end
    end
    
end

