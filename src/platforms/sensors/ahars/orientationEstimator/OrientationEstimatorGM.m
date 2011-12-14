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
    %   update([])                        - updates the orientation sensor noise state
    %
    properties (Access = private)
        BETA                              % noise time constant
        SIGMA                             % noise standard deviation
        n = zeros(3,1);                   % noise sample at current timestep
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
            %                objparams.seed - prng seed, random if 0
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
            if(obj.active==1)    %noisy
                estimatedOrientation = obj.n + X(4:6);
            else                 %noiseless
                estimatedOrientation = X(4:6);
            end
        end
    end
    
    methods (Sealed,Access=protected)
        function obj=update(obj,~)
            % updates the orientation sensor noise state
            % Note: this method is called by step() if the time is a multiple
            % of this object dt, therefore it should not be called directly.
            obj.n = obj.n.*exp(-obj.BETA*obj.dt) + obj.SIGMA.*randn(obj.rStream,3,1);
        end
    end
    
end

