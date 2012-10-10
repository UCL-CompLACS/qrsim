classdef TaskNoAreaType<Task
    % Task used to test assertions on DT
    %
    methods (Sealed,Access=public)
                
        function obj = TaskNoAreaType(state)
            obj = obj@Task(state);
        end

        function updateReward(obj,U)
            % reward not defined
        end
        
        function taskparams=init(obj)
            % loads and returns all the parameters for the various simulator objects
            
            taskparams.dt = 0.02; % task timestep i.e. rate at which controls
                               % are supplied and measurements are received
            
            taskparams.seed = 0; %set to zero to have a seed that depends on the system time
            
            %%%%% visualization %%%%%
            % 3D display parameters
            taskparams.display3d.on = 0;
            taskparams.display3d.width = 1000;
            taskparams.display3d.height = 600;  
                       
            % GPS
            % The space segment of the gps system
            taskparams.environment.gpsspacesegment.on = 0;
            taskparams.environment.gpsspacesegment.dt = 0.2;
            
            % Wind
            % i.e. a steady omogeneous wind with a direction and magnitude
            % this is common to all helicopters
            taskparams.environment.wind.on = 0;
            
        end
        
        function reset(obj) 
            % initial state
        end 

        function r=reward(obj) 
            % nothing this is just a test task
        end
    end
    
end
