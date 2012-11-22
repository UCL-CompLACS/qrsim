classdef GPSSpaceSegmentGM < GPSSpaceSegment
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
    %    update([])                  - propagates the noise state forward in time
    %    getTotalNumSVS(~)           - returns number of satellite vehicles
    %
    properties (Access=private)
        PR_BETA;                % process time constant (from [2])
        PR_SIGMA;               % process standard deviation (from [2])
        tStart;                 % simulation start GPS time
        randomTStart;           % true if the tStart is random
        prPrngIds;              % ids of the prng streams used for the pseudorange noises
        sPrngId;                % id of the prng stream used to select the start time
    end
    
    methods (Sealed,Access=public)        
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
            %                objparams.on - 1 if the object is active
            %                objparams.PR_BETA - process time constant
            %                objparams.PR_SIGMA - process standard deviation
            %                objparams.tStart - simulation start in GPS time
            %                objparams.orbitfile - satellites orbits
            %                objparams.svs - visible satellites
            %
            
            obj=obj@GPSSpaceSegment(objparams);
            
            assert(isfield(objparams,'tStart'),'gpsspacesegmentgm:notstart','The task must define a gps start time gpsspacesegment.tStart');
            obj.tStart = objparams.tStart;
            obj.randomTStart = (obj.tStart==0);
            
            assert(isfield(objparams,'PR_BETA'),'gpsspacesegmentgm:nobeta','The task must define a gpsspacesegment.PR_BETA');
            obj.PR_BETA = objparams.PR_BETA;
            
            assert(isfield(objparams,'PR_SIGMA'),'gpsspacesegmentgm:nosigma','The task must define a gpsspacesegment.PR_SIGMA');
            obj.PR_SIGMA = objparams.PR_SIGMA;
            
            % read in the precise satellite orbits
            assert(isfield(objparams,'orbitfile'),'gpsspacesegmentgm:noorbitfile','The task must define a gpsspacesegment.orbitfile');
            obj.simState.environment_.gpsspacesegment.stdPe = readSP3(Orbits, objparams.orbitfile);
            
            obj.simState.environment_.gpsspacesegment.stdPe.compute();
            
            assert(isfield(objparams,'svs'),'gpsspacesegmentgm:nosvs','The task must define a gpsspacesegment.svs');
            obj.simState.environment_.gpsspacesegment.svs = objparams.svs;
            
            % for each of the possible svs we initialize the
            % common part of the pseudorange noise models
            obj.simState.environment_.gpsspacesegment.nsv = length(objparams.svs);
                                    
            obj.prPrngIds = obj.simState.numRStreams+1:obj.simState.numRStreams+obj.simState.environment_.gpsspacesegment.nsv;
            obj.simState.numRStreams = obj.simState.numRStreams+obj.simState.environment_.gpsspacesegment.nsv+1;
            obj.sPrngId = obj.simState.numRStreams;
            
            obj.simState.environment_.gpsspacesegment.betas = (1/obj.PR_BETA)*ones(obj.simState.environment_.gpsspacesegment.nsv,1);
            obj.simState.environment_.gpsspacesegment.w = obj.PR_SIGMA*ones(obj.simState.environment_.gpsspacesegment.nsv,1);
        end
                
        function obj = reset(obj)
            % reinitialize the noise model

            [b,e] = obj.simState.environment_.gpsspacesegment.stdPe.tValidLimits();
            
            if(obj.randomTStart)
                obj.tStart=b+rand(obj.simState.rStreams{obj.sPrngId},1,1)*(e-b-obj.TBEFOREEND);
            end
            
            if((obj.tStart<b)||(obj.tStart>e))
                error('GPS start time out of sp3 file bounds');
            end
            
            obj.simState.environment_.gpsspacesegment.prns=zeros(obj.simState.environment_.gpsspacesegment.nsv,1);
            
            % spin up the noise process
            for i=1:randi(obj.simState.rStreams{obj.sPrngId},1000)
                % update noise states
                for j=1:obj.simState.environment_.gpsspacesegment.nsv
                    obj.simState.environment_.gpsspacesegment.prns(j) = obj.simState.environment_.gpsspacesegment.prns(j)*...
                        exp(-obj.simState.environment_.gpsspacesegment.betas(j)*obj.dt)...
                        +obj.simState.environment_.gpsspacesegment.w(j)*randn(obj.simState.rStreams{obj.prPrngIds(j)},1);
                end
            end            
            
            for j = 1:obj.simState.environment_.gpsspacesegment.nsv,
                %compute sv positions
                obj.simState.environment_.gpsspacesegment.svspos(:,j) = getSatCoord(obj.simState.environment_.gpsspacesegment.stdPe,...
                    obj.simState.environment_.gpsspacesegment.svs(j),(obj.tStart+obj.simState.t));
            end

	    obj.bootstrapped = 1;
        end
                        
        function n = getTotalNumSVS(~)
            % returns number of satellite vehicles
            n = obj.simState.environment_.gpsspacesegment.nsv;
        end
    end
    
    methods (Sealed,Access=protected)        
        function obj=update(obj,~)
            % propagates the noise state forward in time
            %
            % Note:
            %  this method is called automatically by the step() of the Steppable parent
            %  class and should not be called directly.
            %           
            
            % update noise states
            for j=1:obj.simState.environment_.gpsspacesegment.nsv
                obj.simState.environment_.gpsspacesegment.prns(j) = obj.simState.environment_.gpsspacesegment.prns(j)*...
                    exp(-obj.simState.environment_.gpsspacesegment.betas(j)*obj.dt)...
                    +obj.simState.environment_.gpsspacesegment.w(j)*randn(obj.simState.rStreams{obj.prPrngIds(j)},1);
            end
            
            obj.simState.environment_.gpsspacesegment.svspos=zeros(3,obj.simState.environment_.gpsspacesegment.nsv);
            for j = 1:obj.simState.environment_.gpsspacesegment.nsv,
                %compute sv positions
                obj.simState.environment_.gpsspacesegment.svspos(:,j) = getSatCoord(obj.simState.environment_.gpsspacesegment.stdPe,...
                    obj.simState.environment_.gpsspacesegment.svs(j),(obj.tStart+obj.simState.t));
            end
        end
    end
end

