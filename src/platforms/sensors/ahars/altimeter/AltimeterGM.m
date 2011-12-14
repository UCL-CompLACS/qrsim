classdef AltimeterGM<Altimeter
    % Simple accelerometer noise model.
    % The noise is modelled as an additive Gauss-Markov process.
    %
    % AltimeterGM Properties:
    %   BETA                       - noise time constant
    %   SIGMA                      - noise standard deviation
    %
    % AltimeterGM Methods:
    %   AltimeterGM(objparams)     - constructs the object 
    %   getMeasurement(X)          - returns a noisy orientation measurement
    %   update([])                 - updates the altimeter sensor noise state
    %
    
    properties (Access = private)
        BETA                       % noise time constant
        SIGMA                      % noise standard deviation
        n = zeros(1,1);     % noise sample at current timestep
    end
    
    methods (Sealed)
        function obj = AltimeterGM(objparams)
            % constructs the object 
            %
            % Example:
            %
            %   obj=AltimeterGM(objparams)
            %                objparams.dt - timestep of this object
            %                objparams.DT - global simulation timestep
            %                objparams.on - 1 if the object is active
            %                objparams.seed - prng seed, random if 0
            %                objparams.BETA - noise time constant
            %                objparams.SIGMA - noise standard deviation
            %
            obj = obj@Altimeter(objparams);
            obj.BETA = objparams.BETA;
            obj.SIGMA = objparams.SIGMA; 
        end
        
        function estimatedAltitude = getMeasurement(obj,X)
            % returns a noisy altitude measurement
            %
            % Example:
            %   ma = obj.getMeasurement(X)
            %        X - platform noise free state vector [px,py,pz,phi,theta,psi,u,v,w,p,q,r,thrust]
            %        ma - scalar "noisy" altitude in global frame \~h  m
            %
            
            if(obj.active==1)%noisy
                estimatedAltitude = obj.n - X(3); %altitude not Z
            else             %noiseless 
                estimatedAltitude = -X(3);        %altitude not Z
            end    
        end
    end
    
    methods (Sealed,Access=protected)         
        function obj=update(obj,~)
            % updates the altimeter noise state
            % Note: this method is called by step() if the time is a multiple
            % of this object dt, therefore it should not be called directly. 
            obj.n = obj.n.*exp(-obj.BETA*obj.dt) + obj.SIGMA.*randn(obj.rStream,1,1);
        end
        
    end
    
end

