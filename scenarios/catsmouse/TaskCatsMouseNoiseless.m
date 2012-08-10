classdef TaskCatsMouseNoiseless<Task
    % Simple task in which three quadrotors (cats) have to catch another
    % quadrotor (mouse) at the end of the allotted time for the task.
    % In other words we have only a final cost equal to the sum of the
    % squared distances of the cats to the mouse. A large negative reward
    % is returned if any of the helicopters goes outside of the flying area.
    % For simplicity all quadrotors are supposed to fly at the same altitude.
    % The initial configuration of the quadrotors is defined randomly
    % (within reason); the mouse moves at a constant (max) speed and uses
    % a predefined control law which pays more heed to cats that are close by.
    %
    % Note:
    % This task accepts control inputs (for each cat) in terms of 2D accelerations,
    % in global coordinates. So in the case of three cats one would use
    % qrsim.step(U);  where U = [ax_1,ax_2,ax_3; ay_1,ay_2,ay_3];
    %
    % TaskCatsMouseNoiseless methods:
    %   init()         - loads and returns the parameters for the various simulation objects
    %   reset()        - defines the starting state for the task
    %   updateReward() - updates the running costs (zero for this task)
    %   reward()       - computes the final reward for this task
    %   step()         - computes pitch, roll, yaw, throttle  commands from the user dVn,dVe commands
    %
    properties (Constant)
        durationInSteps = 300;
        Nc = 3; %number of cats        
        minCatMouseInitDistance = 8;
        maxCatMouseInitDistance = 6;
        minInterCatsInitDistance = 5;
        hfix = 10;
        PENALTY = 1000;
    end
    
    properties (Access=private)
        initialX; % initial state of the uavs
        prngId;   % id of the prng stream used to select the initial positions
        velPIDs;  % pid used to control the uavs  
        Vs;       % last velocity command
    end
    
    methods (Sealed,Access=public)
        
        function obj = TaskCatsMouseNoiseless(state)
            obj = obj@Task(state);
        end
        
        function taskparams=init(obj) %#ok<MANU>
            % loads and returns the parameters for the various simulation objects
            %
            % Example:
            %   params = obj.init();
            %          params - the task parameters
            %
            
            % Simulator step time in second this should not be changed...
            taskparams.DT = 0.02;
            
            taskparams.seed = 0; %set to zero to have a seed that depends on the system time
            
            %%%%% visualization %%%%%
            % 3D display parameters
            taskparams.display3d.on = 1;
            taskparams.display3d.width = 1000;
            taskparams.display3d.height = 600;
            
            %%%%% environment %%%%%
            % these need to follow the conventions of axis(), they are in m, Z down
            % note that the lowest Z limit is the refence for the computation of wind shear and turbulence effects
            taskparams.environment.area.limits = [-200 200 -200 200 -40 0];
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
            taskparams.environment.gpsspacesegment.on = 0; %% NO GPS NOISE!!!
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
            for i=1:obj.Nc,
                taskparams.platforms(i).configfile = 'noiseless_cat_config';                
                obj.velPIDs{i} = VelocityHeightPID(taskparams.DT);
            end
            taskparams.platforms(obj.Nc+1).configfile = 'noiseless_mouse_config';
            obj.velPIDs{obj.Nc+1} = VelocityHeightPID(taskparams.DT);
            
            % get hold of a prng stream
            obj.prngId = obj.simState.numRStreams+1;
            obj.simState.numRStreams = obj.simState.numRStreams + 1;
        end
        
        function reset(obj)
            % mouse always at the origin
            obj.simState.platforms{obj.Nc+1}.setX([0;0;-obj.hfix;0;0;0]);
            obj.initialX{obj.Nc+1} = obj.simState.platforms{obj.Nc+1}.getX();
            
            % cats randomly placed around, not too close not too far
            for i=1:obj.Nc,
                
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
                end
                
                obj.simState.platforms{i}.setX([pos;0;0;0]);
                obj.initialX{i} = obj.simState.platforms{i}.getX();
            end        
            
            %reset the last velocity controls
            obj.Vs = zeros(2,obj.Nc+1);
        end
        
        function UU = step(obj,U)
            % compute the UAVs controls from the velocity inputs
            UU = zeros(5,obj.Nc+1);
            
            mousePos = obj.simState.platforms{obj.Nc+1}.getX(1:2);
            Umouse = [0;0];
            
            for i=1:obj.Nc,
                diff = (mousePos-obj.simState.platforms{i}.getX(1:2));
                Umouse = Umouse+diff/(diff'*diff);            
            end
            
            % take the obtained direction and rescale it by the max
            % velocity we can fly
            Umouse = obj.velPIDs{obj.Nc+1}.maxv*(Umouse./norm(Umouse));
            
            obj.Vs(:,obj.Nc+1) =  obj.Vs(:,obj.Nc+1) + obj.simState.DT*Umouse;
            UU(:,obj.Nc+1) = obj.velPIDs{obj.Nc+1}.computeU(obj.simState.platforms{obj.Nc+1}.getX(),obj.Vs(:,obj.Nc+1),-obj.hfix,0);
            
            for i=1:obj.Nc,
               obj.Vs(:,i) =  obj.Vs(:,i) + obj.simState.DT*U(:,i);               
               UU(:,i) = obj.velPIDs{i}.computeU(obj.simState.platforms{i}.getX(),obj.Vs(:,i),-obj.hfix,0);
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
                    e = mousePos - catPos;
                    % accumulate square distance of mouse from cat i
                    r = r - e' * e;
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
