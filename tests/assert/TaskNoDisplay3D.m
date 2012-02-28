classdef TaskNoDisplay3D<BaseTask
    % Task used to test assertions on DT
    %
    methods (Sealed,Access=public)
        
        function taskparams=init(obj)
            % loads and returns all the parameters for the various simulator objects
            
            % Simulator step time in second this should not be changed...
            taskparams.DT = 0.02;
            
            taskparams.seed = 0; %set to zero to have a seed that depends on the system time
            
        end
        
        function r=reward(obj) 
            % nothing this is just a test task
        end
    end
    
end
