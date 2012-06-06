classdef Task<handle
    % Abstract class for a generic task.
    % This is nothing more than an interface, its only purpouse is to force derived class 
    % to implement init and reward methods.
    %
    % Task Methods:
    %    init()*           - initializes all the simulation parameter needed to define a task
    %    reward()*         - returns the reward for the task (sum of accumulated istantaneous and final reward)
    %    updateReward()*   - updates the reward after a step
    %    resetReward()*    - reset the reward
    %
    %                      *hyperlink broken because the method is abstract
    %
    
    properties (Access=protected)
       simState;      % handle to the simultor state
    end
    
    methods (Abstract)        
        taskparams=init(obj);
        % initializes all the simulation parameter needed to define a task,
        % its content depends on the task neeeds
        
        updateReward(obj,U);
        % called by qrsim after a step in order to compute any
        % state/control const; its content depends on the task neeeds
                
        resetReward(obj);
        % resets the reward to 0, this is called by qrsim during a reset
        
        r = reward(obj);
        % returns a task reward given the current state, its content depends on the task
        % to be learned and on the learning algorithm used
    end
    
    methods (Access=public)
        function obj = Task(state)
           obj.simState = state; 
        end
    end    
end