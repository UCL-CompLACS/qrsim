classdef GPSSpaceSegmentGM < SteppablePRNG
    % Class that simulates the correlate noise affecting the GPS pseudorange.
    % The running assumption is that all the receivers are (approximately) geographically
    % co-located so that pseudorange measurements to the same satellite vehicle obtained
    % by different receivers are strongly correlated.
    %
    % At each epoch the position of each satellite vehicles is determined interpolating
    % the precise orbits file (SP3) defined in params.environment.gpsspacesegment.preciseorbitfile,
    % pseudorange errors are considered additive and modelled by a Gauss-Markov process [1][2].
    % Global variables are used to maintain the noise states shared between receivers.
    %
    % [1] J. Rankin, "An error model for sensor simulation GPS and differential GPS," IEEE
    %     Position Location and Navigation Symposium, 1994, pp.260-266.
    % [2] Carlson, Justin, "Mapping Large, Urban Environments with GPS-Aided SLAM" (2010).
    %     Dissertations. Paper 44.
    %
    % GPSSpaceSegmentGM Properties:
    %    PR_BETA                    - process time constant (from [2])
    %    PR_SIGMA                   - process standard deviation (from [2])
    %    tStart                     - simulation start GPS time
    %
    % GPSSpaceSegmentGM Methods:
    %    GPSSpaceSegmentGM(objparams)- constructor
    %    update([])                 - propagates the noise state forward in time
    %
    
    properties (Access=private)
        PR_BETA                     % process time constant (from [2])
        PR_SIGMA                    % process standard deviation (from [2])
        tStart                      % simulation start GPS time
    end
    
    methods
        
        function obj=GPSSpaceSegmentGM(objparams)
            % constructs the object.
            % Loads and interpoates the satellites orbits and creates and initialises a
            % Gauss-Markov process for each of the GPS satellite vehicles.
            % These processes represent additive noise to the pseudorange measurement
            % of each satellite.
            %
            % Example:
            %
            %   obj=GPSSpaceSegmentGM(objparams);
            %       objparams - gps parameters defined in general config file
            %
            global state;
            
            obj=obj@SteppablePRNG(objparams);
            
            obj.PR_BETA = objparams.PR_BETA;
            obj.PR_SIGMA = objparams.PR_SIGMA;
            obj.tStart = objparams.tStart;
            
            
            % read in the precise satellite orbits
            state.environment.gpsspacesegment.stdPe = readSP3(Orbits, objparams.preciseorbitfile);
            state.environment.gpsspacesegment.stdPe.compute();
            
            state.environment.gpsspacesegment.svs = objparams.svs;
            
            % for each of the possible svs we initialize the
            % common part of the pseudorange noise models
            state.environment.gpsspacesegment.nsv = length(objparams.svs);
            state.environment.gpsspacesegment.prns=zeros(state.environment.gpsspacesegment.nsv,1);
            
            state.environment.gpsspacesegment.betas = (1/obj.PR_BETA)*ones(state.environment.gpsspacesegment.nsv,1);
            state.environment.gpsspacesegment.w = obj.PR_SIGMA*ones(state.environment.gpsspacesegment.nsv,1);
            
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
            
            % update noise states
            state.environment.gpsspacesegment.prns = state.environment.gpsspacesegment.prns.*...
                exp(-state.environment.gpsspacesegment.betas*obj.dt)...
                +state.environment.gpsspacesegment.w.*randn(obj.rStream,...
                state.environment.gpsspacesegment.nsv,1);
            
            state.environment.gpsspacesegment.svspos=zeros(3,state.environment.gpsspacesegment.nsv);
            for j = 1:state.environment.gpsspacesegment.nsv,
                %compute sv positions
                state.environment.gpsspacesegment.svspos(:,j) = getSatCoord(state.environment.gpsspacesegment.stdPe,...
                    state.environment.gpsspacesegment.svs(j),(obj.tStart+state.t));
            end
        end
    end
end

