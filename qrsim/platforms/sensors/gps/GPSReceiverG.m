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
    
    properties (Access=private)
        svidx                       % array with the ids of the visible satellite vehicles
        nsv                         % number of satellite visible by this receiver
        pastEstimatedPosNED = zeros(3,1); % past North East Down coordinate returned by the receiver
        estimatedPosNED = zeros(3,1); % North East Down coordinate returned by the receiver
        originUTMcoords             % coordinates of the local reference frame
        R_SIGMA                     % receiver noise standard deviation
        receivernoise = zeros(3,1); % current receiver noise sample
        pastPositions = 0;          % array of past positions needed to simulate delay
        delay;                      % time delay 
        minmaxnumsv;                % limits for visible number of satellites
        totalnumsvs;                % total number of satellites in the space segment
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
            % Example:
            %
            %   obj=GPSReceiverG(objparams)
            %                objparams.dt - timestep of this object
            %                objparams.on - 1 if the object is active
            %                objparams.R_SIGMA - receiver noise standard deviation
            %                objparams.delay - time delay in multiples of receiver's dt
            %
            global state;
            obj=obj@GPSReceiver(objparams);

            obj.originUTMcoords = state.environment.area.params.originutmcoords;
            
            assert(isfield(objparams,'R_SIGMA'),'gpsreceiverg:nosigma','the platform config must define the gpsreceiver.R_SIGMA parameter');
            obj.R_SIGMA = objparams.R_SIGMA;
            assert(isfield(objparams,'delay'),'gpsreceiverg:nodelay','the platform config must define the gpsreceiver.delay parameter');
            obj.delay = objparams.delay;
            
            % pick randomly the satellites visible for this receiver
            assert(isfield(objparams,'minmaxnumsv'),'gpsreceiverg:nonumsvs','the platform config must define the gpsreceiver.minmaxnumsv parameter');
            obj.minmaxnumsv = objparams.minmaxnumsv;
            obj.totalnumsvs = length(state.environment.gpsspacesegment.params.svs);
            
            % init the ids of the visible satellites
            obj.reset();
        end
        
        
        function estimatedPosNED = getMeasurement(obj,X)
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
            
            estimatedPosNED = [obj.estimatedPosNED;...
                (obj.estimatedPosNED(1:2)-obj.pastEstimatedPosNED(1:2))/obj.dt];
            
        end
        
        function obj = reset(obj)
           % re-init the ids of the visible satellites
           %
           % Example:
           %
           %   obj.reset()
           %
           global state;
           obj.nsv = obj.minmaxnumsv(1)+randi(state.rStream,obj.minmaxnumsv(2)-obj.minmaxnumsv(1));
            
           obj.svidx = zeros(1,obj.nsv);
           r = randperm(state.rStream,obj.totalnumsvs);
           obj.svidx = r(1:obj.nsv); 
           
           obj.receivernoise = obj.R_SIGMA*randn(state.rStream,obj.nsv,1);
        end
        
        function obj = setState(obj,X)
            % reinitialise the current state and noise
            %
            % Example:
            %
            %   obj.setState(X)
            %       X - new platform state vector [px,py,pz,phi,theta,psi,u,v,w,p,q,r,thrust]
            %           only the first 3 elements of X are actually used
            %
            obj.estimatedPosNED = X(1:3);
            
            obj.pastEstimatedPosNED = X(1:3);
            
            obj.pastPositions = repmat(X(1:3),1,obj.delay);

            % now reset the visible satellites
            obj.reset();
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
            
            assert(isfield(state.environment.gpsspacesegment_,'svspos'), ...
                'In order to run a GPSReceiver needs the corresponding space segment!');
            
            if(obj.pastPositions == 0)
                obj.pastPositions = repmat(X(1:3),1,obj.delay);
            end
            
            obj.pastPositions = [obj.pastPositions,X(1:3)];
            pastPos = obj.pastPositions(:,1);
            obj.pastPositions = obj.pastPositions(:,2:end);
            
            truePosECEF = ned2ecef(pastPos, obj.originUTMcoords);
            
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
            
            if(sum(obj.pastEstimatedPosNED)~=0)
                obj.pastEstimatedPosNED = obj.estimatedPosNED;
                obj.estimatedPosNED = ecef2ned(p(1:3), obj.originUTMcoords);
            else
                % avoids silly velocities at startup
                obj.estimatedPosNED = ecef2ned(p(1:3), obj.originUTMcoords);
                obj.pastEstimatedPosNED = obj.estimatedPosNED;
            end
        end
    end
end

% [1] J. Rankin, "An error model for sensor simulation GPS and differential GPS," IEEE
%     Position Location and Navigation Symposium, 1994, pp.260-266.
