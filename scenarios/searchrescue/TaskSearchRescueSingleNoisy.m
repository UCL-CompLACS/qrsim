classdef TaskSearchRescueSingleNoisy<Task
    % Simple task in which targets (people) are lost/injured on 
    % the ground in a landscape and need to be located and rescued. 
    % A single helicopter agent is equipped with a camera/classification module
    % for observing the position of targets in its field of vision, but the
    % quality of observation depends upon the geometry between helicopter and ground (e.g. the distance).
    % Rather than raw images the camera module provides higher-level data in the form of likelihood
    % ratios of the current image conditioned on the presence or absence of a target.
    % Finally in this task all the sensors are noisy and the wind is turned on.
    %
    % Note:
    % This task accepts control inputs (for each uav) in terms of 3D velocities,
    % in global coordinates. So in the case of three uavs one would use
    % qrsim.step(U);  where U = [vx_1,vx_2,vx_3; vy_1,vy_2,vy_3];
    %
    % TaskSearchRescueSingleNoisy methods:
    %   init()         - loads and returns the parameters for the various simulation objects
    %   reset()        - defines the starting state for the task
    %   updateReward() - updates the running costs (empy method since the reward is not episodic)
    %   reward()       - returns the current reward for this task
    %   step()         - computes pitch, roll, yaw, throttle  commands from the user dVn,dVe commands
    %
    properties (Constant)
        numUAVs = 1;           % number of uavs
        startHeight = -25;     % initial uav height
        durationInSteps = 200; % steps are generally 1s
        PENALTY = 1000;        % penalty reward in case of collision
    end
    
    properties (Access=public)
        velPIDs;  % pid used to control the uavs
    end
    
    properties (Access=private)
        prngId;   % id of the prng stream used to select the initial positions
        initialX; % pid used to control the uavs
        headings; % random uav headings
    end
    
    methods (Sealed,Access=public)
        
        function obj = TaskSearchRescueSingleNoisy(state)
            obj = obj@Task(state);
        end
        
        function taskparams=init(obj) 
            % loads and returns the parameters for the various simulation objects
            %
            % Example:
            %   params = obj.init();
            %          params - the task parameters
            %
            
            taskparams.dt = 1;    % task timestep i.e. rate at which controls
                                  % are supplied and measurements are received
            
            taskparams.seed = 0;  % set to zero to have a seed that depends on the system time
            
            %%%%% visualization %%%%%
            % 3D display parameters
            taskparams.display3d.on = 1;
            taskparams.display3d.width = 1000;
            taskparams.display3d.height = 600;
            
            %%%%% environment %%%%%
            % these need to follow the conventions of axis(), they are in m, Z down
            % note that the lowest Z limit is the refence for the computation of wind shear and turbulence effects
            D = sqrt(obj.durationInSteps*25*3*obj.numUAVs);  % simple heuristic that scales the terrain size so that the agent 
                                                 % won't have enough time to simply scan the area in lawn mower fashion
            taskparams.environment.area.limits = [-D D -D D -80 0];
            taskparams.environment.area.dt = 1;
            taskparams.environment.area.type = 'BoxWithPersonsArea';
            
            % originutmcoords is the location of the RVC (our usual flying site)
            % generally when this is changed gpsspacesegment.orbitfile and
            % gpsspacesegment.svs need to be changed
            [E N zone h] = llaToUtm([51.71190;-0.21052;0]);
            taskparams.environment.area.originutmcoords.E = E;
            taskparams.environment.area.originutmcoords.N = N;
            taskparams.environment.area.originutmcoords.h = h;
            taskparams.environment.area.originutmcoords.zone = zone;
            taskparams.environment.area.numpersonsrange = [5,10];         % number of person selected at random between these limits
            taskparams.environment.area.personfounddistancethreshold = 5; % distance within which a person is deemed as found [m]
            taskparams.environment.area.personfoundspeedthreshold = 0.1;  % speed lower than which the uav has to travel when close to a person to deem it found [m/s]
            taskparams.environment.area.personsize = 0.5;                 % size of the edge of the square patch representing a person [m]
            taskparams.environment.area.graphics.type = 'SearchAreaGraphics';
            taskparams.environment.area.terrain.type = 'PourTerrain';   
            taskparams.environment.area.terrain.classpercentages = [0.2,0.05];  % 20% clutter, 5% occlusion => 75% no clutter & no occlusions 
            taskparams.environment.area.personinclassprob = [0.0,0.0];  % prob 0 of person being in terrain of class clutter
                                                                        % prob 0 of person being in terrain of class occlusion
                                                                        % prob 1 of person being in terrain of class no clutter & no occlusions            
            
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
            taskparams.environment.wind.on = 0;  %% NO WIND!!!
            taskparams.environment.wind.type = 'WindConstMean';
            taskparams.environment.wind.direction = degsToRads(45); %mean wind direction, rad clockwise from north set to [] to initialise it randomly
            taskparams.environment.wind.W6 = 0.5;  % velocity at 6m from ground in m/s
            
            %%%%% platforms %%%%%
            % Configuration and initial state for each of the platforms
            for i=1:obj.numUAVs,
                taskparams.platforms(i).configfile = 'pelican_with_camera_noisy_config';
            end  
            
        end
        
        function reset(obj)        
            % initializes the task, generating new positions for persons and
            % new initial positions fo the uavs
            %
            % note: this is generally called automatically by qrsim 
            %
            
            % uav randomly placed, but not too close to the edges of the area         
            
            obj.headings = pi*rand(obj.numUAVs,1);
            
            for i=1:obj.numUAVs,
                
                r = rand(obj.simState.rStreams{obj.prngId},2,1);
                l = obj.simState.environment.area.getLimits();
                
                px = 0.5*(l(2)+l(1)) + (r(1)-0.5)*0.9*(l(2)-l(1));
                py = 0.5*(l(4)+l(3)) + (r(2)-0.5)*0.9*(l(4)-l(3));
                
                obj.simState.platforms{i}.setX([px;py;obj.startHeight;0;0;obj.headings(i)]);
                obj.initialX{i} = obj.simState.platforms{i}.getX();
                               
                obj.velPIDs{i} = VelocityPID(obj.simState.DT);
            end
            
            % persons randomly placed, but not too close to the edges of the area
            obj.simState.environment.area.reset();
        end
        
        function UU = step(obj,U)
            % computes the UAVs controls from the velocity inputs 
            %
            % note: this is generally called automatically by qrsim 
            %   
            UU=zeros(5,length(obj.simState.platforms));
            for i=1:length(obj.simState.platforms),
                if(obj.simState.platforms{i}.isValid())
                    UU(:,i) = obj.velPIDs{i}.computeU(obj.simState.platforms{i}.getEX(),U(:,i),obj.headings(i));
                else
                    UU(:,i) = obj.velPIDs{i}.computeU(obj.simState.platforms{i}.getEX(),[0;0;0],obj.headings(i));
                end
            end
        end
        
        function updateReward(obj,~)
            % no reward update since the reward is not episodic
            obj.currentReward = 0;
        end
                        
        function p = getNumberOfPersons(obj)
            % returns the number of persons in the search area
            p = obj.simState.environment.area.getNumberOfPersons();
        end
        
        function r=reward(obj)
            % returns the reward at the current timestep
            % in this case it is 1 if a person was found, and 
            % -1/durationInSteps otherwise
            %
            % usage:
            %   qrsi.reward();
            %
            valid = 1;
            for i=1:length(obj.simState.platforms)
                valid = valid &&  obj.simState.platforms{i}.isValid();
            end
            
            if(valid)
                justFound = obj.simState.environment.area.getPersonsJustFound();
                 
                r = sum(sum(justFound));
                 
                if(r==0)
                    r = -1/obj.durationInSteps;
                end
            else
                % returning a large penalty in case the state is not valid
                % i.e. one the helicopters is out of the area, there was a
                % collision or one of the helicoptera has crashed
                r = - obj.PENALTY;
            end
        end
    end
    
end
