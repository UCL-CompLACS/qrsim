classdef TestGPSTask<Task
    % Simple task used to do sensor testing
    %
    % KeepSpot methods:
    %   init()   - loads and returns all the parameters for the various simulator objects
    %   reward() - returns 0
    %
    
    methods (Sealed,Access=public)
        
        function obj = TestGPSTask(state)
            obj = obj@Task(state);
        end

        function updateReward(obj,U)
            % reward not defined
        end
        
        function taskparams=init(obj) %#ok<MANU>
            % loads and returns all the parameters for the various simulator objects
            %
            % Example:
            %   params = obj.init();
            %          params - all the task parameters
            %
            
            taskparams.dt = 0.02; % task timestep i.e. rate at which controls
                               % are supplied and measurements are received
            
            taskparams.seed = 125; %set to zero to have a seed that depends on the system time
            
            %%%%% visualization %%%%%
            % 3D display parameters
            taskparams.display3d.on = 0;         
            
            %%%%% environment %%%%%
            % these need to follow the conventions of axis(), they are in m, Z down
            % note that the lowest Z limit is the refence for the computation of wind shear and turbulence effects
            taskparams.environment.area.limits = [-10 20 -7 7 -20 0];
            taskparams.environment.area.type = 'BoxArea';
            % location of our usual flying site
            [E N zone h] = llaToUtm([51.71190;-0.21052;0]);
            taskparams.environment.area.originutmcoords.E = E;
            taskparams.environment.area.originutmcoords.N = N;
            taskparams.environment.area.originutmcoords.h = h;
            taskparams.environment.area.originutmcoords.zone =  zone;
            
            % GPS
            % The
            taskparams.environment.gpsspacesegment.on = 1; % if off the gps returns the noiseless position
            taskparams.environment.gpsspacesegment.dt = 0.2;
            % specific setting due to the use of the ngs15992_16to17.sp3 file
            taskparams.environment.gpsspacesegment.orbitfile = 'ngs15992_16to17.sp3';
            taskparams.environment.gpsspacesegment.tStart = 0;%Orbits.parseTime(2010,8,31,16,0,0); %0 to init randomly
            % a typical flight day had the following svs visible:
            %03G 05G 06G 07G 13G 16G 18G 19G 20G 22G 24G 29G 31G
            taskparams.environment.gpsspacesegment.svs = [3,5,6,7,13,16,18,19,20,22,24,29,31];
            taskparams.environment.gpsspacesegment.type = 'GPSSpaceSegmentGM2';            
            taskparams.environment.gpsspacesegment.PR_BETA2 = 4;               % process time constant
            taskparams.environment.gpsspacesegment.PR_BETA1 =  1.005;          % process time constant   
            taskparams.environment.gpsspacesegment.PR_SIGMA = 0.003;           % process standard deviation            
            
            % Wind
            % i.e. a steady omogeneous wind with a direction and magnitude
            % this is common to all helicopters
            taskparams.environment.wind.on = 0;
            
            %%%%% platforms %%%%%
            % Configuration and initial state for each of the platforms
            taskparams.platforms(1).configfile = 'pelican_test_gps_config';
            
        end

        function reset(obj) 
	    % initial state
	    obj.simState.platforms{1}.setX([0;0;-20;0;0;0]);
        end
        
        function r=reward(obj) 
            % returns the instantateous reward for this task
            %
            % Example:
            %   r = obj.reward();
            %          r - the reward
            %
            r = 0; 
        end
    end
    
end
