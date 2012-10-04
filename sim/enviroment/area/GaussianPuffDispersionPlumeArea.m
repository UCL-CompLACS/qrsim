classdef GaussianPuffDispersionPlumeArea<PlumeArea
    % Defines a simple box shaped area in which is present a plume that is
    % emitted in puffs with esponential interemission time 
    % the resulting concentration is roghly described by blob like
    % puffs travelling downwind an expanding as the move away from the source
    %
    %
    % GaussianPuffDispersionPlumeArea Methods:
    %    GaussianPuffDispersionPlumeArea(objparams)   - constructs the object
    %    reset()                        - does nothing
    %    getOriginUTMCoords()           - returns origin
    %    getLimits()                    - returns limits
    %    isGraphicsOn()                 - returns true if there is a graphics objec associate with the area
    %
    
    properties (Constant)
        NUMSAMPLES = 1000;
    end
    
    properties (Access=public)
        QRange;
        a;
        b;
        u;
        numSources;
        sources;
        numSourcesRange;
        C;
        iPrngId;
        sPrngId;
        cepsilon;
        vmean;
        mu;
        puffs;
        nextEmissionTimes;
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
            %               objparams.sourceSigmaRange - min,max values for the width of the Gaussian concentration
            %                                         (with of the concentration along the principal axes is drawn
            %                                          randomly with uniform probability from the specified range)
            %               objparams.numSourcesRange - min,max number of sources in the area
            %               objparams.QRange - min,max emission rate of a source
            %               objparams.a - diffusion paramter
            %               objparams.b - diffusion paramter
            %               objparams.state - handle to the simulator state
            %               objparams.mu - mean interemission time
            %
            obj=obj@PlumeArea(objparams);
            
            obj.iPrngId = obj.simState.numRStreams+1;
            obj.sPrngId = obj.simState.numRStreams+2;
            obj.simState.numRStreams = obj.simState.numRStreams + 2;
            
            assert(isfield(objparams,'numSourcesRange'),'gaussianpuffdispersionplumearea:nonumsourcesrange',...
                'If using a GaussianPuffDispersionPlumeArea, the task must define the parameter numSourcesRange');
            obj.numSourcesRange = objparams.numSourcesRange;
            
            assert(isfield(objparams,'QRange'),'gaussianpuffdispersionplumearea:nonqrange',...
                'If using a GaussianPuffDispersionPlumeArea, the task must define the parameter QRange');
            obj.QRange = objparams.QRange;
            
            assert(isfield(objparams,'a'),'gaussianpuffdispersionplumearea:noa',...
                'If using a GaussianPuffDispersionPlumeArea, the task must define the dispersion parameter a');
            obj.a = objparams.a;
            
            assert(isfield(objparams,'b'),'gaussianpuffdispersionplumearea:nob',...
                'If using a GaussianPuffDispersionPlumeArea, the task must define the dispersion parameter b');
            obj.b = objparams.b;    
            
            assert(isfield(objparams,'mu'),'gaussianpuffdispersionplumearea:nomu',...
                'If using a GaussianPuffDispersionPlumeArea, the task must define the mean interemission time parameter mu');
            obj.mu = objparams.mu;
            
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
        end
        
        function c = getSamples(obj,pos)
            % compute the concentration at the requested locations
            
            n = size(pos,2);
            c = zeros(1,n);
           
            for i=1:size(obj.puffs,2),
                % transform location to source centered wind frame
                s = obj.puffs(1,i);
                pos(1,:)=pos(1,:)-obj.sources(1,s);
                pos(2,:)=pos(2,:)-obj.sources(2,s);                
                p = [obj.C*pos(1:2,:);...
                    pos(3,:)-obj.sources(3,s);...
                    pos(3,:)+obj.sources(3,s)];
                
                den = (2*obj.a*p(1,:).^obj.b);
                
                dti = (obj.simState.t-obj.puffs(2,i));
                ci = (obj.puffs(3,i)./((2*pi*den).^1.5)).*...
                     exp(-(((p(1,:)-obj.u*dti).^2+p(2,:).^2)./den)).*...
                     (exp(-((p(3,:).^2)./den))+exp(-((p(4,:).^2)./den))); 
                
                % the model is not valid for negative x...
                ci(p(1,:)<0)=0; 
                
                c = c+ci;
            end            
        end
        
        function locations = getLocations(obj)
            % generate random locations within the support
            % i.e. so that c(x,y,z)>epsilon
            
            locations=zeros(3,obj.NUMSAMPLES);
            
            limits = reshape(obj.limits,2,3)';
            lph = 0.5*(limits(:,2)+limits(:,1));
            lm = (limits(:,2)-limits(:,1));
            
            n = obj.NUMSAMPLES;
            while (n > 0)
                % generate n points within the area limits
                ll = repmat(lph,1,n)+repmat(lm,1,n)...
                    .*(rand(obj.simState.rStreams{obj.iPrngId},3,n)-0.5);
                
                % compute concentration at such points
                c = obj.getSamples(ll);
                
                % keep the points whithin the support (i.e. c(x,y,z)>epsilon)
                csup = (c>=obj.cepsilon);
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
            % generate the dispersion rates and the position of the sources
            
            % number of sources
            if (obj.numSourcesRange(2)~=obj.numSourcesRange(1))
                obj.numSources=obj.numSourcesRange(1)+...
                    randi(obj.simState.rStreams{obj.iPrngId},obj.numSourcesRange(2)-obj.numSourcesRange(1),1);
            else
                obj.numSources=obj.numSourcesRange(1);
            end
            obj.sources=zeros(3,obj.numSources);
            
            obj.cepsilon = 0;
            
            % sources position
            limits = reshape(obj.limits,2,3)';
            lph = 0.5*(limits(:,2)+limits(:,1));
            lm = 0.8*(limits(:,2)-limits(:,1));
            obj.sources = repmat(lph,1,obj.numSources)+repmat(lm,1,obj.numSources)...
                .*(rand(obj.simState.rStreams{obj.iPrngId},3,obj.numSources)-0.5);
            
            % empty puffs lists
            obj.puffs = [];
            
            % generate past puffs
            for i=1:obj.numSources
                % generate how many past puffs for this source
                nPastPuffi = randi(obj.simState.rStreams{obj.iPrngId},5);
                
                % previous puff time
                t = 0;
                for j=1:nPastPuffi
                    q = obj.QRange(1)+(obj.QRange(2)-obj.QRange(1))*rand(obj.simState.rStreams{obj.iPrngId});                   
                    t = t - obj.mu*(-log(rand(obj.simState.rStreams{obj.iPrngId})));                    
                    obj.puffs(:,end+1) = [i;t;q];
                end
            end
            
            % generate the times at which we expect a new emission for each source
            obj.nextEmissionTimes = obj.simState.t + obj.mu*(-log(rand(obj.simState.rStreams{obj.iPrngId},obj.numSources,1)));
            
            % mean wind
            obj.vmean = obj.simState.environment.wind.getLinear([0;0;-6;0;0;0]);
            
            % wind magnitude
            obj.u = norm(obj.vmean);
            assert((obj.u>0),'gaussianpuffdispersionplumearea:nopositivewind',...
                'If using a GaussianPuffDispersionPlumeArea, the wind must be turned on ond obj.W6 must be positive');
            
            % rotation body to wind frame
            obj.C=[obj.vmean(1),obj.vmean(2);-obj.vmean(2),obj.vmean(1)]./obj.u;
            
        end

        function obj = update(obj, ~)
            % takes care of updating/removing puffs
            %
            % Note:
            %  this method is called automatically by the step() of the Steppable parent
            %  class and should not be called directly.
            %
            
            % remove puffs that are out of the flying area
            outside=[];
            for i=1:size(obj.puffs,2)
               p = obj.C'*[obj.u*(obj.simState.t-obj.puffs(2,i));0] + obj.sources(obj.puffs(1,i));               
               if((p(1)<obj.limits(1))||(p(1)>obj.limits(2))||(p(2)<obj.limits(3))||(p(2)>obj.limits(4)))
                    outside=[outside,i]; %#ok<AGROW>
               end
            end    
            obj.puffs(:,outside)=[];
                        
            % add any newly emitted puff
            for i=1:obj.numSources,
                if(obj.nextEmissionTimes(i)<obj.simState.t)
                    q = obj.QRange(1)+(obj.QRange(2)-obj.QRange(1))*rand(obj.simState.rStreams{obj.iPrngId});
                    % a puff is defined by source, time, and concentration 
                    obj.puffs(:,end+1) = [i;obj.simState.t;q];
                    obj.nextEmissionTimes(i) = obj.nextEmissionTimes(i) + obj.mu*(-log(rand(obj.simState.rStreams{obj.iPrngId})));
                end    
            end   
            
            if(size(obj.puffs,2)~=0)
                obj.cepsilon = 1e-5*min(obj.puffs(3,:));
            end
            
            % refresh display
            if(~isempty(obj.graphics))
                locations = obj.getLocations();
                values = obj.getSamples(locations);
                obj.graphics.update(obj.simState,obj.sources,obj.vmean,locations,values);
            end
        end
    end
end
