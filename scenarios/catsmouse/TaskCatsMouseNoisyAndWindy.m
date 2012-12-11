classdef TaskCatsMouseNoisyAndWindy<Task
    % Simple task in which three quadrotors (cats) have to catch another
    % quadrotor (mouse) at the end of the allotted time for the task.
    % In other words we have only a final cost equal to the sum of the
    % squared distances of the cats to the mouse. A large negative reward
    % is returned if any of the helicopters goes outside of the flying area.
    % For simplicity all quadrotors are supposed to fly at the same altitude.
    % The initial position of the quadrotors is defined randomly
    % (within reason) around the mouse; the mouse moves at a constant (max) speed and uses
    % a predefined control law which pays more heed to cats that are close by.
    % Finally in this task sensors are affected by noise and wind is present.
    %
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
    %   step()         - computes pitch, roll, yaw, throttle  commands from the user dVn,dVe commands
    %
    properties (Constant)
        durationInSteps = 1000;
        Nc = 3;              % number of cats
        minCatMouseInitDistance = 20;
        maxCatMouseInitDistance = 14;
        minInterCatsInitDistance = 22;
        mouseVfactor = 1;       % max mouse speed = mouseVfactor * catMaxSpeed
        trappedFactor = 2; % the mouse is trapped (and does not move) if its distance from any of the
                             % cats is lower than trappedFactor*collisionDistance
        hfix = 10;           % fix flight altitude
        PENALTY = 1000;      % penalty reward in case of collision
    end
    
    properties (Access=public)
        initialX; % initial state of the uavs
        prngId;   % id of the prng stream used to select the initial positions
        velPIDs;  % pid used to control the uavs
    end
    
    methods (Sealed,Access=public)
        
        function obj = TaskCatsMouseNoisyAndWindy(state)
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
            taskparams.environment.area.limits = [-140 140 -140 140 -40 0];
            taskparams.environment.area.type = 'BoxArea';
            
            % originutmcoords is the location of the RVC (our usual flying site)
            % generally when this is changed gpsspacesegment.orbitfile and
            % gpsspacesegment.svs need to be changed
            [E N zone h] = llaToUtm([51.71190;-0.21052;0]);
            taskparams.environment.area.originutmcoords.E = E;
            taskparams.environment.area.originutmcoords.N = N;
            taskparams.environment.area.originutmcoords.h = h;
            taskparams.environment.area.originutmcoords.zone = zone;
            taskparams.environment.area.graphics.type = 'AreaGraphics';
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
            taskparams.environment.wind.W6 = 1;  % velocity at 6m from ground in m/s
            
            %%%%% platforms %%%%%
            % Configuration and initial state for each of the platforms
            for i=1:obj.Nc,
                taskparams.platforms(i).configfile = 'noisy_windy_cat_config'; 
            end
            taskparams.platforms(obj.Nc+1).configfile = 'noisy_windy_mouse_config';
            
            % get hold of a prng stream
            obj.prngId = obj.simState.numRStreams+1;
            obj.simState.numRStreams = obj.simState.numRStreams + 1;
        end
        
        function reset(obj)
            % mouse always at the origin
            obj.simState.platforms{obj.Nc+1}.setX([0;0;-obj.hfix;0;0;0]);
            obj.initialX{obj.Nc+1} = obj.simState.platforms{obj.Nc+1}.getX();
            
            % cats randomly placed, not too close not too far
            for i=1:obj.Nc,
                
                cnt = 0;
                tooClose = 1;
                while tooClose
                    angle = 2*pi*rand(obj.simState.rStreams{obj.prngId},1,1);
                    d = obj.minCatMouseInitDistance + rand(obj.simState.rStreams{obj.prngId},1,1)*(obj.maxCatMouseInitDistance-obj.minCatMouseInitDistance);
                    pos = obj.initialX{obj.Nc+1}(1:3)+[d*cos(angle);d*sin(angle);0];
                    
                    tooClose = 0;
                    for j=1:i-1,
                        if(norm(pos-obj.initialX{j}(1:3))<obj.minInterCatsInitDistance)
                            tooClose = 1;
                        end
                    end
                    cnt = cnt + 1;
                    assert(cnt<100,'not able to generate an initial configuration, the minInterCatsInitDistance required by the tigsks appears too tight');
                end
                
                obj.simState.platforms{i}.setX([pos;0;0;0]);
                obj.initialX{i} = obj.simState.platforms{i}.getX();
               
                obj.velPIDs{i} = VelocityHeightPID(obj.simState.DT);
            end

            obj.velPIDs{obj.Nc+1} = VelocityHeightPID(obj.simState.DT);
        end
        
        function UU = step(obj,U)
            % compute the UAVs controls from the velocity inputs
            UU = zeros(5,obj.Nc+1);
            
            mousePos = obj.simState.platforms{obj.Nc+1}.getEX(1:2);
            Umouse = [0;0];
            
            % sum up the vectors pointing from each cat to the mouse,
            % weighted by their squared magnitude
            for i=1:obj.Nc,
                diff = (mousePos-obj.simState.platforms{i}.getEX(1:2));
                if(~any(isnan(diff)))
                    Umouse = Umouse+diff/(diff'*diff);
                end
            end
            
            % take the obtained direction and rescale it by the max mouse velocity
            Umouse = obj.mouseVfactor*obj.velPIDs{obj.Nc+1}.maxv*(Umouse./norm(Umouse));
            
            UU(:,obj.Nc+1) = obj.velPIDs{obj.Nc+1}.computeU(obj.simState.platforms{obj.Nc+1}.getEX(),Umouse,-obj.hfix,0);
            
            for i=1:obj.Nc,
                if(obj.simState.platforms{i}.isValid())
                    UU(:,i) = obj.velPIDs{i}.computeU(obj.simState.platforms{i}.getEX(),U(:,i),-obj.hfix,0);
                else
                    UU(:,i) = obj.velPIDs{i}.computeU(obj.simState.platforms{i}.getEX(),[0;0],-obj.hfix,0);
                end
            end
        end
        
        function updateReward(~,~)
            % updates reward
            % in this task we only have a final cost
        end
        
        function r=reward(obj)
            % returns the total reward for this task
            % in this case simply the sum of the squared distances of the
            % cats to the mouse (multiplied by -1)
            
            valid = 1;
            for i=1:length(obj.simState.platforms)
                valid = valid &&  obj.simState.platforms{i}.isValid();
            end
            
            if(valid)
                r = 0;
                mousePos = obj.simState.platforms{obj.Nc+1}.getX(1:3);
                for i=1:length(obj.Nc)
                    catPos = obj.simState.platforms{i}.getX(1:3);
                    e = max([0,norm(mousePos - catPos)-obj.trappedFactor*obj.simState.platforms{i}.getCollisionDistance()]);
                    % accumulate square distance of mouse from cat i
                    r = r - e^2;
                end
                r = obj.currentReward + r;
            else
                % returning a large penalty in case the state is not valid
                % i.e. one the helicopters is out of the area, there was a
                % collision or one of the helicoptera has crashed
                r = - obj.PENALTY;
            end
        end
    end
    
end



% [1] J. Rankin, "An error model for sensor simulation GPS and differential GPS," IEEE
%     Position Location and Navigation Symposium, 1994, pp.260-266.
% [2] Carlson, Justin, "Mapping Large, Urban Environments with GPS-Aided SLAM" (2010).
%     Dissertations. Paper 44.
