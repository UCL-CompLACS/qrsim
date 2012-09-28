classdef TaskNoSeed<Task
    % Task used to test assertions on seed
    %
    methods (Sealed,Access=public)
                
        function obj = TaskNoSeed(state)
            obj = obj@Task(state);
        end

        function updateReward(obj,U)
            % reward not defined
        end  
        
        function taskparams=init(obj)
            
            taskparams.dt = 0.02; % task timestep i.e. rate at which controls
                               % are supplied and measurements are received
                       
        end
        
        function reset(obj) 
            % initial state
        end 

        function r=reward(obj) 
            % nothing this is just a test task
        end
    end
    
end
