classdef GPObsModel<handle
    % modelling the image classifier observation by means of two GPs
    
    properties (Constant)
        % min area for person to be detectable (from tests on real images)
        minDetectArea = 60*60; % pixels
        
        % GP model P( score | target is present)
        % x = [px,py,r,tclass,d,sigma,inc,sazi,cazi]  if person is visible
        meanfuncP = {@meanSum, {@meanLinear, @meanConst}};
        %meanfuncP = {@meanConst};        
        hypPmean = [0; 0; 0; 1; 0; 1/3600; 0; 0; 0; 1];
        %hypPmean = [1];
        covfuncP = {@covSEard};
        %covfuncP = {@covSEiso};
        hypPcov = log([1; 1; 1; 3; 100; 10000; 2*pi; 1; 1; 0.2]);
        %hypPcov = log([1; 1; 1; 1; 1; 1; 1; 1; 1; 0.2]);
        %hypPcov = log([0.2;0.2]);
        likfuncP = {@likGauss};
        hypPlik = log(0.1); % Gaussian likelihood sd
        
        % GP model P( score | target is not present)
        % x = [px,py,r,tclass]  if person is not visible
        meanfuncN = {@meanSum, {@meanLinear, @meanConst}};
        %meanfuncN = {@meanConst};        
        %hypNmean = [0; 0; 1/100; -1/3; 1];
        hypNmean = [0; 0; 1; 1; 1];
        %hypNmean = [1];        
        covfuncN = {@covSEard};
        %covfuncN = {@covSEiso};        
        hypNcov = log([1; 1; 1; 3; 0.2]);
        %hypNcov = log([1; 1; 1; 1; 0.2]);        
        %hypNcov = log([0.2; 0.2]);
        likfuncN = {@likGauss};       
        hypNlik = log(0.1); % Gaussian likelihood sd
    end
    
    properties (Access=private)
        gpp;
        gpn;
        simState;
        prngId;
        camParams;
        groundDistHardCut;
        personSize;
    end
    
    methods 
        function obj = GPObsModel(objparams)
            
            % initialize the GPs
            obj.simState = objparams.simState;
            obj.prngId = objparams.prngId;
            obj.camParams.f = objparams.f;
            obj.camParams.c = objparams.c;
            obj.personSize = objparams.psize;
            % all the observations farther away than 1.5 times the frame diagonal
            % when at the max height at which persons are detectable are assumed
            % to be uncorrelated 
            
            maxDetectHeight = (objparams.f(1)*obj.personSize)/sqrt(obj.minDetectArea);            
            obj.groundDistHardCut = 1.5*norm(2*maxDetectHeight*objparams.c./objparams.f);
            
            obj.gpp = GPwrapper(obj.meanfuncP,obj.hypPmean,obj.covfuncP,obj.hypPcov,obj.likfuncP, obj.hypPlik,obj.groundDistHardCut,'P');
            obj.gpn = GPwrapper(obj.meanfuncN,obj.hypNmean,obj.covfuncN,obj.hypNcov,obj.likfuncN, obj.hypNlik,obj.groundDistHardCut,'N');
        end
        
        function reset(obj)
            % cleanup
            obj.gpp.reset();
            obj.gpn.reset();
        end
        
        function ystar = sample(obj, which, xstar, xcstar)
            % given a set of row inputs, we compute the
            % predictive distribution and sample from it
            
            lx = size(xstar,1);
            ystar = zeros(lx,1);
            which = logical(which);
            lp = sum(which);
            ln = lx - lp;
            rndsample = randn(obj.simState.rStreams{obj.prngId},lx,1);
            
            % generate samples from gpp
            if(lp>0)
                tmp = obj.gpp.sample(cell2mat(xstar(which)),xcstar,rndsample(1:lp));
                ystar(which) = tmp;
            end
            
            % generate samples from gpn
            if(ln>0)
                tmp = obj.gpn.sample(cell2mat(xstar(~which)),xcstar,rndsample(lp+1:end));
                ystar(~which) = tmp;
            end
        end
        
        function llikd = computeLogLikelihoodDifference(obj, xqueryp, xqueryn, xcstar, ystar)
            % compute the likelihood ratio for the locations
            % xstars and the measurements ystar
            n = size(ystar,1);
            llikd = zeros(n,1);
            
            for i=1:n
                llikp = obj.gpp.computeLogLikelihood(xqueryp(i,:), xcstar,ystar(i,:));
                llikn = obj.gpn.computeLogLikelihood(xqueryn(i,:), xcstar,ystar(i,:));
                
                llikd(i)=  llikp-llikn;
            end
        end
        
        function obj = updatePosterior(obj)
            % update the posterior of the two GPs based
            % on the data stored at sampling time
            obj.gpp.updatePosterior();
            obj.gpn.updatePosterior();
        end
    end
end

