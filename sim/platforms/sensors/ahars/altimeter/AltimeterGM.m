classdef AltimeterGM<Altimeter
    % Simple accelerometer noise model.
    % The following assumptions are made:
    % - the noise is modelled as an additive Gauss-Markov process.
    % - the accelerometer refrence frame concides wih the body reference frame
    % - no time delays
    %
    % AltimeterGM Methods:
    %   AltimeterGM(objparams)     - constructs the object
    %   getMeasurement(X)          - returns a noisy altitude measurement
    %   update(X)                  - updates the altimeter noisy altitude measurement
    %   reset()                    - does nothing
    %   setState(X)                - sets the current altitude and its derivative and resets
    %
    properties (Access = protected)
        TAU;                      % noise time constant
        SIGMA;                    % noise standard deviation
        pastEstimatedAltitude;    % altitude at past valid timestep
        n;                        % noise        
        nPrngId;                  % id of the prng stream used by the noise model
        rPrngId;                  % id of the prng stream used to spin up the noise model
    end
    
    methods (Sealed,Access=public)
        function obj = AltimeterGM(objparams)
            % constructs the object
            %
            % Example:
            %
            %   obj=AltimeterGM(objparams)
            %                objparams.dt - timestep of this object
            %                objparams.on - 1 if the object is active
            %                objparams.BETA - noise time constant
            %                objparams.SIGMA - noise standard deviation
            %
                        
            obj = obj@Altimeter(objparams);
            
            obj.nPrngId = obj.simState.numRStreams+1;
            obj.rPrngId = obj.simState.numRStreams+2; 
            obj.simState.numRStreams = obj.simState.numRStreams + 2;
            
            assert(isfield(objparams,'TAU'),'altimetergm:notau',...
                'the platform config file a must define altimetergm.TAU parameter');
            obj.TAU = objparams.TAU;
            assert(isfield(objparams,'SIGMA'),'altimetergm:nosigma',...
                'the platform config file a must define altimetergm.SIGMA parameter');
            obj.SIGMA = objparams.SIGMA;
        end
        
        function estimatedAltAndAltDot = getMeasurement(obj,~)
            % returns a noisy altitude measurement
            %
            % Example:
            %   [~h,~hdot] = obj.getMeasurement(X)
            %        X - platform noise free state vector [px,py,pz,phi,theta,psi,u,v,w,p,q,r,thrust]
            %        ~h - scalar "noisy" altitude in global frame m
            %        ~hdot - scalar "noisy" altitude rate in global frame m
            %
            
            estimatedAltAndAltDot = obj.estimatedAltAndAltDot;
        end
        
        function obj=reset(obj)
            % reinitialize the noise state

            obj.n = 0;
            nm1 = 0;
            for i=1:randi(obj.simState.rStreams{obj.rPrngId},1000),
                nm1 = obj.n;
                obj.n = obj.n.*exp(-obj.TAU*obj.dt) + obj.SIGMA.*randn(obj.simState.rStreams{obj.nPrngId},1,1);
            end
            
            obj.estimatedAltAndAltDot(1,1) = obj.estimatedAltAndAltDot(1,1) + obj.n;  %altitude not Z     
            obj.estimatedAltAndAltDot(2,1) = obj.estimatedAltAndAltDot(2,1) + (obj.n-nm1)./obj.dt;  
            
            obj.bootstrapped = obj.bootstrapped +1;
        end       
                        
        function obj = setState(obj,X)
           % re-initialise the state to a new value
           %
           % Example:
           %
           %   obj.setState(X)
           %       X - platform noise free state vector [px,py,pz,phi,theta,psi,u,v,w,p,q,r,thrust]
           %
         
           % velocity in global frame
           gvel = (dcm(X)')*X(7:9);                
                
           % crude init of past position
           obj.estimatedAltAndAltDot(1,1) = - X(3);
           obj.estimatedAltAndAltDot(2,1) = gvel(3);
           
           obj.bootstrapped = 0;          
        end
    end
    
    methods (Sealed,Access=protected)
        
        function obj=update(obj,X)
            % updates the altimeter noise state
            % Note: this method is called by step() if the time is a multiple
            % of this object dt, therefore it should not be called directly.               
                        
            obj.n = obj.n.*exp(-obj.TAU*obj.dt) + obj.SIGMA.*randn(obj.simState.rStreams{obj.nPrngId},1,1);
            
            obj.pastEstimatedAltitude = obj.estimatedAltAndAltDot(1,1);
            obj.estimatedAltAndAltDot(1,1) = obj.n - X(3);  %altitude not Z
            obj.estimatedAltAndAltDot(2,1) =  (obj.estimatedAltAndAltDot(1) - obj.pastEstimatedAltitude)/obj.dt;
        end
    end
    
end

