classdef GaussianPlumeArea<PlumeArea
    % Defines a simple box shaped area in which is present a plume with concentration described by a 3d Gaussian
    %
    % GaussianPlumeArea Methods:
    %    GaussianPlumeArea(objparams)   - constructs the object
    %    reset()                        - does nothing
    %    getOriginUTMCoords()           - returns origin
    %    getLimits()                    - returns limits
    %    isGraphicsOn()                 - returns true if there is a graphics objec associate with the area
    %           
    
    properties (Constant)
       NUMSAMPLES = 1000;
    end
    
    properties (Access=protected)
       sigma;
       invSigma;
       detSigma;
       source;
       angle;
       sigmaRange;
       prngId;
       Q0;
       cepsilon;
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
            %               objparams.sourceSigmaRange - min,max values for the width of the Gaussian concentration
            %                                         (with of the concentration along the principal axes is drawn 
            %                                          randomly with uniform probability from the specified range)
            %               objparams.state - handle to the simulator state
            %
            obj=obj@PlumeArea(objparams);
            
            obj.prngId = obj.simState.numRStreams+1;
            obj.simState.numRStreams = obj.simState.numRStreams + 1;
            obj.sigmaRange = objparams.sourceSigmaRange;
            
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
            % redraw a different plume pattern
            obj.init();
            % modify plot
            locations = obj.getLocations();
            values = ((((2*pi)^3)*obj.detSigma)^0.5)*obj.getSamples(locations);
            obj.graphics.update(obj.simState,obj.source,[0;0;0],locations,values);            
        end
        
        function samples = getSamples(obj,positions)
            % compute the concentration at the requested locations            
            rsource = repmat(obj.source,1,size(positions,2)); 
            samples = obj.Q0*exp(-0.5*dot((positions-rsource),obj.invSigma*(positions-rsource),1));
        end
        
        function locations = getLocations(obj)
            % generate locations locations within the support
            % i.e. so that c(x,y,z)>epsilon
            locations=zeros(3,obj.NUMSAMPLES);
            
            limits = reshape(obj.limits,2,3)';
            lph = 0.5*(limits(:,2)+limits(:,1));
            lm = (limits(:,2)-limits(:,1));
            
            n = obj.NUMSAMPLES;
            while (n > 0)
                % generate n points within the area limits                
                ll = repmat(lph,1,n)+repmat(lm,1,n)...
                    .*(rand(obj.simState.rStreams{obj.prngId},3,n)-0.5);
                
                % compute concentration at such points
                c = obj.getSamples(ll);
                
                % keep the points whithin the support (i.e. c(x,y,z)>epsilon)
                csup = (c>obj.cepsilon);
                ncsup = sum(csup);
                idf = obj.NUMSAMPLES - n;
                locations(:,idf+(1:ncsup)) = ll(:,csup);
                
                % update number of samples needed
                n = n - ncsup;                
            end
        end
    end
    
    methods (Access=protected)
        function obj=init(obj)
            % generate the covariance matrix and the position of the source                       
            
            obj.angle = pi*rand(obj.simState.rStreams{obj.prngId});
            ss = obj.sigmaRange(1)+rand(obj.simState.rStreams{obj.prngId},3,1)*...
                                   (obj.sigmaRange(2)-obj.sigmaRange(1));
            
            sqrts = (angleToDcm(obj.angle,0,0)')*diag(ss);
            obj.sigma=sqrts*sqrts';
            
            obj.invSigma = inv(obj.sigma);
            obj.detSigma = det(obj.sigma);
            
            obj.Q0 = (1/((((2*pi)^3)*obj.detSigma)^0.5));          
            obj.cepsilon = 1e-5*obj.Q0;
            
            % source position
            limits = reshape(obj.limits,2,3)';
            lph = 0.5*(limits(:,2)+limits(:,1));
            lm = 0.8*(limits(:,2)-limits(:,1));              
            obj.source = lph+lm.*(rand(obj.simState.rStreams{obj.prngId},3,1)-0.5);            
        end
    end    
end
