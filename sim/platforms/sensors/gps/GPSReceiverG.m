classdef GPSReceiverG < GPSReceiver
    % Class that simulates a noisy GPS receivers.
    % Given the current position of the satellite vehicles and pseudorange noise
    % (from GPSStaceSegmentGM) the receiver position is computed using ordinary LS.
    % Given the small size of the platform the location of the receiver's
    % antenna phase center is assumed to coincide with the vehicle center
    % of mass.
    % Global variables are used to maintain the noise states shared between receivers.
    %
    % GPSReceiverG Properties:
    %    v_light                    - speed of light (Constant)
    %
    % GPSReceiverG Methods:
    %    GPSReceiverG(objparams)    - constructor
    %    getMeasurement(X)          - computes and returns a GPS estimate given the input
    %                                 noise free NED position
    %    update(X)                  - generates a new noise sample
    %    setState(X)                - reinitializes the current state and noise
    %    reset()                    - re-init the ids of the visible satellites
    %
    properties (Constant)
        v_light = 299792458;        % speed of light (Constant)
    end
    
    properties (Access=public)
        svidx;                      % array with the ids of the visible satellite vehicles
        nsv;                        % number of satellite visible by this receiver
        pastEstimatedPosNED;        % past North East Down coordinate returned by the receiver
        originUTMcoords;            % coordinates of the local reference frame
        R_SIGMA;                    % receiver noise standard deviation
        receivernoise;              % current receiver noise sample
        delayedPositionsNED;        % array of past positions needed to simulate delay
        delay;                      % time delay
        minmaxnumsv;                % limits for visible number of satellites
        totalnumsvs;                % total number of satellites in the space segment
        nPrngId;                    % id of the prng stream used by the noise model
        sPrngId;                    % id of the prng stream used to select the visible satellites
    end
    
    methods (Sealed,Access=public)
        function obj=GPSReceiverG(objparams)
            % constructs the object.
            % Selects the satellite vehicles visible to this receiver among the ones in
            % objparams.svs the total number of visible satellites is generate
            % randomly (uniform number between objparams.minmaxnumsv(1) and
            % objparams.minmaxnumsv(2)). The selection of satellites is kept FIX during
            % all the simulation.
            %
            % Example:
            %
            %   obj=GPSReceiverG(objparams)
            %                objparams.dt - timestep of this object
            %                objparams.on - 1 if the object is active
            %                objparams.R_SIGMA - receiver noise standard deviation
            %                objparams.delay - time delay in multiples of receiver's dt
            %
            
            obj=obj@GPSReceiver(objparams);
            
            obj.nPrngId = obj.simState.numRStreams+1;
            obj.sPrngId = obj.simState.numRStreams+2;
            obj.simState.numRStreams = obj.simState.numRStreams + 2;
            
            obj.originUTMcoords = obj.simState.environment.area.getOriginUTMCoords();
            
            assert(isfield(objparams,'R_SIGMA'),'gpsreceiverg:nosigma','the platform config must define the gpsreceiver.R_SIGMA parameter');
            obj.R_SIGMA = objparams.R_SIGMA;
            assert(isfield(objparams,'delay'),'gpsreceiverg:nodelay','the platform config must define the gpsreceiver.delay parameter');
            obj.delay = objparams.delay;
            
            % pick randomly the satellites visible for this receiver
            assert(isfield(objparams,'minmaxnumsv'),'gpsreceiverg:nonumsvs','the platform config must define the gpsreceiver.minmaxnumsv parameter');
            obj.minmaxnumsv = objparams.minmaxnumsv;
            obj.totalnumsvs = obj.simState.environment.gpsspacesegment.getTotalNumSVS();
        end
        
        function estimatedPosVelNED = getMeasurement(obj,~)
            % returns a GPS estimate given the current noise free position
            %
            % Example:
            %
            %   [~px;~py;~pz;~pxdot;~pydot] = obj.getMeasurement(X)
            %       X - platform noise free state vector [px,py,pz,phi,theta,psi,u,v,w,p,q,r,thrust]
            %       ~px,~py,~pz      [m]     position estimated by GPS (NED coordinates)
            %       ~pxdot           [m/s]   x velocity from GPS (NED coordinates)
            %       ~pydot           [m/s]   y velocity from GPS (NED coordinates)
            %
            
            estimatedPosVelNED = obj.estimatedPosVelNED;
        end
        
        function obj = reset(obj)
            % re-init the ids of the visible satellites
            %
            % Example:
            %
            %   obj.reset()
            %

            obj.nsv = (obj.minmaxnumsv(1)-1)+randi(obj.simState.rStreams{obj.sPrngId},obj.minmaxnumsv(2)-obj.minmaxnumsv(1)+1);
            
            obj.svidx = zeros(1,obj.nsv);
            r = randperm(obj.simState.rStreams{obj.sPrngId},obj.totalnumsvs);
            obj.svidx = r(1:obj.nsv);
            obj.receivernoise = obj.R_SIGMA*randn(obj.simState.rStreams{obj.nPrngId},obj.nsv,1);
            
            obj.pastEstimatedPosNED = obj.solveFromObservations(obj.pastEstimatedPosNED);            
            obj.estimatedPosVelNED(1:3,1) = obj.solveFromObservations(obj.estimatedPosVelNED(1:3,1));           
            obj.estimatedPosVelNED(4:5,1) = (obj.estimatedPosVelNED(1:2,1) - obj.pastEstimatedPosNED(1:2,1))./obj.dt;
            
            obj.bootstrapped = obj.bootstrapped +1;
        end
        
        function obj = setState(obj,X)
            % re-initialise the state to a new value
            %
            % Example:
            %
            %   obj.setState(X)
            %       X - platform noise free state vector [px,py,pz,phi,theta,psi,u,v,w,p,q,r,thrust]
            %
            %
            % make up the delayed from the velocities
            % assuming a constant velocity that is
            
            gvel = (dcm(X)')*X(7:9);
            obj.estimatedPosVelNED = [X(1:3);gvel(1:2)];
                        
            obj.delayedPositionsNED = zeros(3,obj.delay);
            for i=obj.delay:-1:1,
                obj.delayedPositionsNED(:,i) = X(1:3) - gvel*(obj.delay-i)*obj.dt;
            end  
            obj.estimatedPosVelNED(1:3,1) = X(1:3) - gvel*obj.delay*obj.dt;
            obj.estimatedPosVelNED(4:5,1) = gvel(1:2,1);
            
            obj.pastEstimatedPosNED = X(1:3) - gvel*(obj.delay+1)*obj.dt;
            
            obj.bootstrapped = 0;
        end
    end
    
    methods (Sealed, Access=protected)
        
        function estimatedPosNED = solveFromObservations(obj,posNED)
            % compute position solution given the pseudorange observations
            
            truePosECEF = nedToEcef(posNED, obj.originUTMcoords);
            
            obs = zeros(obj.nsv,1);
            for i = 1:obj.nsv,
                % compute pseudorange
                obs(i,1) = norm(truePosECEF-obj.simState.environment_.gpsspacesegment.svspos(:,obj.svidx(i)))...
                    +obj.simState.environment_.gpsspacesegment.prns(obj.svidx(i))...
                    +obj.receivernoise(i);
            end
            
            % ordinary lest square solution initialised at the previous solution
            p = [obj.pastEstimatedPosNED;0];
            for iter = 1:4 % even 3 iterations should do since we prime it
                A = zeros(obj.nsv,4);
                omc = zeros(obj.nsv,1); % observed minus computed observation
                for i = 1:obj.nsv,
                    XX = obj.simState.environment_.gpsspacesegment.svspos(:,obj.svidx(i));
                    omc(i,:) = obs(i)-norm(XX-p(1:3),'fro')-p(4);
                    A(i,:) = [(-(XX(1)-p(1)))/obs(i),(-(XX(2)-p(2)))/obs(i),(-(XX(3)-p(3)))/obs(i),1];
                end % i
                x = A\omc;
                p = p+x;
            end % iter
            
            estimatedPosNED = ecefToNed(p(1:3), obj.originUTMcoords);
        end
    end
    
    methods (Sealed,Access=protected)
        
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
            
            obj.receivernoise = obj.R_SIGMA*randn(obj.simState.rStreams{obj.nPrngId},obj.nsv,1);
            
            assert(isfield(obj.simState.environment_.gpsspacesegment,'svspos'), ...
                'In order to run a GPSReceiver needs the corresponding space segment!');
            
            % delay chain
            obj.delayedPositionsNED = [obj.delayedPositionsNED,X(1:3)];
            delayedPos = obj.delayedPositionsNED(:,1);
            obj.delayedPositionsNED = obj.delayedPositionsNED(:,2:end);
            
            estimatedPosNED = obj.solveFromObservations(delayedPos);
            
            obj.pastEstimatedPosNED = obj.estimatedPosVelNED(1:3);
            obj.estimatedPosVelNED(1:3) =  estimatedPosNED;            
            obj.estimatedPosVelNED(4:5) = (estimatedPosNED(1:2) - obj.pastEstimatedPosNED(1:2))/obj.dt;
        end
    end
end

% [1] J. Rankin, "An error model for sensor simulation GPS and differential GPS," IEEE
%     Position Location and Navigation Symposium, 1994, pp.260-266.
