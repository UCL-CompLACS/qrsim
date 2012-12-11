classdef GPwrapper< handle
    % handy class to wrap parameters of a GP
    % note that we make hard assumptions about the correlations
    % mostly depending ond ground distance to reduce computation
    
    properties (Constant)
        MAXIN = 500; % no matter what we never ever allow more than
        % this number of inputs in computing predictions
        MAXADD = 20; % no matter what we never ever allow more than
        % this number of inputs to be added from a single frame
    end
    
    properties (Access=private)
        name;
        isFirst;
        mf;
        cf;
        lf;
        hyp;
        sn;
        
        x;
        y;
        
        dCut;
        xstar;
        ystar;
        
        L;
        alpha;
        sW;
        id;
    end
    
    methods (Access=public)
        function obj = GPwrapper(mf,hmean,cf,hcov,lf,hlik,dCut,name)
            % initialize the GP models give mean covariance and likelihood
            % functions and parametars
            obj.mf=mf;
            obj.hyp.mean=hmean;
            obj.cf=cf;
            obj.hyp.cov=hcov;
            obj.lf=lf;
            obj.hyp.lik=hlik;
            obj.isFirst = 1;
            obj.dCut = dCut;
            obj.name = name;
        end
        
        function obj = reset(obj)
            % reset all teh data structures
            obj.x = [];
            obj.y = [];
            obj.xstar = [];
            obj.ystar = [];
            obj.isFirst = 1;
            obj.L = [];
            obj.alpha = [];
            obj.sW = [];
            obj.id = [];
        end
        
        function ystar = sample(obj,xstar,xcstar,rndsample)
            % generate samples from the observation model
            obj.xstar = xstar;
            
            assert(isempty(obj.L)||isempty(obj.id)||isempty(obj.sW)||isempty(obj.alpha)||isempty(obj.xstar)||isempty(obj.ystar),...
                'gpwrapper:sample','there should be no old data before a sampling!') % safety check
            
            %fprintf(['sample GP ',obj.name]);
            sn2 = exp(2*obj.hyp.lik);
            % we keep the covariances and cross covariances to avoid
            % recomputing the when updating the posterior
            if(obj.isFirst)
                k = feval(obj.cf{:},obj.hyp.cov,xstar);
                m = feval(obj.mf{:},obj.hyp.mean, xstar);
                s2 = k + sn2*eye(size(xstar,1));
            else
                obj.computeInvCovFactors(xcstar);
                kss = feval(obj.cf{:}, obj.hyp.cov, xstar);   % self-variance
                Ks  = feval(obj.cf{:}, obj.hyp.cov, obj.x(obj.id,:), xstar);  % cross-covariances
                ms = feval(obj.mf{:}, obj.hyp.mean, xstar);
                m = ms + Ks'*obj.alpha;          % predictive means
                V  = obj.L'\(repmat(obj.sW,1,size(xstar,1)).*Ks);
                s2 = kss - V'*V + sn2*eye(size(xstar,1)); % predictive variances
            end
            %fprintf([' predicted ',num2str(num2str(size(xstar,1))),'\n']);
            % generate samples
            obj.ystar = m + chol(s2)'*rndsample;
            ystar = obj.ystar;
        end
        
        function [lik,m,s2] = computeLogLikelihood(obj,xquery,xcstar,ystar)
            % log likelihood of the passed measurement according to the
            % positive and negative GP models
            
            assert(size(xquery,1)==1,'logLikelihood of one sample at the time only!');
            sn2 = exp(2*obj.hyp.lik);
            
            if(obj.isFirst)
                k = feval(obj.cf{:},obj.hyp.cov,xquery);
                m = feval(obj.mf{:}, obj.hyp.mean, xquery);
                s2 = k + sn2;
            else
                if(isempty(obj.L)||isempty(obj.sW)||isempty(obj.id)||isempty(obj.alpha))
                    obj.computeInvCovFactors(xcstar);
                end
                kss = feval(obj.cf{:}, obj.hyp.cov, xquery);   % self-variance
                Ks  = feval(obj.cf{:}, obj.hyp.cov, obj.x(obj.id,:), xquery);  % cross-covariances
                ms = feval(obj.mf{:}, obj.hyp.mean, xquery);
                m = ms + Ks'*obj.alpha;          % predictive means
                V  = obj.L'\(repmat(obj.sW,1,size(xquery,1)).*Ks);
                s2 = kss - V'*V + sn2;     % predictive variances
            end
            lik = feval(obj.lf{:}, obj.hyp.lik, ystar, m,s2);
        end
        
        function obj = updatePosterior(obj)
            % update the model posterior to take into account the
            % observation returned
            
            if(~isempty(obj.xstar))
                if(obj.isFirst)
                    obj.isFirst = 0;
                end
                
                n = size(obj.xstar,1);
                if(n>obj.MAXADD)
                    idx = randperm(n,obj.MAXADD);
                    obj.x = [obj.x;obj.xstar(idx,:)];
                    obj.y = [obj.y;obj.ystar(idx)];
                else
                    obj.x = [obj.x;obj.xstar];
                    obj.y = [obj.y;obj.ystar];
                end
                obj.L = [];
                obj.alpha = [];
                obj.sW = [];
                obj.id = [];
                obj.xstar = [];
                obj.ystar = [];
            end
            %after = size(obj.x,1);
            %fprintf(['update GP ',obj.name,' x=',num2str(after),' just added ',num2str(after-before),'\n']);
        end
    end
    
    methods (Access = private)
        function obj = computeInvCovFactors(obj,xcstar)
            % fetch input that are close to the centersample
            obj.id = knnradiussearch(xcstar,obj.x(:,1:size(xcstar,2)),obj.dCut,[]);
            % if still too many only the lucky ones remain
            nidxclose = find(obj.id==1);
            nclose = size(nidxclose,1);
            %fprintf([' close points ',num2str(nclose)]);
            if(nclose>obj.MAXIN)
                obj.id(nidxclose(randperm(nclose,nclose-obj.MAXIN)))=false;
            end
            n = sum(obj.id);
            %fprintf([' used ',num2str(n)]);
            K = feval(obj.cf{:},obj.hyp.cov,obj.x(obj.id,:));
            m = feval(obj.mf{:},obj.hyp.mean,obj.x(obj.id,:));
            sn2 = exp(2*obj.hyp.lik);
            obj.L = chol(K/sn2+eye(n));
            obj.alpha = solve_chol(obj.L,obj.y(obj.id)-m)/sn2;
            obj.sW = ones(n,1)/sqrt(sn2);  % sqrt of noise precision vector
        end
    end
end