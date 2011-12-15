classdef OrientationEstimatorGM<OrientationEstimator
    % Simple orientation noise model.
    % The noise is modelled as an additive Gauss-Markov process.
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
            %                objparams.DT - global simulation timestep
            %                objparams.on - 1 if the object is active
            %                objparams.BETA - noise time constant
            %                objparams.SIGMA - noise standard deviation
            %
            obj=obj@OrientationEstimator(objparams);
            obj.BETA = objparams.BETA;    % noise time constant
            obj.SIGMA = objparams.SIGMA;  % noise standard deviation
        end
        
        function estimatedOrientation = getMeasurement(obj,X)
            % returns a noisy orientation measurement
            %
            % Example:
            %   mo = obj.getMeasurement(X)
            %        X - platform noise free state vector [px;py;pz;phi;theta;psi;u;v;w;p;q;r;thrust]
            %        mo - 3 by 1 "noisy" orientation in global frame,
            %             Euler angles ZYX [\~phi;\~theta;\~psi] rad
            %
            % Note: if active == 0, no noise is added, in other words:
            % mo = X(4:6)
            % 
                        fprintf('get measurement OrientationEstimatorGM active=%d\n',obj.active);
            if(obj.active==1)    %noisy
                estimatedOrientation = obj.estimatedOrientation;
            else                 %noiseless
                estimatedOrientation = X(4:6);
            end
        end
    end
    
    methods (Sealed,Access=protected)
        function obj=update(obj,X)
            % updates the orientation sensor noise state
            % Note: this method is called by step() if the time is a multiple
            % of this object dt, therefore it should not be called directly.
	        global state;
            obj.n = obj.n.*exp(-obj.BETA*obj.dt) + obj.SIGMA.*randn(state.rStream,3,1);
            obj.estimatedOrientation = obj.n + X(4:6);
        end
    end
    
end

