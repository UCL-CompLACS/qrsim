classdef GaussianDispersionPlumeArea<PlumeArea
    % Defines a simple box shaped area in which is present a plume that is emitted at constant rate
    % the resulting concentration is described by a cone like concentration pattern oriented downwind
    %
    % GaussianDispersionPlumeArea Methods:
    %    GaussianDispersionPlumeArea(objparams)   - constructs the object
    %    reset()                        - reset the model
    %    getOriginUTMCoords()           - returns origin
    %    getLimits()                    - returns limits
    %    isGraphicsOn()                 - returns true if there is a graphics objec associate with the area
    %    getSamples(positions)          - returns concentration at positions
    %    getLocations()                 - returns array of locations at which the prediction must be made
    %    getSamplesPerLocation()        - returns the number of samples to be returned for each of the locations
    %
    
    properties (Access=protected)
        Qs;                   % source rate
        QRange;               % min max source rate
        a;                    % diffusion parameter
        b;                    % diffusion parameter
        u;                    % wind speed
        numSourcesRange;      % min max num sources
        C;                    % global to wind axis transformation
        iPrngId;              % prng id
        sPrngId;              % prng id
        vmean;                % mean wind velocity
    end
    
    methods (Sealed,Access=public)
        function obj = GaussianDispersionPlumeArea(objparams)
            % constructs the object
            %
            % Example:
            %
            %   obj=GaussianDispersionPlumeArea(objparams)
            %               objparams.limits - x,y,z limits of the area
            %               objparams.originutmcoords - structure containing the origin in utm coord
            %               objparams.graphics.type - class type for the graphics object
            %                                         (only needed if the 3D display is active)
            %               objparams.graphics.backgroundimage - background image
            %               objparams.numreflocations - number of reference locations in space used for reward computation
            %               objparams.sourceSigmaRange - min,max values for the width of the Gaussian concentration
            %                                         (with of the concentration along the principal axes is drawn
            %                                          randomly with uniform probability from the specified range)
            %               objparams.numSourcesRange - min,max number of sources in the area
            %               objparams.QRange - min,max emission rate of a source
            %               objparams.a - diffusion parameter
            %               objparams.b - diffusion parameter
            %               objparams.state - handle to the simulator state
            %
            obj=obj@PlumeArea(objparams);
            
            obj.iPrngId = obj.simState.numRStreams+1;
            obj.sPrngId = obj.simState.numRStreams+2;
            obj.simState.numRStreams = obj.simState.numRStreams + 2;
            
            assert(isfield(objparams,'a'),'gaussiandispersionplumearea:noa',...
                'If using a GaussianDispersionPlumeArea, the task must define the dispersion parameter a');
            obj.a = objparams.a;
            
            assert(isfield(objparams,'b'),'gaussiandispersionplumearea:nob',...
                'If using a GaussianDispersionPlumeArea, the task must define the dispersion parameter b');
            obj.b = objparams.b;
            
            assert(isfield(objparams,'numSourcesRange'),'gaussiandispersionplumearea:nonumsourcesrange',...
                'If using a GaussianDispersionPlumeArea, the task must define the parameter numSourcesRange');
            obj.numSourcesRange = objparams.numSourcesRange;
            
            assert(isfield(objparams,'QRange'),'gaussiandispersionplumearea:nonqrange',...
                'If using a GaussianDispersionPlumeArea, the task must define the parameter QRange');
            obj.QRange = objparams.QRange;
            
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
            % reset the object 
            
            % redraw a different plume pattern
            obj.init();
            % modify plot
            obj.computeLocations();
            obj.computeReferenceSamples();
            obj.graphics.update(obj.simState,obj.sources,obj.vmean,obj.locations,obj.referenceSamples);

            obj.bootstrapped = 1;
        end
        
        function c = getSamples(obj,pos)
            % returns the concentration at the requested locations
            
            n = size(pos,2);
            c = zeros(1,n);
            
            for i=1:obj.numSources,
                % transform location to source centered wind frame
                p = [obj.C*(pos(1:2,:)-repmat(obj.sources(1:2,i),1,n));...
                    pos(3,:)-obj.sources(3,i);...
                    pos(3,:)+obj.sources(3,i)];
                
                den = (2*obj.a*p(1,:).^obj.b);
                
                ci = (obj.Qs(i)./(pi*obj.u*den)).*...
                    exp(-((p(2,:).^2)./den)).*...
                    (exp(-((p(3,:).^2)./den))+exp(-((p(4,:).^2)./den)));
                
                % the model is not valid for negative x...
                ci(p(1,:)<0)=0;
                c = c+ci;
            end
        end
    end
    
    methods (Access=protected)
        function obj=init(obj)
            % initialize the area object by generating new number new positions
            % and rates for the sources.
            
            % generate the dispersion rates and the position of the sources
            
            % number of sources
            if (obj.numSourcesRange(2)~=obj.numSourcesRange(1))
                obj.numSources=(obj.numSourcesRange(1)-1)+...
                    randi(obj.simState.rStreams{obj.iPrngId},obj.numSourcesRange(2)-obj.numSourcesRange(1)+1,1);
            else
                obj.numSources=obj.numSourcesRange(1);
            end
            obj.sources=zeros(3,obj.numSources);
            
            % rates
            obj.Qs = obj.QRange(1)*ones(1,obj.numSources)+(obj.QRange(2)-...
                obj.QRange(1))*rand(obj.simState.rStreams{obj.iPrngId},1,obj.numSources);
            
            obj.cepsilon = 1e-3*min(obj.Qs);
            
            % sources position
            limits = reshape(obj.limits,2,3)';
            lph = 0.5*(limits(:,2)+limits(:,1));
            lm = 0.8*(limits(:,2)-limits(:,1));
            obj.sources = repmat(lph,1,obj.numSources)+repmat(lm,1,obj.numSources)...
                .*(rand(obj.simState.rStreams{obj.iPrngId},3,obj.numSources)-0.5);
            
            % mean wind
            obj.vmean = obj.simState.environment.wind.getLinear([0;0;-6;0;0;0]);
            
            % wind magnitude
            obj.u = norm(obj.vmean);
            assert((obj.u>0),'gaussiandispersionplumearea:nopositivewind',...
                'If using a GaussianDispersionPlumeArea, the wind must be turned on ond obj.W6 must be positive');
            
            % rotation body to wind frame
            obj.C=[obj.vmean(1),obj.vmean(2);-obj.vmean(2),obj.vmean(1)]./obj.u;            
        end
        
        function obj=computeReferenceSamples(obj)
            % computes a set of samples from the model used by the simulator
            obj.referenceSamples = obj.getSamples(obj.locations);
        end
        
        function obj=computeLocations(obj)
            % generates random locations within the support
            % i.e. so that c(x,y,z)>epsilon
            % at which the agent has to return predictions
            obj.locations=zeros(3,obj.numRefLocations);
            
            limits = reshape(obj.limits,2,3)';
            lph = 0.5*(limits(:,2)+limits(:,1));
            lm = (limits(:,2)-limits(:,1));
            
            nout = ceil(0.2*obj.numRefLocations);
            ll = repmat(lph,1,nout)+repmat(lm,1,nout)...
                    .*(rand(obj.simState.rStreams{obj.iPrngId},3,nout)-0.5);
            obj.locations(:,(1:nout)) = ll;
            
            nin = obj.numRefLocations - nout;
            while (nin > 0)
                % generate n points within the area limits
                ll = repmat(lph,1,nin)+repmat(lm,1,nin)...
                    .*(rand(obj.simState.rStreams{obj.iPrngId},3,nin)-0.5);
                
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
    end
end
