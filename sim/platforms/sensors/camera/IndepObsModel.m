classdef IndepObsModel<handle
    % class that models the image classifier observations by means of a simple
    % gaussian bi-modal model in which mean and variance of the modes
    % depends on the distance between the camera and the target.
    %
    % IndepObsModel methods:
    %
    %   reset()                  - reset model
    %   sample(which, xstar, ~)  - returns samples from the model
    %   updatePosterior()        - not used since the mesurements are assumed independent
    %   computeLogLikelihoodDifference(xqueryp, xqueryn, ~, ystar) - compute the log likelihood difference for the given samples
    %
    properties (Constant)
        % parameters of the observation model
        % derived from experimental data
        Ch = 11;
        ChM = 50;
        Cpm1 = 0.55;
        Cpm2 = 0.11;
        Cpm3 = 0.66
        Cpm4 = -0.005;
        Cpm5 = -0.1;
        Cpsd1 = 7.4e-05;
        Cpsd2 = -0.0061;
        Cpsd3 = 0.16;
        
        %Cpsd1 = 2.6e-05;
        %Cpsd2 = -0.0025;
        %Cpsd3 = 0.10;
        %Cnm1 = 0.416;
        %Cnsd1 = 0.055;
        %Cnsd2 = 0.025;
        
        Cnm1 = 0.34;
        Cnm2 = 0.076;
        Cnm3 = 0.416;
        Cnsd1 = 2.4e-05;
        Cnsd2 = -0.0016;
        Cnsd3 =  0.09; %0.125
        Cnsd4 =  0.04;
    end
    
    properties (Access=private)
        simState;    % handle to teh state data structure
        prngId;      % prng id
        camParams;   % camera parameters
        personSize;  % size of the person
    end
    
    methods
        function obj = IndepObsModel(objparams)
            % initialize the model
            %
            % Example:
            %  obj = IndepObsModel(objparams)
            %
            %    objparams.simState - handle to state data structure
            %    objparams.prngId   - unique pseudo random number generator id
            %    objparams.f        - camera focal length
            %    objparams.c        - camera center   
            %    objparams.psize    - person size
            %
            obj.simState = objparams.simState;
            obj.prngId = objparams.prngId;
            obj.camParams.f = objparams.f;
            obj.camParams.c = objparams.c;
            obj.personSize = objparams.psize;
        end
        
        function obj = reset(obj)
            % cleanup
        end
        
        function ystar = sample(obj, which, xstar, ~)
            % given a set inputs generates sample observations
            
            lx = size(xstar,1);
            ystar = zeros(lx,1);
            which = logical(which);
            lp = sum(which);
            ln = lx - lp;
            rndsample = randn(obj.simState.rStreams{obj.prngId},lx,1);
            
            % generate samples from gpp
            if(lp>0)
                xs = cell2mat(xstar(which));
                [mp,sdp] = obj.suffStatP(xs(:,3:4));
                ystar(which) = mp + sdp.*rndsample(1:lp);
            end
            
            % generate samples from gpn
            if(ln>0)
                xs = cell2mat(xstar(~which));
                [mn,sdn] = obj.suffStatN(xs(:,3:4));
                ystar(~which) = mn + sdn.*rndsample(lp+1:end);
            end
        end
        
        function llikd = computeLogLikelihoodDifference(obj, xqueryp, xqueryn, ~, ystar)
            % computes the likelihood ratio for the locations
            % xstars and the measurements ystar
            
            [mp,sdp] = obj.suffStatP(xqueryp(:,3:4) );
            [mn,sdn] = obj.suffStatN(xqueryn(:,3:4) );
            
            llikp = log(1./(sqrt(2*pi).*sdp))- 0.5*(((ystar-mp)./sdp).^2);
            llikn = log(1./(sqrt(2*pi).*sdn))- 0.5*(((ystar-mn)./sdn).^2);
            
            llikd = llikp-llikn;
        end
        
        function obj = updatePosterior(obj)
            % nothing to be done since the mesurements are assumed independent
        end
    end
    
    methods (Access=private)
        function [mp,sdp] = suffStatP(obj, hc)
            % return the sufficient statistics (mean and std)
            % for the distribution of positive scores at height h
            h = hc(:,1);
            h(h<0) = 0;
            h(h>obj.ChM) = obj.ChM;
            mp = (h<=obj.Ch).*(obj.Cpm1+obj.Cpm2*cos(pi*(1+h./obj.Ch)))+...
                (h>obj.Ch).*(obj.Cpm3+obj.Cpm4*(h-obj.Ch))+...
                obj.Cpm5.*(hc(:,2)==2);
            sdp = (obj.Cpsd1.*h + obj.Cpsd2).*h + obj.Cpsd3;
        end
        
        function [mn,sdn] = suffStatN(obj, hc)
            % return the sufficient statistics (mean and std)
            % for the distribution of positive scores at height h
            %mn = obj.Cnm1*ones(size(hc,1),1);
            %sdn = obj.Cnsd1 + obj.Cnsd2.*(hc(:,2)>=1);
            h = hc(:,1);
            h(h<0) = 0;
            h(h>obj.ChM) = obj.ChM;
            mn = (h<=obj.Ch).*(obj.Cnm1+(obj.Cnm2/obj.Ch)*h)+...
                (h>obj.Ch).*obj.Cnm3;
            sdn = (obj.Cnsd1.*h + obj.Cnsd2).*h + obj.Cnsd3 +...
                obj.Cnsd4.*(hc(:,2)==1);
        end
    end
end

