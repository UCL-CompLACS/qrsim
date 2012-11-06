classdef GPObsModel<handle
    % modelling the image classifier observation by means of two GPs
    
    properties
        % GP model P( score | target is present)
        meanfuncP = {@meanSum, {@meanLinear, @meanConst}};
        hypPmean = [0.5; 0.7; 1];
        covfuncP = {@covSEiso};
        lP = 1/4; sfP = 1;
        hypPcov = log([lP; sfP]);
        snP = 0.1; % Gaussian likelihood sd
        KinvP;
        muP;
        
        % GP model P( score | target is not present)
        meanfuncN = {@meanSum, {@meanLinear, @meanConst}};
        hypNmean = [0.5; 0.7; 1];
        covfuncN = {@covSEiso};
        lN = 1/4; sfN = 1;
        hypNcov = log([lN; sfN]);
        snN = 0.1; % Gaussian likelihood sd
        KinvN;
        muN;
        
        x;
        y;
        simState;
        prngId;
    end
    
    methods
        function obj = GPObsModel(simState, prngId)
          obj.simState = simState;
          obj.prngId = prngId;
        end
        
        function reset(obj)
           % cleanup 
           obj.KinvN = [];
           obj.muN = [];
           obj.KinvP = [];
           obj.muP = []; 
           obj.x = [];
           obj.y = [];
        end
            
        function ystar = sampleP(obj, xstar)
            % given a set of row inputs, we compute the
            % predictive distribution and sample from it
            obj.kboldP  = feval(obj.covfuncP{:},obj.hypPcov,obj.x,xstar);
            obj.kP = feval(obj.covfuncP{:},obj.hypPcov,xstar);
            ms = feval(obj.meanfuncP{:}, obj.hypPmean, xstar);
            
            tmp = obj.kboldP'*obj.KinvP;
            m = ms + tmp*(y-obj.muP);
            s2 = obj.kP - tmp*obj.kboldP + obj.snP*obj.snP;
            
            % generate samples
            ystar = m + chol(s2)*randn(obj.simState.rStreams{obj.prngId},size(xstar,1),1);
        end
        
        function ystar = sampleN(obj, xstar)
            % given a set of row inputs, we compute the
            % predictive distribution and sample from it
            obj.kboldN  = feval(obj.covfuncN{:},obj.hypNcov,obj.x,xstar);
            obj.kN = feval(obj.covfuncN{:},obj.hypNcov,xstar);
            ms = feval(obj.meanfuncN{:}, obj.hypNmean, xstar);
            
            tmp = obj.kboldN'*obj.KinvN;
            m = ms + tmp*(obj.y-obj.muN);
            s2 = obj.kN - tmp*obj.kboldN + obj.snN*obj.snN;
            
            % generate samples
            ystar = m + chol(s2)*randn(obj.simState.rStreams{obj.prngId},size(xstar,1),1);
        end
        
        function likr = computeLikelihoodRatio(obj, xstarP, xstarN, ystar)
            
            kboldN  = feval(obj.covfuncN{:},obj.hypNcov,obj.x,xstar);
            kN = feval(obj.covfuncN{:},obj.hypNcov,xstar);
            ms = feval(obj.meanfuncN{:}, obj.hypNmean, xstar);
            
            tmp = kboldN'*obj.KinvN;
            mN = ms + tmp*(y-obj.muN);
            s2N = kN - tmp*kboldN + obj.snN*obj.snN;
            
            likN = (1/(2*pi*sqrt(s2N)))*exp(-(0.5/s2N)*(ystar-mN)^2);
            
            
            kboldP  = feval(obj.covfuncP{:},obj.hypPcov,obj.x,xstar);
            kP = feval(obj.covfuncP{:},obj.hypPcov,xstar);
            ms = feval(obj.meanfuncP{:}, obj.hypPmean, xstar);
            
            tmp = kboldP'*obj.KinvP;
            mP = ms + tmp*(y-obj.muP);
            s2P = kP - tmp*obj.kboldP + obj.snP*obj.snP;
            likP = (1/(2*pi*sqrt(s2P)))*exp(-(0.5/s2P)*(ystar-mP)^2);
            
            likr = likP/likN;            
        end
        
        function updatePosterior()
            % following MacKay 45.35-45.43
            m = 1/(k - obj.kbold'*obj.Kinv*obj.kbold + (exp(hyp.lik)^2));
            mbold = -m*Cinv*kbold;
            Mbold = Cinv + (1/m)*(mbold*mbold');
            
            Cinv = [ Mbold mbold ; mbold' m];
            mu = [mu;mfast]; %#ok<AGROW>
        end
        
    end
    
end

