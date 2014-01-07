classdef TaskHoldingPattern < Task
    % Note:
    % This task accepts control inputs (for each cat) in terms of 2D velocities,
    % in global coordinates. So in the case of three cats one would use
    % qrsim.step(U);  where U = [vx_1,vx_2,vx_3; vy_1,vy_2,vy_3];
    %
    % TaskCatsMouseNoiseless methods:
    %   init()         - loads and returns the parameters for the various simulation objects
    %   reset()        - defines the starting state for the task
    %   updateReward() - updates the running costs (zero for this task)
    %   reward()       - computes the final reward for this task
    %   step()         - computes pitch, roll, yaw, throttle  commands from the user dVn, dVe commands
    
    % Constants
    properties (Constant)
        landingPosition = [0;0;0];   % Position of landing zone
        durationInSteps = 1000;      % Number of time ticks
        numPlatforms    = 3;         % Number of platforms
        maxSpeed        = 3;         % Maximum holding speed
        minSpeed        = 2;         % Minimum holding speed
        maxDistance     = 60         % Maximum distance
        hfix            = 10;        % Fixed flight altitude
        PENALTY         = 1000;      % penalty reward in case of collision
    end
    
    % Publicly accessible properties
    properties (Access=public)
        accReward;                   % Accumulated reward
        prngId;                      % ID of the prng stream used to select the initial positions
        velPIDs;                     % PID used to control the uavs
    end
    
    % Publicly accessible methods
    methods (Sealed,Access=public)
        
        % Constructor
        function obj = TaskHoldingPattern(state)
            obj = obj@Task(state);
        end

        % Initialise the task
        function taskparams = init(obj)
            
            % General
            taskparams.dt   = 1; % Rate at which control is issues
            taskparams.seed = 0; % Initialization depends on system time
            
            % Visualisation
            taskparams.display3d.on = 1;
            taskparams.display3d.width = 1000;
            taskparams.display3d.height = 600;
            
            % Video (optional)
            taskparams.display3d.video = VideoWriter('holdingpattern.avi');
            taskparams.display3d.video.FrameRate = 1/taskparams.dt;
            taskparams.display3d.video.Quality = 100;

            % Location
            [E N zone h] = llaToUtm([51.71190;-0.21052;0]);
            taskparams.environment.area.originutmcoords.E = E;
            taskparams.environment.area.originutmcoords.N = N;
            taskparams.environment.area.originutmcoords.h = h;
            taskparams.environment.area.originutmcoords.zone = zone;
            taskparams.environment.area.graphics.type = 'AreaGraphics';
            taskparams.environment.area.graphics.backgroundimage = 'ucl-rvc-zoom.tif';
            taskparams.environment.area.limits = [-140 140 -140 140 -40 0];
            taskparams.environment.area.type = 'BoxArea';
            
            % Global positioning system
            taskparams.environment.gpsspacesegment.on = 0;                              % No noise
            taskparams.environment.gpsspacesegment.dt = 0.2;                            % DT
            taskparams.environment.gpsspacesegment.orbitfile = 'ngs15992_16to17.sp3';   % Real satellite orbits from NASA JPL
            taskparams.environment.gpsspacesegment.tStart = 0;                          % Simulation start in GPS time
            taskparams.environment.gpsspacesegment.svs = [3,5,6,7,13,16,18,19,20,22,24,29,31];  % IDs of visible satellites,
            taskparams.environment.gpsspacesegment.type = 'GPSSpaceSegmentGM2';         % Noise type
            taskparams.environment.gpsspacesegment.PR_BETA2 = 4;                        % Process time constant
            taskparams.environment.gpsspacesegment.PR_BETA1 =  1.005;                   % Process time constant
            taskparams.environment.gpsspacesegment.PR_SIGMA = 0.003;                    % Process standard deviation
            
            % Wind
            taskparams.environment.wind.on = 0;                                         % No wind
            taskparams.environment.wind.type = 'WindConstMean';                         % Constant mean field
            taskparams.environment.wind.direction = degsToRads(45);                     % Mean wind direction, rad clockwise from north
            taskparams.environment.wind.W6 = 0.5;                                       % Velocity at 6m from ground in m/s
            
            % Platforms
            for i = 1:obj.numPlatforms,
                taskparams.platforms(i).configfile = 'noiseless_platform';
            end
            
            % Random streams
            obj.prngId = obj.simState.numRStreams;
            obj.simState.numRStreams = obj.simState.numRStreams;
        end
        
        % Reset the simulation
        function reset(obj)
            
            % Reset the reward
            obj.accReward = 0;
            
            % Initialise each platform
            for i = 1:obj.numPlatforms
                
                % Randomly place the platforms
                obj.simState.platforms{i}.setX([rand(2,1)*140-70;-obj.hfix;0;0;0]);
                
                % Create new PID controller for this platform
                obj.velPIDs{i} = VelocityHeightPID(obj.simState.DT);
            
            end
            
        end
        
        % Step the simulation
        function UU = step(obj,U)
            
            % Initialise the control vectors
            UU = cell(obj.numPlatforms);
            
            % Work out the rotor control using a velocity height PID
            for i = 1:obj.numPlatforms
                if (obj.simState.platforms{i}.isValid())
                    UU{i} = obj.velPIDs{i}.computeU(obj.simState.platforms{i}.getEX(), U{i},-obj.hfix,0);
                else
                    UU{i} = obj.velPIDs{i}.computeU(obj.simState.platforms{i}.getEX(),[0;0],-obj.hfix,0);
                end
            end
            
        end
        
        % Calculate the reward at a given iteration
        function updateReward(obj,~)

            % Calculate the reward at this iteration
            c = 0;

            % Work out for each unit
            for i = 1:obj.numPlatforms
                
                % Get the position and velocity
                pos = obj.simState.platforms{i}.getX(1:3);
                vel = obj.simState.platforms{i}.getX(4:6);
                
                % Calculate the current speed
                speed = sqrt(sum(vel.^2));
                
                % Penalty for low or high speeds
                c = c + exp( speed - obj.maxSpeed);     % max allowed speed
                c = c + exp(-speed + obj.minSpeed);     % min allowed speed

                % Penalty for going to far away from landing position
                d = sqrt(sum((pos - obj.landingPosition).^2));
                c = c + exp(d - obj.maxDistance);

                % Only include one reward for each UAV pair
                if i < obj.numPlatforms

                    % Penalty for collision / being close
                    for j = (i+1):obj.numPlatforms

                        % Get the peer position
                        peer = obj.simState.platforms{j}.getX(1:3);
                        
                        % Get the distance to the peer
                        d = max(sqrt(sum((pos-peer).^2)),0.00001);
                        
                        % Penalise close platforms
                        c = c + 0.0025 / d;

                    end
        
                end
                
            end
           
            % Accumulate reward
            obj.accReward = obj.accReward - c;
            
        end
        
        % Total reward: 
        function r = reward(obj)
            
            % Check that all platforms are valid
            valid = 1;
            for i = 1:length(obj.simState.platforms)
                valid = valid && obj.simState.platforms{i}.isValid();
            end
            
            % Calculate the reward
            if valid
                r = obj.accReward;
            else
                r = -obj.PENALTY;
            end
            
        end
        
    end
    
end
