classdef TaskPlumeMultiSourceGaussianDispersion<Task
    % plume mapping task in which one helicopter is used for the sampling,
    % its dynamics is stochastic and affected by wind disturbances (following a wind model),
    % the state returned is a noisy estimate of the platform state (i.e. with additional correlated noise).
    % The smoke concentration is static and has the form specified by the superposition 
    % of several sources each of which follows a Gaussian dispersion model.
    %
    % Note:
    % This task accepts control inputs in terms of 2D velocities,
    % in global coordinates.
    % qrsim.step(U);  where U = [vx; vy];
    %
    % TaskPlumeMultiSourceGaussianDispersion methods:
    %   init()         - loads and returns the parameters for the various simulation objects
    %   reset()        - defines the starting state for the task
    %   updateReward() - updates the running costs (zero for this task)
    %   reward()       - computes the final reward for this task
    %   step()         - computes pitch, roll, yaw, throttle  commands from the user dVn,dVe commands
    %   getLocations()                 - returns array of locations at which the prediction must be made
    %   getSamplesPerLocation()        - returns the number of samples to be returned for each of the locations
    %   setSamples()        - returns the predictions to the task so that a reward can be computed
    %
    properties (Constant)
        numUAVs = 1;
        startHeight = -10;
        durationInSteps = 1000;
        PENALTY = 1000;      % penalty reward in case of collision
    end
    
    properties (Access=public)
        prngId;   % id of the prng stream used to select the initial positions
        velPIDs;  % pid used to control the uavs
        receivedSamples;
        initialX;
        locations;
    end
    
    methods (Sealed,Access=public)
        
        function obj = TaskPlumeMultiSourceGaussianDispersion(state)
            obj = obj@Task(state);
        end
        
        function taskparams=init(obj) 
            % loads and returns the parameters for the various simulation objects
            %
            % Example:
            %   params = obj.init();
            %          params - the task parameters
            %
            
            taskparams.dt = 1; % task timestep i.e. rate at which controls
                               % are supplied and measurements are received
            
            taskparams.seed = 0; %set to zero to have a seed that depends on the system time
            
            %%%%% visualization %%%%%
            % 3D display parameters
            taskparams.display3d.on = 1;
            taskparams.display3d.width = 1000;
            taskparams.display3d.height = 600;
            
            %%%%% environment %%%%%
            % these need to follow the conventions of axis(), they are in m, Z down
            % note that the lowest Z limit is the refence for the computation of wind shear and turbulence effects
            taskparams.environment.area.limits = [-140 140 -140 140 -80 0];
            taskparams.environment.area.type = 'GaussianDispersionPlumeArea';
            taskparams.environment.area.a = 0.33; %dispersion parameter from [1]
            taskparams.environment.area.b = 0.86; %dispersion parameter from [1]
            taskparams.environment.area.numSourcesRange = [1,5]; %range of number of sources
            taskparams.environment.area.QRange = [0.1,2.5];%*1e-3; %range of emission rates
            taskparams.environment.area.numreflocations = 100; %number of reference locations in space used for reward computation
            
            % originutmcoords is the location of the RVC (our usual flying site)
            % generally when this is changed gpsspacesegment.orbitfile and
            % gpsspacesegment.svs need to be changed
            [E N zone h] = llaToUtm([51.71190;-0.21052;0]);
            taskparams.environment.area.originutmcoords.E = E;
            taskparams.environment.area.originutmcoords.N = N;
            taskparams.environment.area.originutmcoords.h = h;
            taskparams.environment.area.originutmcoords.zone = zone;
            taskparams.environment.area.graphics.type = 'PlumeAreaGraphics';
            taskparams.environment.area.graphics.backgroundimage = 'ucl-rvc-zoom.tif';
            
            % GPS
            % The space segment of the gps system
            taskparams.environment.gpsspacesegment.on = 1; 
            taskparams.environment.gpsspacesegment.dt = 0.2;
            % real satellite orbits from NASA JPL
            taskparams.environment.gpsspacesegment.orbitfile = 'ngs15992_16to17.sp3';
            % simulation start in GPS time, this needs to agree with the sp3 file above,
            % alternatively it can be set to 0 to have a random initialization
            %taskparams.environment.gpsspacesegment.tStart = Orbits.parseTime(2010,8,31,16,0,0);
            taskparams.environment.gpsspacesegment.tStart = 0;
            % id number of visible satellites, the one below are from a typical flight day at RVC
            % these need to match the contents of gpsspacesegment.orbitfile
            taskparams.environment.gpsspacesegment.svs = [3,5,6,7,13,16,18,19,20,22,24,29,31];
            % the following model is from [2]
            %taskparams.environment.gpsspacesegment.type = 'GPSSpaceSegmentGM';
            %taskparams.environment.gpsspacesegment.PR_BETA = 2000;     % process time constant
            %taskparams.environment.gpsspacesegment.PR_SIGMA = 0.1746;  % process standard deviation
            % the following model was instead designed to match measurements of real
            % data, it appears more relistic than the above
            taskparams.environment.gpsspacesegment.type = 'GPSSpaceSegmentGM2';
            taskparams.environment.gpsspacesegment.PR_BETA2 = 4;       % process time constant
            taskparams.environment.gpsspacesegment.PR_BETA1 =  1.005;  % process time constant
            taskparams.environment.gpsspacesegment.PR_SIGMA = 0.003;   % process standard deviation
            
            % Wind
            % i.e. a steady omogeneous wind with a direction and magnitude
            % this is common to all helicopters
            taskparams.environment.wind.on = 1;  
            taskparams.environment.wind.type = 'WindConstMean';
            taskparams.environment.wind.direction = []; %mean wind direction, rad clockwise from north set to [] to initialise it randomly
            taskparams.environment.wind.W6 = 2;  % velocity at 6m from ground in m/s
            
            %%%%% platforms %%%%%
            % Configuration and initial state for each of the platforms
            for i=1:obj.numUAVs,
                taskparams.platforms(i).configfile = 'pelican_config_plume_noisy_windy'; 
            end            

            % get hold of a prng stream
            obj.prngId = obj.simState.numRStreams+1;
            obj.simState.numRStreams = obj.simState.numRStreams + 1;
        end
        
        function reset(obj)
            % uav randomly placed, but not too close to the edges of the area
            for i=1:obj.numUAVs,
                
                r = rand(obj.simState.rStreams{obj.prngId},2,1);
                l = obj.simState.environment.area.getLimits();
                
                px = 0.5*(l(2)+l(1)) + (r(1)-0.5)*0.9*(l(2)-l(1));
                py = 0.5*(l(4)+l(3)) + (r(2)-0.5)*0.9*(l(4)-l(3));
                
                obj.simState.platforms{i}.setX([px;py;obj.startHeight;0;0;0]);
                obj.initialX{i} = obj.simState.platforms{i}.getX();
                               
                obj.velPIDs{i} = VelocityPID(obj.simState.DT);
            end
        end
        
        function UU = step(obj,U)
            % compute the UAVs controls from the velocity inputs
            UU=zeros(5,length(obj.simState.platforms));
            for i=1:length(obj.simState.platforms),
                if(obj.simState.platforms{i}.isValid())
                    UU(:,i) = obj.velPIDs{i}.computeU(obj.simState.platforms{i}.getEX(),U(:,i),0);
                else
                    UU(:,i) = obj.velPIDs{i}.computeU(obj.simState.platforms{i}.getEX(),[0;0],0);
                end
            end
        end
        
        function updateReward(~,~)
            % updates reward
            % in this task we only have a final cost
        end
        
        function l = getLocations(obj)
            % return a list of x,y,z point for which the agent is
            % expected to return predictions            
            l = obj.simState.environment.area.getLocations();
        end
        
        function obj = setSamples(obj,samples)
            % used by the agent to pass back the concentration value
            % computed at the points specified by getLocations()            
            obj.receivedSamples = samples;
        end
        
        function r=reward(obj)
            % returns the total reward for this task            
            assert(~isempty(obj.receivedSamples),'TaskPlumeSingleSourceGaussianDispersion:nosamples',...
                'Before asking for a task reward, return a set of sample concentrations using setConcentrations(s)');
            
            valid = 1;
            for i=1:length(obj.simState.platforms)
                valid = valid &&  obj.simState.platforms{i}.isValid();
            end
            
            if(valid)                
                % the reward is simply the L2 norm (multiplied by -1 of course)
                r = - sum((obj.simState.environment.area.getReferenceSamples()-obj.receivedSamples).^2);
            else
                % returning a large penalty in case the state is not valid
                % i.e. one the helicopters is out of the area, there was a
                % collision or one of the helicoptera has crashed
                r = - obj.PENALTY;
            end
        end
                
        function spl = getSamplesPerLocation(obj)
            % returns the number of samples to be returned for each of the locations 
            spl = obj.simState.environment.area.getSamplesPerLocation();
        end
                
        function rs = getReferenceSamples(obj)
            % returns true samples from the underlying model
            % this should be used only for debugging 
            rs = obj.simState.environment.area.getReferenceSamples();
        end
    end
    
end

%[1] JOHN M. STOCKIE  The Mathematics of Atmospheric Dispersion Modeling SIAM REVIEW Vol. 53, No. 2, pp. 349–372

