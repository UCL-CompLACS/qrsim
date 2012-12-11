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
    %   reset()                           - reinitializes the noise state
    %   setState(X)                       - sets the current orientation and resets
    %
    properties (Access = protected)
        BETA;                             % noise time constant
        SIGMA;                            % noise standard deviation
        n;                                % noise sample at current timestep
        nPrngIds;                         %ids of the prng stream used by the noise model
        rPrngId;                          %id of the prng stream used to spin up the noise model
    end
    
    methods (Sealed,Access=public)
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
            
            obj.nPrngIds = [1,2,3]+obj.simState.numRStreams;
            obj.rPrngId = obj.simState.numRStreams+4;
            obj.simState.numRStreams = obj.simState.numRStreams + 4;
            
            assert(isfield(objparams,'BETA'),'orientationestimatorgm:nobeta',...
                'the platform config file a must define orientationEstimator.BETA parameter');
            obj.BETA = objparams.BETA;    % noise time constant
            assert(isfield(objparams,'SIGMA'),'orientationestimatorgm:nosigma',...
                'the platform config file a must define orientationEstimator.SIGMA parameter');
            obj.SIGMA = objparams.SIGMA;  % noise standard deviation
            obj.bootstrapped = 0;
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
        
        function obj=reset(obj)
            % reinitializes the noise state
            
            obj.n = zeros(3,1);
            for i=1:randi(obj.simState.rStreams{obj.rPrngId},1000)
                eta = [randn(obj.simState.rStreams{obj.nPrngIds(1)},1,1);
                    randn(obj.simState.rStreams{obj.nPrngIds(2)},1,1);
                    randn(obj.simState.rStreams{obj.nPrngIds(3)},1,1)];
                obj.n = obj.n.*exp(-obj.BETA*obj.dt) + obj.SIGMA.*sqrt((1-exp(-2*obj.BETA*obj.dt))./(2*obj.BETA)).*eta;
            end
            obj.estimatedOrientation = obj.estimatedOrientation + obj.n;
            obj.bootstrapped = obj.bootstrapped +1;
        end
        
        function obj = setState(obj,X)
            obj.estimatedOrientation = X(4:6);
            obj.bootstrapped = 0;
        end
    end
    
    methods (Sealed,Access=protected)
        function obj=update(obj,X)
            % updates the orientation sensor noise state
            % Note: this method is called by step() if the time is a multiple
            % of this object dt, therefore it should not be called directly.
            
            eta = [randn(obj.simState.rStreams{obj.nPrngIds(1)},1,1);
                randn(obj.simState.rStreams{obj.nPrngIds(2)},1,1);
                randn(obj.simState.rStreams{obj.nPrngIds(3)},1,1)];
            obj.n = obj.n.*exp(-obj.BETA*obj.dt) + obj.SIGMA.*sqrt((1-exp(-2*obj.BETA*obj.dt))./(2*obj.BETA)).*eta;
            obj.estimatedOrientation = obj.n + X(4:6);
        end
    end
    
end

