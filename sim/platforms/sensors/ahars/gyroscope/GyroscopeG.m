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
    properties (Access = protected)
        SIGMA = [0.0005;0.0005;0.0005]; % noise standard deviation
        n = zeros(3,1);                 % noise sample at current timestep
        prngIds;                        % ids of the prng stream used by this object
    end
    
    methods (Sealed,Access=public)
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
            
            obj.prngIds = [1,2,3]+obj.simState.numRStreams;
            obj.simState.numRStreams = obj.simState.numRStreams+3;
            
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
        
        function obj = reset(obj)
            % reset
            obj.n = obj.SIGMA.*[randn(obj.simState.rStreams{obj.prngIds(1)},1,1);
                randn(obj.simState.rStreams{obj.prngIds(2)},1,1);
                randn(obj.simState.rStreams{obj.prngIds(3)},1,1)];
            obj.measurementAngularVelocity = obj.measurementAngularVelocity + obj.n;
            
            obj.bootstrapped = obj.bootstrapped +1;
        end
        
        function obj = setState(obj,X)
            % re-initialise the state to a new value
            %
            % Example:
            %
            %   obj.setState(X)
            %       X - platform state
            %
            obj.measurementAngularVelocity = X(10:12);
            obj.bootstrapped = 0;
        end
    end
    
    methods (Sealed,Access=protected)
        function obj=update(obj,X)
            % updates the gyroscope noise state
            % Note: this method is called by step() if the time is a multiple
            % of this object dt, therefore it should not be called directly.
            
            obj.n = obj.SIGMA.*[randn(obj.simState.rStreams{obj.prngIds(1)},1,1);
                randn(obj.simState.rStreams{obj.prngIds(2)},1,1);
                randn(obj.simState.rStreams{obj.prngIds(3)},1,1)];
            obj.measurementAngularVelocity = obj.n + X(10:12);
        end
    end
    
end

