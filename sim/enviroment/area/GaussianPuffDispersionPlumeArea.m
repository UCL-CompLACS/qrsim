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
        NUMSAMPLES = 300;
    end
    
    properties (Access=public)
        QRange;
        a;
        b;
        u;
        numSources;
        sources;
        sourcesW;
        numSourcesRange;
        C;
        iPrngId;
        sPrngId;
        cepsilon;
        vmean;
        mu;
        puffs;
        nextEmissionTimes;
        locations;
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
            obj.locations=[];
        end
        
        function c = getSamples(obj,pos)
            % compute the concentration at the requested locations
            
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
                
                dti = (obj.simState.t-obj.puffs(2,i));
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
        
        function locations = getLocations(obj)
            % generate random locations within the support
            % i.e. so that c(x,y,z)>epsilon            
            if(isempty(obj.locations))                
                obj.locations=zeros(3,obj.NUMSAMPLES);
                
                limits = reshape(obj.limits,2,3)';
                lph = 0.5*(limits(:,2)+limits(:,1));
                lm = (limits(:,2)-limits(:,1));
                
                n = obj.NUMSAMPLES;
                while (n > 0)
                    % generate n points within the area limits
                    ll = repmat(lph,1,n)+repmat(lm,1,n)...
                        .*(rand(obj.simState.rStreams{obj.iPrngId},3,n)-0.5);
                    
                    % compute average concentration at such points
                    c = obj.getSamplesFromAverage(ll);
                    
                    % keep the points whithin the support (i.e. c(x,y,z)>epsilon)
                    csup = (c>=obj.cepsilon);
                    ncsup = sum(csup);
                    idf = obj.NUMSAMPLES - n;
                    obj.locations(:,idf+(1:ncsup)) = ll(:,csup);
                    
                    % update number of samples needed
                    n = n - ncsup;
                end                
            end
            locations = obj.locations;
            
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
            
%             % generate past puffs
%             for i=1:obj.numSources
%                 % generate how many past puffs for this source
%                 nPastPuffi = randi(obj.simState.rStreams{obj.iPrngId},5);
%                 
%                 % previous puff time
%                 t = 0;
%                 for j=1:nPastPuffi
%                     q = obj.QRange(1)+(obj.QRange(2)-obj.QRange(1))*rand(obj.simState.rStreams{obj.iPrngId});
%                     t = t - obj.mu*(-log(rand(obj.simState.rStreams{obj.iPrngId})));
%                     obj.puffs(:,end+1) = [i;t;q];
%                 end
%             end
             
            %fprintf('starting with %d puffs\n',size(obj.puffs,1));
            % generate the times at which we expect a new emission for each source
            obj.nextEmissionTimes = obj.mu*(-log(rand(obj.simState.rStreams{obj.iPrngId},obj.numSources,1)));
            
            % mean wind
            obj.vmean = obj.simState.environment.wind.getLinear([0;0;-6;0;0;0]);
            
            % wind magnitude
            obj.u = norm(obj.vmean);
            assert((obj.u>0),'gaussianpuffdispersionplumearea:nopositivewind',...
                'If using a GaussianPuffDispersionPlumeArea, the wind must be turned on ond obj.W6 must be positive');
            
            % rotation global to wind frame
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
            for pi=1:size(obj.puffs,2)
                ti=(obj.simState.t-obj.puffs(2,pi));
                % 1% width of the Gaussian blob.
                w = sqrt(-log(0.01)*2*obj.a*(obj.u*ti)^obj.b);
                p = obj.C'*[obj.u*ti-w;0] + obj.sources(1:2,obj.puffs(1,pi));
                if((p(1)<obj.limits(1))||(p(1)>obj.limits(2))||(p(2)<obj.limits(3))||(p(2)>obj.limits(4)))
                    outside=[outside,pi]; %#ok<AGROW>
                end
            end
            if(~isempty(outside))
            obj.puffs(:,outside)=[];
            end
            % add any newly emitted puff
            for s=1:obj.numSources,
                %fprintf('t:%d, %d puffs\n',obj.simState.t,size(obj.puffs,2));
                while(obj.nextEmissionTimes(s)<obj.simState.t)
                    q = obj.QRange(1)+(obj.QRange(2)-obj.QRange(1))*rand(obj.simState.rStreams{obj.iPrngId});
                    % a puff is defined by source, time, and concentration
                    obj.puffs(:,end+1) = [s;obj.nextEmissionTimes(s);q];
                    obj.nextEmissionTimes(s) = obj.nextEmissionTimes(s) + obj.mu*(-log(rand(obj.simState.rStreams{obj.iPrngId})));                    
                    %fprintf('added puff@%f for source %d, next puff@%f\n',obj.puffs(2,end),s,obj.nextEmissionTimes(s)); 
                end
            end
            obj.cepsilon = 1e-5*obj.QRange(1);
            
            % refresh display
            if(~isempty(obj.graphics))
                locs = obj.getLocations();
                values = obj.getSamples(locs);
                obj.graphics.update(obj.simState,obj.sources,obj.vmean,locs,values);
            end
        end
    end
end
