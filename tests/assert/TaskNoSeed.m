classdef TaskNoSeed<Task
    % Task used to test assertions on seed
    %
    methods (Sealed,Access=public)
        
        function taskparams=init(obj)
            
            % Simulator step time in second this should not be changed...
            taskparams.DT = 0.02;
                       
        end
        
        function r=reward(obj) 
            % nothing this is just a test task
        end
    end
    
end
