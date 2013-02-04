classdef GaussianPuffDispersionPlumeArea<PlumeArea
    % Defines a simple box shaped area in which is present a plume that is
    % emitted in puffs with esponential inter-emission times
    % the resulting concentration is roughly described by blob like
    % puffs travelling downwind an expanding as the move away from the source
    %
    %
    % GaussianPuffDispersionPlumeArea Methods:
    %    GaussianPuffDispersionPlumeArea(objparams)   - constructs the object
    %    reset()                        - reset the model
    %    getOriginUTMCoords()           - returns origin
    %    getLimits()                    - returns limits
    %    isGraphicsOn()                 - returns true if there is a graphics objec associate with the area
    %    getSamples(positions)          - returns concentration at positions
    %    getLocations()                 - returns array of locations at which the prediction must be made
    %    getSamplesPerLocation()        - returns the number of samples to be returned for each of the locations
    %    
    properties (Constant)
        TIME_BETWEEN_REF_SAMPLES = 60;
    end
    
    properties (Access=private)
        QRange;           % min max source rate
        a;                    % diffusion parameter
        b;                    % diffusion parameter
        u;                    % wind speed
        numSourcesRange;      % min max num sources
        C;                    % global to wind axis transformation
        iPrngId;              % prng id
        sPrngId;              % prng id
        vmean;                % mean wind velocity
        mu;                   % average time between puffs
        puffs;                % array of current puffs
        nextEmissionTimes;    % times at which the new puffs will be emitted
    end
    
    methods (Sealed,Access=public)
        function obj = GaussianPuffDispersionPlumeArea(objparams)
            % constructs the object
            %
            % Example:
            %
            %   obj=GaussianPuffDispersionPlumeArea(objparams)
            %               objparams.limits - x,y,z limits of the area
            %               objparams.originutmcoords - structure containing the origin in utm coord
            %               objparams.graphics.type - class type for the graphics object
            %                                         (only needed if the 3D display is active)
            %               objparams.graphics.backgroundimage - background image            
            %               objparams.sourceSigmaRange - min,max values for the width of the Gaussian concentration
            %                                         (with of the concentration along the principal axes is drawn
            %                                          randomly with uniform probability from the specified range)
            %               objparams.numSourcesRange - min,max number of sources in the area
            %               objparams.QRange - min,max emission rate of a source
            %               objparams.a - diffusion paramter
            %               objparams.b - diffusion paramter
            %               objparams.state - handle to the simulator state
            %               objparams.mu - mean interemission time
            %               objparams.numsamplesperlocations - number of samples to be returned for each of the locations
            %
            obj=obj@PlumeArea(objparams);
            
            obj.iPrngId = obj.simState.numRStreams+1;
            obj.sPrngId = obj.simState.numRStreams+2;
            obj.simState.numRStreams = obj.simState.numRStreams + 2;
                        
            assert(isfield(objparams,'a'),'gaussianpuffdispersionplumearea:noa',...
                'If using a GaussianPuffDispersionPlumeArea, the task must define the dispersion parameter a');
            obj.a = objparams.a;
            
            assert(isfield(objparams,'b'),'gaussianpuffdispersionplumearea:nob',...
                'If using a GaussianPuffDispersionPlumeArea, the task must define the dispersion parameter b');
            obj.b = objparams.b;
            
            assert(isfield(objparams,'numSourcesRange'),'gaussianpuffdispersionplumearea:nonumsourcesrange',...
                'If using a GaussianPuffDispersionPlumeArea, the task must define the parameter numSourcesRange');
            obj.numSourcesRange = objparams.numSourcesRange;
                        
            assert(isfield(objparams,'mu'),'gaussianpuffdispersionplumearea:nomu',...
                'If using a GaussianPuffDispersionPlumeArea, the task must define the mean inter-emission time parameter mu');
            obj.mu = objparams.mu;
            
            assert(isfield(objparams,'QRange'),'gaussianpuffdispersionplumearea:nonqrange',...
                'If using a GaussianPuffDispersionPlumeArea, the task must define the parameter QRange');
            obj.QRange = objparams.QRange;
            
            assert(isfield(objparams,'numsamplesperlocations'),'gaussianpuffdispersionplumearea:nonumsamplesperlocations',...
                'If using a GaussianPuffDispersionPlumeArea, the task must define the parameter numsamplesperlocations');            
            obj.numSamplesPerLocation = objparams.numsamplesperlocations;
            
            if(objparams.graphics.on)
                tmp.limits = objparams.limits;
                tmp.state = objparams.state;
                if(isfield(objparams,'graphics') && isfield(objparams.graphics,'backgroundimage'))
                    tmp.backgroundimage = objparams.graphics.backgroundimage;
                end
                
                obj.graphics=feval(objparams.graphics.type,tmp);
            end
	    obj.bootstrapped = 0;
        end
        
        function obj = reset(obj)
            % redraw a different plume pattern
            obj.init(); 
            obj.bootstrapped = 1;
        end
        
        function c = getSamples(obj,pos)
            % get samples at the current time.
            c = obj.getSamplesAtTime(pos,obj.simState.t);
        end
    end
    
    methods (Access=protected)
        
        function obj=init(obj)
            % generate the dispersion rates and the position of the sources
            
            % number of sources
            if (obj.numSourcesRange(2)~=obj.numSourcesRange(1))
                obj.numSources=(obj.numSourcesRange(1)-1)+...
                    randi(obj.simState.rStreams{obj.iPrngId},obj.numSourcesRange(2)-obj.numSourcesRange(1)+1,1);
            else
                obj.numSources=obj.numSourcesRange(1);
            end
            obj.sources=zeros(3,obj.numSources);
            
            obj.cepsilon = 1e-3*obj.QRange(1);
            
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
            assert((obj.u>0),'gaussianpuffdispersionplumearea:nopositivewind',...
                'If using a GaussianPuffDispersionPlumeArea, the wind must be turned on ond obj.W6 must be positive');
            
            % rotation global to wind frame
            obj.C=[obj.vmean(1),obj.vmean(2);-obj.vmean(2),obj.vmean(1)]./obj.u;
            
            % produce locations used for KL computatation
            obj.computeLocations();
            
            % produce samples used as a reference for KL computatation
            obj.computeReferenceSamples();
            
            % empty puffs lists
            obj.puffs = [];
            
            %fprintf('starting with %d puffs\n',size(obj.puffs,1));
            % generate the times at which we expect a new emission for each source
            obj.nextEmissionTimes = obj.mu*(-log(rand(obj.simState.rStreams{obj.iPrngId},obj.numSources,1)));
            
        end
        
        function obj = update(obj, ~)
            % takes care of updating/removing puffs
            %
            % Note:
            %  this method is called automatically by the step() of the Steppable parent
            %  class and should not be called directly.
            %
            
            obj.propagateToTime(obj.simState.t);
            
            % refresh display
            if(obj.graphicsOn)
                values = obj.getSamples(obj.locations);
                obj.graphics.update(obj.simState,obj.sources,obj.vmean,obj.locations,values);
            end
        end
        
        function c = getSamplesAtTime(obj,pos,t)
            % compute the concentration at the requested locations and time
            
            c = zeros(1,size(pos,2));
            
            for i=1:size(obj.puffs,2),
                % transform location to source centered wind frame
                s = obj.puffs(1,i);
                p = pos;
                p(1,:)=p(1,:)-obj.sources(1,s);
                p(2,:)=p(2,:)-obj.sources(2,s);
                p = [obj.C*p(1:2,:);...
                    p(3,:)-obj.sources(3,s);...
                    p(3,:)+obj.sources(3,s)];
                
                dti = (t-obj.puffs(2,i));
                den = (2*obj.a*p(1,:).^obj.b);
                
                ci = (obj.puffs(3,i)./((2*pi*den).^1.5)).*...
                    exp(-(((p(1,:)-obj.u*dti).^2+p(2,:).^2)./den)).*...
                    (exp(-((p(3,:).^2)./den))+exp(-((p(4,:).^2)./den)));
                
                % the model is not valid for negative x...
                ci(p(1,:)<0)=0;
                ci(isnan(ci))=0;
                c = c + ci;
            end
        end
        
        function c = getSamplesFromAverage(obj,pos)
            % compute the concentration at the requested locations
            % from the average concentration model
            n = size(pos,2);
            c = zeros(1,n);
            
            for i=1:obj.numSources,
                % transform location to source centered wind frame
                p = [obj.C*(pos(1:2,:)-repmat(obj.sources(1:2,i),1,n));...
                    pos(3,:)-obj.sources(3,i);...
                    pos(3,:)+obj.sources(3,i)];
                
                den = (2*obj.a*p(1,:).^obj.b);
                
                ci = ((obj.QRange(2)/obj.mu)./(pi*obj.u*den)).*...
                    exp(-((p(2,:).^2)./den)).*...
                    (exp(-((p(3,:).^2)./den))+exp(-((p(4,:).^2)./den)));
                
                % the model is not valid for negative x...
                ci(p(1,:)<0)=0;
                c = c+ci;
            end
        end
        
        function obj = propagateToTime(obj,t)
            % remove puffs that are out of the flying area
            outside=[];
            for pi=1:size(obj.puffs,2)
                ti=(t-obj.puffs(2,pi));
                % 1% width of the Gaussian blob.
                w = sqrt(-log(0.01)*2*obj.a*(obj.u*ti)^obj.b);
                p = obj.C'*[obj.u*ti-w;0] + obj.sources(1:2,obj.puffs(1,pi));
                if((p(1)<obj.limits(1))||(p(1)>obj.limits(2))||(p(2)<obj.limits(3))||(p(2)>obj.limits(4)))
                    outside=[outside,pi]; %#ok<AGROW>
                end
            end
            obj.puffs(:,outside)=[];
            
            % add any newly emitted puff
            for s=1:obj.numSources,
                %fprintf('t:%d, %d puffs\n',obj.simState.t,size(obj.puffs,2));
                while(obj.nextEmissionTimes(s)<t)
                    q = obj.QRange(1)+(obj.QRange(2)-obj.QRange(1))*rand(obj.simState.rStreams{obj.iPrngId});
                    % a puff is defined by source, time, and concentration
                    obj.puffs(:,end+1) = [s;obj.nextEmissionTimes(s);q];
                    obj.nextEmissionTimes(s) = obj.nextEmissionTimes(s) + obj.mu*(-log(rand(obj.simState.rStreams{obj.iPrngId})));
                    %fprintf('added puff@%f for source %d, next puff@%f\n',obj.puffs(2,end),s,obj.nextEmissionTimes(s));
                end
            end
        end
        
        function obj = computeLocations(obj)
            % generate random locations within the support
            % i.e. so that c(x,y,z)>epsilon
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
                
                % compute average concentration at such points
                c = obj.getSamplesFromAverage(ll);
                
                % keep the points whithin the support (i.e. c(x,y,z)>epsilon)
                csup = (c>=obj.cepsilon);
                ncsup = sum(csup);
                idf = obj.numRefLocations - nin;
                obj.locations(:,idf+(1:ncsup)) = ll(:,csup);
                
                % update number of samples needed
                nin = nin - ncsup;
            end
        end
        
        function obj = computeReferenceSamples(obj)
            % produce the "true" samples against which the KL of the agent
            % produced samples is evaluated to return a reward.
            tic
            
            % allocate reference samples
            obj.referenceSamples = zeros(obj.numSamplesPerLocation,obj.numRefLocations);
            
            % clean up puffs and emission times...
            obj.puffs = [];
            % generate the times at which we expect a new emission for each source
            obj.nextEmissionTimes = obj.mu*(-log(rand(obj.simState.rStreams{obj.iPrngId},obj.numSources,1)));
            
            % get the locations at which we sample the concentration
            locs = obj.getLocations();
            
            % propagate forward in time puff model and store samples at each
            % time point
            t = obj.TIME_BETWEEN_REF_SAMPLES;
            for i=1:obj.numSamplesPerLocation,
                obj.propagateToTime(t);
                obj.referenceSamples(i,:)=obj.getSamplesAtTime(locs,t);
                t = t + obj.TIME_BETWEEN_REF_SAMPLES;
            end
            fprintf('reference distribution generation took %f seconds\n', toc);
        end
    end
end
