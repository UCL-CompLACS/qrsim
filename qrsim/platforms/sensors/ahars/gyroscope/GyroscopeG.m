classdef GyroscopeG<Gyroscope
    % Simple gyroscope noise model.
    % The following assumptions are made:
    % - the noise is modelled as additive white Gaussian.
    % - the accelerometer refrence frame concides wih the body reference frame
    % - no time delays
    %
    % GyroscopeG Properties:
    %   SIGMA                            - noise standard deviation
    %
    % GyroscopeG Methods:
    %   GyroscopeG(objparams)            - constructs the object
    %   getMeasurement(X)                - returns a noisy angular velocity measurement
    %   update(X)                        - updates the gyroscope sensor noisy measurement
    %   reset()                          - does nothing
    %   setState(X)                      - sets the current angular velocity and resets
    %
    properties (Access = private)
        SIGMA = [0.0005;0.0005;0.0005]; % noise standard deviation
        measurementAngularVelocity = zeros(3,1); % measurement at last valid timestep
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
            %                objparams.on - 1 if the object is active
            %                objparams.SIGMA - noise standard deviation
            %
            obj=obj@Gyroscope(objparams);
            assert(isfield(objparams,'SIGMA'),'gyroscopeg:nosigma',...
                'the platform config file a must define gyroscope.SIGMA parameter');
            obj.SIGMA = objparams.SIGMA;
        end
        
        function measurementAngularVelocity = getMeasurement(obj,~)
            % returns a noisy angular velocity measurement
            %
            % Example:
            %   ma = obj.getMeasurement(X)
            %        X - platform noise free state vector [px;py;pz;phi;theta;psi;u;v;w;p;q;r;thrust]
            %        ma - 3 by 1 "noisy" angular velocity in body frame [~p;~q;~r] rad/s
            %
            measurementAngularVelocity = obj.measurementAngularVelocity;
        end
        
        function obj=reset(obj)
            % does nothing
            % since the noise model does not have state variables
        end
        
        function obj = setState(obj,X)
            % sets the current angular velocity and resets
            obj.reset();            
            obj.update(X);
        end
    end
    
    methods (Sealed,Access=protected)
        function obj=update(obj,X)
            % updates the gyroscope noise state
            % Note: this method is called by step() if the time is a multiple
            % of this object dt, therefore it should not be called directly.
            global state;
            obj.n = obj.SIGMA.*randn(state.rStream,3,1);
            obj.measurementAngularVelocity = obj.n + X(10:12);
        end
    end
    
end

