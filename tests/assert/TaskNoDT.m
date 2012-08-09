classdef TaskNoDT<Task
    % Task used to test assertions on DT
    %
    methods (Sealed,Access=public)
                
        function obj = TaskNoDT(state)
            obj = obj@Task(state);
        end

        function updateReward(obj,U)
            % reward not defined
        end
        
        function taskparams=init(obj)
            taskparams = [];
        end
        
        function reset(obj) 
            % initial state
        end 

        function r=reward(obj) 
            % nothing this is just a test task
            r = 0;
        end
    end
    
end
