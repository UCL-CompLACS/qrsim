classdef GPSReceiverG < GPSReceiver
    % Class that simulates a noisy GPS receivers.
    % Given the current position of the satellite vehicles and pseudorange noise
    % (from GPSStaceSegmentGM) the receiver position is computed using ordinary LS.
    % Global variables are used to maintain the noise states shared between receivers.
    %
    % GPSReceiverG Properties:
    %    v_light                    - speed of light (Constant)
    %
    % GPSReceiverG Methods:
    %    GPSReceiverG(objparams)    - constructor
    %    getMeasurement(X)          - computes and returns a GPS estimate given the input
    %                                 noise free NED position
    %    update(X)                 - generates a new noise sample
    %
    properties (Constant)
        v_light = 299792458;        % speed of light (Constant)
    end
    
    properties (Access=private)
        svidx                       % array with the ids of the visible satellite vehicles
        nsv                         % number of satellite visible by this receiver
        estimatedPosNED = zeros(3,1); % North East Down coordinate returned by the receiver
        originUTMcoords             % coordinates of the local reference frame
        R_SIGMA                     % receiver noise standard deviation
        receivernoise = zeros(3,1); % current receiver noise sample
    end
    
    methods
        
        function obj=GPSReceiverG(objparams)
            % constructs the object.
            % Selects the satellite vehicles visible to this receiver among the ones in
            % objparams.svs the total number of visible satellites is generate
            % randomly (uniform number between objparams.minmaxnumsv(1) and
            % objparams.minmaxnumsv(2)). The selection of satellites is kept FIX during
            % all the simulation.
            %
            %
            % Example:
            %
            %   obj=GPSReceiverG(objparams)
            %                objparams.dt - timestep of this object
            %                objparams.DT - global simulation timestep
            %                objparams.on - 1 if the object is active
            %                objparams.originutmcoords - coordinates of the local reference frame
            %                objparams.R_SIGMA - receiver noise standard deviation
            %
            global state;
            obj=obj@GPSReceiver(objparams);
            
            obj.originUTMcoords = objparams.originutmcoords;
            obj.R_SIGMA = objparams.R_SIGMA;
            
            % pick randomly the satellites visible for this receiver
            obj.nsv = objparams.minmaxnumsv(1)...
                +randi(state.rStream,objparams.minmaxnumsv(2) ...
                -objparams.minmaxnumsv(1));
            
            obj.svidx = zeros(1,obj.nsv);
            r = randperm(state.rStream,objparams.tnsv);
            obj.svidx = r(1:obj.nsv);
        end
        
        
        function estimatedPosNED = getMeasurement(obj,X)
            % returns a GPS estimate given the current noise free position
            %
            % Example:
            %
            %   estimatedPosNED = obj.getMeasurement(X)
            %                     X - platform noise free state vector [px,py,pz,phi,theta,...
            %                         psi,u,v,w,p,q,r,thrust]
            %                     estimatedPosNED - 3 by 1 vector [m] estimated position
            %
            % Note: if active == 0, no noise is added, in other words:
            % estimatedPosNED = X(1:3)
            %
            fprintf('get measurement GPSReceiverG active=%d\n',obj.active);
            if(obj.active == 1)
                
                estimatedPosNED = obj.estimatedPosNED;
            else
                estimatedPosNED = X(1:3);
            end            
        end        
    end
    
    methods (Access=protected)
        
        function obj=update(obj,X)
            % generates a new noise sample and computes a position estimate
            % The method converts the current noiseless receiver position X(1:3), to ECEF
            % coordinates and using the current satellite vehicles positions and pseudorange
            % noise (from GPSStaceSegmentGM) solves a LS problem to estimate the receiver
            % location. The resulting location is returned after converting it to NED
            % coordinates.
            %
            % Note:
            %  this method is called automatically by the step() of the Steppable parent
            %  class and should not be called directly.
            %

            global state;
            obj.receivernoise = obj.R_SIGMA*randn(state.rStream,obj.nsv,1);
            
            if(~exist('state.environment.gpsspacesegment_.svspos','var'))
                error('In order to run a GPSReceiver needs the corresponding space segment!');
            end
                        
            truePosECEF = ned2ecef(X(1:3), obj.originUTMcoords);
            
            obs = zeros(obj.nsv,1);
            for i = 1:obj.nsv,
                % compute pseudorange
                obs(i,1) = norm(truePosECEF-state.environment.gpsspacesegment_.svspos(:,obj.svidx(i)))...
                    +state.environment.gpsspacesegment_.prns(obj.svidx(i))...
                    +obj.receivernoise(i);
            end
            
            % ordinary lest square solution initialised at the previous solution
            p = [obj.estimatedPosNED;0];
            for iter = 1:5 % even 3 iterations should do since we prime it
                A = zeros(obj.nsv,4);
                omc = zeros(obj.nsv,1); % observed minus computed observation
                for i = 1:obj.nsv,
                    XX = state.environment.gpsspacesegment_.svspos(:,obj.svidx(i));
                    omc(i,:) = obs(i)-norm(XX-p(1:3),'fro')-p(4);
                    A(i,:) = [(-(XX(1)-p(1)))/obs(i),(-(XX(2)-p(2)))/obs(i),(-(XX(3)-p(3)))/obs(i),1];
                end % i
                x = A\omc;
                p = p+x;
            end % iter
            
            obj.estimatedPosNED = ecef2ned(p(1:3), obj.originUTMcoords);
        end
    end    
end

% [1] J. Rankin, "An error model for sensor simulation GPS and differential GPS," IEEE
%     Position Location and Navigation Symposium, 1994, pp.260-266.
