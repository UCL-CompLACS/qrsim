classdef GPObsModel<handle
    % modelling the image classifier observation by means of two GPs
    
    properties (Constant)
        % GP model P( score | target is present)
        meanfuncP = {@meanSum, {@meanLinear, @meanConst}};
        hypPmean = [0.5; 0.7; 1];
        covfuncP = {@covSEiso};
        lP = 1/4; sfP = 1;
        hypPcov = log([lP; sfP]);
        snP = 0.1; % Gaussian likelihood sd
        
        % GP model P( score | target is not present)
        meanfuncN = {@meanSum, {@meanLinear, @meanConst}};
        hypNmean = [0.5; 0.7; 1];
        covfuncN = {@covSEiso};
        lN = 1/4; sfN = 1;
        hypNcov = log([lN; sfN]);
        snN = 0.1; % Gaussian likelihood sd
    end
    
    properties (Access=private)
        gpp;
        gpn;
        simState;
        prngId;
    end
    
    methods
        function obj = GPObsModel(simState, prngId)
            % initialize the GPs
            obj.simState = simState;
            obj.prngId = prngId;
            obj.gpp = GPwrapper(obj.meanfuncP,obj.hypPmean,obj.covfuncP,obj.hypPcov,obj.snP);
            obj.gpn = GPwrapper(obj.meanfuncN,obj.hypNmean,obj.covfuncN,obj.hypNcov,obj.snN);
        end
        
        function reset(obj)
            % cleanup
            obj.gpp.reset();
            obj.gpn.reset();
        end
        
        function ystar = sample(obj, which, xstar)
            % given a set of row inputs, we compute the
            % predictive distribution and sample from it
            
            lx = length(xstar);
            ystar = zeros(lx,1);
            which = logical(which);
            lp = sum(which);
            rndsample = randn(obj.simState.rStreams{obj.prngId},size(xstar,1),1);
            
            % generate samples from gpp
            tmp = obj.gpp.sample(cell2mat(xstar(which)),rndsample(1:lp));
            ystar(which) = tmp;
            
            % generate samples from gpn
            tmp = obj.gpn.sample(cell2mat(xstar(~which)),rndsample(lp+1:end));
            ystar(~which) = tmp;
        end
        
        function likr = computeLikelihoodRatio(obj, xqueryp, xqueryn, ystar)
            % compute the likelihood ratio for the locations
            % xstars and the measurements ystar
            likp = obj.gpp.computeLikelihood(xqueryp,ystar);            
            likn = obj.gpn.computeLikelihood(xqueryn,ystar);
            
            likr = likp./likn;
        end
        
        function obj = updatePosterior(obj)
            % update the posterior of the two GPs based
            % on the data stored at sampling time
            obj.gpp.updatePosterior();
            obj.gpn.updatePosterior();
        end        
    end    
end

