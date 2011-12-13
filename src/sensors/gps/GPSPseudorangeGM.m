classdef GPSPseudorangeGM < GPS
    % Class that simulates one of a set of noisy GPS receivers.
    % The running assumption is that all the receivers are (approximately) geographically 
    % co-located so that pseudorange measurements to the same satellite vehicle obtained 
    % by different receivers are strongly correlated.
    %
    % When computing a solution the position of each satellite vehicles is determined 
    % interpolating the precise orbits file (SP3) defined in params.sensors.gps.preciseorbitfile,
    % pseudorange errors are considered additive and modelled by a Gauss-Markov process [1][2], 
    % the receiver position is computed using ordinary LS. 
    % Global variables are used to maintain the noise states shared between receivers. 
    %
    % [1] J. Rankin, "An error model for sensor simulation GPS and differential GPS," IEEE 
    %     Position Location and Navigation Symposium, 1994, pp.260-266.
    % [2] Carlson, Justin, "Mapping Large, Urban Environments with GPS-Aided SLAM" (2010). 
    %     Dissertations. Paper 44.
    % 
    % GPSPseudorangeGM Properties:
    %    v_light                    - speed of light (Constant)
    %    PR_BETA                    - process time constant (from [2])           
    %    PR_SIGMA                   - process standard deviation (from [2])
    %    R_SIGMA                    - receiver noise standard deviation (from [1])   
    %
    % GPSPseudorangeGM Methods:
    %    GPSPseudorangeGM(objparams)- constructor
    %    init(objparams)            - initialises the state of the noise process       
    %    compute(truePosNED)        - computes and returns a GPS estimate given the input 
    %                                 noise free NED position
    %    update([])                 - propagates the noise state forward in time
    %
    properties (Constant)
        v_light = 299792458;        % speed of light (Constant)
    end
    
    properties (Access=private)
        svidx                       % array with the ids of the visible satellite vehicles
        nsv                         % number of satellite visible by this receiver
        estimatedPosNED = zeros(3,1); % North East Down coordinate returned by the receiver
        originUTMcoords             % coordinates of the local reference frame
        tStart                      % simulation start GPS time 
        PR_BETA                     % process time constant (from [2])           
        PR_SIGMA                    % process standard deviation (from [2])
        R_SIGMA                     % receiver noise standard deviation 
    end
    
    methods
                
        function obj=GPSPseudorangeGM(objparams)
            % constructs the object.
            % Selects the satellite vehicles visible to this receiver among the ones in 
            % objparams.svs the total number of visible satellites is generate 
            % randomly (uniform number between objparams.minmaxnumsv(1) and 
            % objparams.minmaxnumsv(2)). The selection of satellites is kept FIX during 
            % all the simulation. 
            %
            % Note:
            %   This methods calls init(objparams) if this is the first object/receiver being
            %   instantiated.
            %
            % Example:
            %
            %   obj=GPSPseudorangeGM(objparams);
            %       objparams - gps parameters defined in general config file
            %
            global state;
                        
            obj=obj@GPS(objparams);
            
            obj.originUTMcoords = objparams.originutmcoords;
            obj.tStart = objparams.tStart;
            obj.PR_BETA = objparams.PR_BETA;
            obj.PR_SIGMA = objparams.PR_SIGMA; 
            obj.R_SIGMA = objparams.R_SIGMA;            
            
            obj.init(objparams);
            
            % pick randomly the satellites visible for this receiver
            obj.nsv = objparams.minmaxnumsv(1)...
                     +randi(obj.rStream,objparams.minmaxnumsv(2) ...
                     -objparams.minmaxnumsv(1));
            
            obj.svidx = zeros(1,obj.nsv);
            r = randperm(obj.rStream,state.sensors.gps.nsv);
            obj.svidx = r(1:obj.nsv);
        end
        
        function obj = init(obj, objparams)
            % initialises the state of the noise process.
            % Creates and initialises a Gauss-Markov process for each of the GPS satellite
            % vehicles. These processes represent additive noise to the pseudorange measurement 
            % of each satellite.
            %
            % Example:
            %
            %   obj.init(objparams);
            %       objparams - gps parameters defined in general config file
            %
            global state;
            
            if(~exist('state.sensors.gps.exists','var') || (state.sensors.gps.exists ==0))
                
                % read in the precise satellite orbits
                state.sensors.gps.stdPe = readSP3(Orbits, objparams.preciseorbitfile);
                state.sensors.gps.stdPe.compute();
                
                state.sensors.gps.svs = objparams.svs;
                
                % for each of the possible svs we initialize the
                % common part of the pseudorange noise models                
                state.sensors.gps.nsv = length(objparams.svs);
                state.sensors.gps.prns=zeros(state.sensors.gps.nsv,1);
                
                state.sensors.gps.betas = (1/obj.PR_BETA)*ones(state.sensors.gps.nsv,1);
                state.sensors.gps.w = obj.PR_SIGMA*ones(state.sensors.gps.nsv,1);
                
                state.sensors.gps.t = 0;                
                                
                state.sensors.gps.exists = 1;
            end
        end
        
        function estimatedPosNED = getMeasurement(obj,truePosNED)
            % computes and returns a GPS estimate given the current noise free position
            % The method converts the current noiseless receiver position truePosNED, to ECEF
            % coordinates and given the current time, computes the satellite vehicles positions. 
            % For each satellite it then computes the pseudorange, to which the current 
            % noise is added together with a receiver dependent white noise component.
            % It uses LS to estimate the receiver location and returns it after converting
            % it to NED coordinates.
            %
            % Example:
            %
            %   estimatedPosNED = obj.compute(truePosNED)   
            %                     truePosNED - 3 by 1 vector [m] noiseless position
            %                     estimatedPosNED - 3 by 1 vector [m] estimated position
            %
            % Note: if active == 0, no noise is added, in other words:
            % estimatedPosNED = truePosNED
            %     
      
            global state;
            
            if(obj.active == 1)
            
                r = rem(state.t,obj.dt);
                if((r<obj.TOL)||((obj.dt-r)<obj.TOL))

                    truePosECEF = ned2ecef(truePosNED, obj.originUTMcoords);

                    obs = zeros(obj.nsv,1);
                    for i = 1:obj.nsv,
                        % compute pseudorange
                        obs(i,1) = norm(truePosECEF-state.sensors.gps.svspos(:,obj.svidx(i)))...
                                  +state.sensors.gps.prns(obj.svidx(i))...
                                  +obj.R_SIGMA*randn(1,1);
                    end

                    % ordinary lest square solution initialised at the previous solution
                    p = [obj.estimatedPosNED;0];
                    for iter = 1:5 % even 3 iterations should do since we prime it
                        A = zeros(obj.nsv,4);
                        omc = zeros(obj.nsv,1); % observed minus computed observation
                        for i = 1:obj.nsv,
                            X = state.sensors.gps.svspos(:,obj.svidx(i));
                            omc(i,:) = obs(i)-norm(X-p(1:3),'fro')-p(4);
                            A(i,:) = [(-(X(1)-p(1)))/obs(i),(-(X(2)-p(2)))/obs(i),(-(X(3)-p(3)))/obs(i),1];
                        end % i
                        x = A\omc;
                        p = p+x;
                    end % iter

                    obj.estimatedPosNED = ecef2ned(p(1:3), obj.originUTMcoords);
                else 
                    % no need to update return last measurement
                end
            
            else
                obj.estimatedPosNED = truePosNED;
            end
            
            estimatedPosNED = obj.estimatedPosNED;

        end
        
    end
    
    methods (Access=protected)
        
        function obj=update(obj,~)
            % propagates the noise state forward in time
            %
            % Note:
            %  this method is called automatically by the step() of the Steppable parent 
            %  class and should not be called directly.
            %
            global state;
            
            % we update the noise only once per timestep
            if(state.sensors.gps.t ~= (obj.tStart+state.t))
                
                state.sensors.gps.t = (obj.tStart+state.t);
                
                % update noise states
                state.sensors.gps.prns = state.sensors.gps.prns.*exp(-state.sensors.gps.betas*obj.dt)...
                                     +state.sensors.gps.w.*randn(obj.rStream,state.sensors.gps.nsv,1);
                
                state.sensors.gps.svspos=zeros(3,state.sensors.gps.nsv);
                for j = 1:state.sensors.gps.nsv,
                    %compute sv positions
                    state.sensors.gps.svspos(:,j) = getSatCoord(state.sensors.gps.stdPe,...
                                                    state.sensors.gps.svs(j),state.sensors.gps.t);
                end
            end
        end
    end
    
end
