classdef OrientationEstimatorGM<OrientationEstimator
    % Simple orientation noise model.
    % The following assumptions are made:
    % - the noise is modelled as an additive Gauss-Markov process.
    % - the accelerometer refrence frame concides wih the body reference frame
    % - no time delays
    %
    % OrientationEstimatorGM Properties:
    %   BETA                              - noise time constant
    %   SIGMA                             - noise standard deviation
    %
    % OrientationEstimatorGM Methods:
    %   OrientationEstimatorGM(objparams) - constructs the object
    %   getMeasurement(X)                 - returns a noisy orientation measurement
    %   update(X)                         - updates the orientation sensor noisy measurement
    %
    properties (Access = private)
        BETA                              % noise time constant
        SIGMA                             % noise standard deviation
        n = zeros(3,1);                   % noise sample at current timestep
        estimatedOrientation = zeros(3,1);% measurement at last valid timestep
    end
    
    methods (Sealed)
        function obj = OrientationEstimatorGM(objparams)
            % constructs the object
            %
            % Example:
            %
            %   obj=OrientationEstimatorGM(objparams)
            %                objparams.dt - timestep of this object
            %                objparams.on - 1 if the object is active
            %                objparams.BETA - noise time constant
            %                objparams.SIGMA - noise standard deviation
            %
            obj=obj@OrientationEstimator(objparams);
            assert(isfield(objparams,'BETA'),'orientationestimatorgm:nobeta',...
                'the platform config file a must define orientationEstimator.BETA parameter');
            obj.BETA = objparams.BETA;    % noise time constant
            assert(isfield(objparams,'SIGMA'),'orientationestimatorgm:nosigma',...
                'the platform config file a must define orientationEstimator.SIGMA parameter');
            obj.SIGMA = objparams.SIGMA;  % noise standard deviation
        end
        
        function estimatedOrientation = getMeasurement(obj,~)
            % returns a noisy orientation measurement
            %
            % Example:
            %   mo = obj.getMeasurement(X)
            %        X - platform noise free state vector [px;py;pz;phi;theta;psi;u;v;w;p;q;r;thrust]
            %        mo - 3 by 1 "noisy" orientation in global frame,
            %             Euler angles ZYX [~phi;~theta;~psi] rad
            %
            estimatedOrientation = obj.estimatedOrientation;
        end
    end
    
    methods (Sealed,Access=protected)
        function obj=update(obj,X)
            % updates the orientation sensor noise state
            % Note: this method is called by step() if the time is a multiple
            % of this object dt, therefore it should not be called directly.
            global state;
            obj.n = obj.n.*exp(-obj.BETA*obj.dt) + obj.SIGMA.*sqrt((1-exp(-2*obj.BETA*obj.dt))./(2*obj.BETA)).*randn(state.rStream,3,1);
            obj.estimatedOrientation = obj.n + X(4:6);
        end
    end
    
end

