classdef GaussianPlumeArea<PlumeArea
    % Defines a simple box shaped area in which is present a plume with concentration described by a 3D Gaussian
    %
    % GaussianPlumeArea Methods:
    %    GaussianPlumeArea(objparams)   - constructs the object
    %    reset()                        - reset the model
    %    getOriginUTMCoords()           - returns origin
    %    getLimits()                    - returns limits
    %    isGraphicsOn()                 - returns true if there is a graphics objec associate with the area
    %    getSamples(positions)          - returns concentration at positions
    %    getLocations()                 - returns array of locations at which the prediction must be made
    %    getSamplesPerLocation()        - returns the number of samples to be returned for each of the locations
    %    
    properties (Access=protected)
        sigma;         % covariance matrix
        invSigma;      % inverse covariance matrix
        detSigma;      % covariance matrix dteterminant
        angle;         % orientation of the plume
        sigmaRange;    % min max value for the std of the ellipsoid 
        prngId;        % prng id
        Q0;            % source concentration
    end
    
    methods (Sealed,Access=public)
        function obj = GaussianPlumeArea(objparams)
            % constructs the object
            %
            % Example:
            %
            %   obj=GaussianPlumeArea(objparams)
            %               objparams.limits - x,y,z limits of the area
            %               objparams.originutmcoords - structure containing the origin in utm coord
            %               objparams.graphics.type - class type for the graphics object
            %                                         (only needed if the 3D display is active)
            %               objparams.graphics.backgroundimage - background image            
            %               objparams.numreflocations - number of reference locations in space used for reward computation
            %               objparams.sourcesigmarange - min,max values for the width of the Gaussian concentration
            %                                         (with of the concentration along the principal axes is drawn
            %                                          randomly with uniform probability from the specified range)
            %               objparams.state - handle to the simulator state
            %
            obj=obj@PlumeArea(objparams);
            
            obj.prngId = obj.simState.numRStreams+1;
            obj.simState.numRStreams = obj.simState.numRStreams + 1;
            
            assert(isfield(objparams,'sourcesigmarange'),'gaussianplumearea:sourcesigmarange',...
                'If using a GaussianPlumeArea, the task must define the parameter sourcesigmarange');                     
            obj.sigmaRange = objparams.sourcesigmarange;
            
            obj.numSamplesPerLocation = 1; % fix to 1 since the concentration is static and determinstic
           
            if(objparams.graphics.on)
                tmp.limits = objparams.limits;
                tmp.state = objparams.state;
                if(isfield(objparams,'graphics') && isfield(objparams.graphics,'backgroundimage'))
                    tmp.backgroundimage = objparams.graphics.backgroundimage;
                end
                
                obj.graphics=feval(objparams.graphics.type,tmp);
            end
        end
        
        function obj = reset(obj)
            % reset object
            
            % redraws a different plume pattern
            obj.init();
            % modify plot
            obj.graphics.update(obj.simState,obj.sources,[0;0;0],obj.locations,obj.referenceSamples);
	    obj.bootstrapped = 1;
        end
        
        function samples = getSamples(obj,positions)
            % computes the concentration at the requested locations
            rsource = repmat(obj.sources,1,size(positions,2));
            samples = obj.Q0*exp(-0.5*dot((positions-rsource),obj.invSigma*(positions-rsource),1));
        end
    end
    
    methods (Access=protected)
        function obj=init(obj)
            % generates new covariance matrix and new position of the source
            
            obj.angle = pi*rand(obj.simState.rStreams{obj.prngId});
            ss = obj.sigmaRange(1)+rand(obj.simState.rStreams{obj.prngId},3,1)*...
                (obj.sigmaRange(2)-obj.sigmaRange(1));
            
            sqrts = (angleToDcm(obj.angle,0,0)')*diag(ss);
            obj.sigma=sqrts*sqrts';
            
            obj.invSigma = inv(obj.sigma);
            obj.detSigma = det(obj.sigma);
            
            obj.Q0 = 1;%(1/((((2*pi)^3)*obj.detSigma)^0.5));
            obj.cepsilon = 1e-3*obj.Q0;
            
            % source position
            limits = reshape(obj.limits,2,3)';
            lph = 0.5*(limits(:,2)+limits(:,1));
            lm = 0.8*(limits(:,2)-limits(:,1));
            obj.numSources = 1;
            obj.sources = lph+lm.*(rand(obj.simState.rStreams{obj.prngId},3,1)-0.5);
            
            % compute locations
            obj.computeLocations();
            
            % compute reference samples
            obj.computeReferenceSamples();
        end
        
        function obj = computeLocations(obj)
            % generate locations within the support
            % i.e. so that c(x,y,z)>epsilon
            % at which the agent must make predictions
            
            obj.locations=zeros(3,obj.numRefLocations);
            
            limits = reshape(obj.limits,2,3)';
            lph = 0.5*(limits(:,2)+limits(:,1));
            lm = (limits(:,2)-limits(:,1));
            
            nout = ceil(0.2*obj.numRefLocations);
            ll = repmat(lph,1,nout)+repmat(lm,1,nout)...
                    .*(rand(obj.simState.rStreams{obj.prngId},3,nout)-0.5);
            obj.locations(:,(1:nout)) = ll;
            
            nin = obj.numRefLocations - nout;
            while (nin > 0)
                % generate n points within the area limits
                ll = repmat(lph,1,nin)+repmat(lm,1,nin)...
                    .*(rand(obj.simState.rStreams{obj.prngId},3,nin)-0.5);
                
                % compute concentration at such points
                c = obj.getSamples(ll);
                
                % keep the points whithin the support (i.e. c(x,y,z)>epsilon)
                csup = (c>obj.cepsilon);
                ncsup = sum(csup);
                idf = obj.numRefLocations - nin;
                obj.locations(:,idf+(1:ncsup)) = ll(:,csup);
                
                % update number of samples needed
                nin = nin - ncsup;
            end
        end
        
        function obj = computeReferenceSamples(obj)
            % compute samples from the underlying model
            obj.referenceSamples = obj.Q0*obj.getSamples(obj.locations);
        end
    end
end
