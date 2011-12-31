classdef GPSSpaceSegmentGM < Steppable & EnvironmentObject
    % Class that simulates the correlate noise affecting the GPS pseudorange.
    % The running assumption is that all the receivers are (approximately) geographically
    % co-located so that pseudorange measurements to the same satellite vehicle obtained
    % by different receivers are strongly correlated.
    %
    % At each epoch the position of each satellite vehicles is determined interpolating
    % the precise orbits file (SP3) defined in params.environment.gpsspacesegment.orbitfile,
    % pseudorange errors are considered additive and modelled by a Gauss-Markov process [1][2].
    % Global variables are used to maintain the noise states shared between receivers.
    %
    % [1] J. Rankin, "An error model for sensor simulation GPS and differential GPS," IEEE
    %     Position Location and Navigation Symposium, 1994, pp.260-266.
    % [2] Carlson, Justin, "Mapping Large, Urban Environments with GPS-Aided SLAM" (2010).
    %     Dissertations. Paper 44.
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
            %                objparams.dt - timestep of this object
            %                objparams.DT - global simulation timestep
            %                objparams.on - 1 if the object is active 
            %                objparams.PR_BETA - process time constant
            %                objparams.PR_SIGMA - process standard deviation 
            %                objparams.tStart - simulation start in GPS time
            %
            global state;
            
            obj=obj@Steppable(objparams);
            obj=obj@EnvironmentObject(objparams);            
            
            obj.PR_BETA = objparams.PR_BETA;
            obj.PR_SIGMA = objparams.PR_SIGMA;
            obj.tStart = objparams.tStart;            
            
            % read in the precise satellite orbits
            state.environment.gpsspacesegment_.stdPe = readSP3(Orbits, objparams.orbitfile);
            state.environment.gpsspacesegment_.stdPe.compute();
            [b,e] = state.environment.gpsspacesegment_.stdPe.tValidLimits();
            
            % if tStart is zero we define the start time randomly
            if(obj.tStart==0)
               obj.tStart=b+rand(1,1)*(e-b);
            end 
          
            if((obj.tStart<b)||(obj.tStart>e))
               error('GPS start time out of sp3 file bounds');
            end   
            
            state.environment.gpsspacesegment_.svs = objparams.svs;
            
            % for each of the possible svs we initialize the
            % common part of the pseudorange noise models
            state.environment.gpsspacesegment_.nsv = length(objparams.svs);
            state.environment.gpsspacesegment_.prns=zeros(state.environment.gpsspacesegment_.nsv,1);
            
            state.environment.gpsspacesegment_.betas = (1/obj.PR_BETA)*ones(state.environment.gpsspacesegment_.nsv,1);
            state.environment.gpsspacesegment_.w = obj.PR_SIGMA*ones(state.environment.gpsspacesegment_.nsv,1);
            
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
            disp('stepping GPSSpaceSegmentGM');
            % update noise states
            state.environment.gpsspacesegment_.prns = state.environment.gpsspacesegment_.prns.*...
                exp(-state.environment.gpsspacesegment_.betas*obj.dt)...
                +state.environment.gpsspacesegment_.w.*randn(state.rStream,...
                state.environment.gpsspacesegment_.nsv,1);
            
            state.environment.gpsspacesegment_.svspos=zeros(3,state.environment.gpsspacesegment_.nsv);
            for j = 1:state.environment.gpsspacesegment_.nsv,
                %compute sv positions
                state.environment.gpsspacesegment_.svspos(:,j) = getSatCoord(state.environment.gpsspacesegment_.stdPe,...
                    state.environment.gpsspacesegment_.svs(j),(obj.tStart+state.t));
            end
        end
    end
end

