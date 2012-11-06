classdef GPwrapper< handle
    % handy class to wrap parameters of a GP
    
    properties
        mf;
        hmean;
        cf;
        hcov;
        sn;
        
        Kinv;
        mu;
        x;
        y;
        
        % temp
        kbold;
        k;
        xstar;
        ystar;
        mustar;
    end
    
    methods
        function obj = GPwrapper(mf,hmean,cf,hcov,sn)
            obj.mf=mf{:};
            obj.hmean=hmean;
            obj.cf=cf{:};
            obj.hcov=hcov;
            obj.sn=sn;
        end
        
        function obj = reset(obj)
            obj.x = [];
            obj.y = [];
            obj.Kinv = [];
            obj.mu = [];
            obj.clearTemp();
        end
        
        function obj = clearTemp(obj)
            obj.kbold = [];
            obj.k = [];
            obj.xstar = [];
            obj.ystar = [];
            obj.mustar = [];
        end
        
        function ystar = sample(obj,xstar,rndsample)
            % generate samples
            obj.xstar = xstar;
            
            assert(isempty(obj.k)||isempty(obj.kbold)||isempty(obj.xstar)||isempty(obj.ystar),...
                'gpwrapper:sample','there should be no old data before a sampling!') % safety check
            
            % we keep the covariances and cross covariances to avoid
            % recomputing the when updating the posterior
            obj.kbold  = feval(obj.cf,obj.hcov,obj.x,xstar);
            obj.k = feval(obj.cf,obj.hcov,xstar);
            ms = feval(obj.cf,obj.hmean, xstar);
            
            tmp = obj.kbold'*obj.Kinv;
            obj.mustar = ms + tmp*(obj.y-obj.mu);
            s2 = obj.k - tmp*obj.kbold + obj.sn*obj.sn;
            
            % generate samples
            obj.ystar = obj.mustar + chol(s2)*rndsample;
            ystar = obj.ystar;
        end
        
        function lik = computeLikelihood(obj, xquery, ystar)
            kbold  = feval(obj.cf,obj.hcov,obj.x,xquery);%#ok<PROP>
            k = feval(obj.cf,obj.hcov,xquery);%#ok<PROP>
            ms = feval(obj.mf, obj.hmean, xquery);
            
            tmp = kbold'*obj.Kinv;%#ok<PROP>
            m = ms + tmp*(obj.y-obj.mu);
            s2 = k - tmp*kbold + obj.sn*obj.sn;%#ok<PROP>
            lik = (1/(2*pi*sqrt(s2)))*exp(-(0.5/s2)*(ystar-m)^2);
        end
        
        function obj = updatePosterior(obj)
            assert((~isempty(obj.k)&&~isempty(obj.kbold)&&~isempty(obj.ystar)&&~isempty(obj.xstar)&&~isempty(obj.mustar)),...
                'gpwrapper:update','there should be data to do an update!') % safety check
            
            n = length(obj.Kinv);
            l = length(obj.xstar);
            
            %still slow but for big matrices this is better than growing
            tmp = zeros(l+n,l+n);
            tmp(1:n,1:n) = obj.Kinv;
            obj.Kinv = tmp;
            
            for i=1:l
                % following MacKay 45.35-45.43
                if(i==1)
                    kbold = obj.kbold(:,i); %#ok<PROP>
                else
                    kbold = [obj.kbold(:,i);obj.k(1:i-1,i)]; %#ok<PROP>
                end
                m = 1/(obj.k(i,i) - kbold'*obj.Kinv(1:n,1:n)*kbold + obj.sn*obj.sn); %#ok<PROP>
                mbold = -m*obj.Kinv(1:n,1:n)*kbold; %#ok<PROP>
                Mbold = obj.Kinv(1:n,1:n) + (1/m)*(mbold*mbold');
                
                obj.Kinv(1:n,1:n) = Mbold;
                obj.Kinv(1:n,n+1) = mbold;
                obj.Kinv(n+1,1:n) = mbold';
                obj.Kinv(n+1,n+1) = m;
                
                n = n+1;
            end
            
            if(l>0)
                obj.x = [obj.x;obj.xstar];
                obj.y = [obj.y;obj.ystar];
                obj.mu = [obj.mu;obj.mustar];
                
                obj.clearTemp();
            end
        end
    end
end