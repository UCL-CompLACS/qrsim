classdef GPwrapper< handle
    % handy class to wrap parameters of a GP
    
    properties
        isFirst;
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
            obj.mf=mf;
            obj.hmean=hmean;
            obj.cf=cf;
            obj.hcov=hcov;
            obj.sn=sn;
            obj.isFirst = 1;
        end
        
        function obj = reset(obj)
            obj.x = [];
            obj.y = [];
            obj.Kinv = [];
            obj.mu = [];
            obj.clearTemp();
            obj.isFirst = 1;
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
            n = size(xstar,1);
            
            % we keep the covariances and cross covariances to avoid
            % recomputing the when updating the posterior
            if(obj.isFirst)
                obj.k = feval(obj.cf{:},obj.hcov,xstar);
                
                % k(x^p,x^q) = sf^2 * exp(-(x^p - x^q)'*inv(P)*(x^p - x^q)/2) 
                %
                % where the P matrix is ell^2 times the unit matrix and sf^2 is the signal
                % variance. The hyperparameters are:
                %
                % hyp = [ log(ell)
                %         log(sf)  ]
                %mm = size(xstar,1);
                %nn = size(xstar,2);
                %kxx = zeros(mm);
                %sf2 = exp(obj.hcov(2))^2;
                %ell2 = exp(obj.hcov(1))^2;
                %for ii=1:mm
                %    for jj=1:mm
                %        diff = (xstar(ii,:)-xstar(jj,:));
                %        kxx(ii,jj)=sf2*exp((-diff*(eye(nn)./ell2)*diff')./2);
                %    end
                %end
                
                obj.mustar = feval(obj.mf{:},obj.hmean, xstar);
                s2 = obj.k + obj.sn*obj.sn;
            else
                obj.kbold  = feval(obj.cf{:},obj.hcov,obj.x,xstar);
                obj.k = feval(obj.cf{:},obj.hcov,xstar);
                ms = feval(obj.mf{:},obj.hmean, xstar);
                
                tmp = obj.kbold'*obj.Kinv;
                obj.mustar = ms + tmp*(obj.y-obj.mu);
                s2 = obj.k - tmp*obj.kbold + obj.sn*obj.sn;
            end
            % generate samples
            obj.ystar = obj.mustar + chol(s2)*rndsample;
            ystar = obj.ystar;
        end
        
        function lik = computeLogLikelihood(obj, xquery, ystar)
            assert(size(xquery,1)==1,'logLikelihood of one sample athe the time only'); 
            
            if(obj.isFirst)
                k = feval(obj.cf{:},obj.hcov,xquery);%#ok<PROP>
                m = feval(obj.mf{:}, obj.hmean, xquery);
                s2 = k + obj.sn*obj.sn;%#ok<PROP>
            else
                kbold  = feval(obj.cf{:},obj.hcov,obj.x,xquery);%#ok<PROP>
                k = feval(obj.cf{:},obj.hcov,xquery);%#ok<PROP>
                ms = feval(obj.mf{:}, obj.hmean, xquery);
                
                tmp = kbold'*obj.Kinv;%#ok<PROP>
                m = ms + tmp*(obj.y-obj.mu);
                s2 = k - tmp*kbold + obj.sn*obj.sn;%#ok<PROP>
            end
            
            lik = log(1/(2*pi*sqrt(s2)))+(-(0.5/s2)*(ystar-m)^2);
        end
        
        function obj = updatePosterior(obj)
            
            disp(size(obj.Kinv,1));

            l = size(obj.xstar,1);
            if(l>0)     
                
                assert((obj.isFirst)||((~isempty(obj.k)&&~isempty(obj.kbold)&&...
                ~isempty(obj.ystar)&&~isempty(obj.xstar)&&~isempty(obj.mustar))),...
                'gpwrapper:update','there should be data to do an update!') % safety check
                
                
                if(obj.isFirst)
                    obj.Kinv = inv(obj.k);
                    obj.isFirst = 0;
                else
                    n = size(obj.Kinv,1);
                    tmp = zeros(l+n,l+n);
                    M = inv(obj.k-obj.kbold'*obj.Kinv*obj.kbold + obj.sn*obj.sn*eye(l));
                    tmp(1:n,1:n) = obj.Kinv + obj.Kinv*obj.kbold*M*obj.kbold'*obj.Kinv; %#ok<MINV>
                    tmp(1:n,n+1:n+l) = -obj.Kinv*obj.kbold*M;%#ok<MINV>
                    tmp(n+1:n+l,1:n) = tmp(1:n,n+1:n+l)';
                    tmp(n+1:n+l,n+1:n+l) = M;
                    obj.Kinv = tmp;                    

%                   %alternative one row at the time version 
%                     tmp(1:n,1:n) = obj.Kinv;
%                     obj.Kinv = tmp;
%                     for i=1:l
%                         % following MacKay 45.35-45.43
%                         if(i==1)
%                             kbold = obj.kbold(:,i); %#ok<PROP>
%                         else
%                             kbold = [obj.kbold(:,i);obj.k(1:i-1,i)]; %#ok<PROP>
%                         end
%                         m = 1/(obj.k(i,i) - kbold'*obj.Kinv(1:n,1:n)*kbold + obj.sn*obj.sn); %#ok<PROP>
%                         mbold = -m*obj.Kinv(1:n,1:n)*kbold; %#ok<PROP>
%                         Mbold = obj.Kinv(1:n,1:n) + (1/m)*(mbold*mbold');
%                         
%                         obj.Kinv(1:n,1:n) = Mbold;
%                         obj.Kinv(1:n,n+1) = mbold;
%                         obj.Kinv(n+1,1:n) = mbold';
%                         obj.Kinv(n+1,n+1) = m;
%                         
%                         n = n+1;
%                     end
                end
                
                obj.x = [obj.x;obj.xstar];
                obj.y = [obj.y;obj.ystar];
                obj.mu = [obj.mu;obj.mustar];
                
                obj.clearTemp();
            end
        end
    end
end