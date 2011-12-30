classdef Task<handle
    % Abstract class for a generic task.
    % This is nothing more than an interface, its only purpouse is to force derived class 
    % to implement init and reward methods.
    %
    % Task Methods:
    %    init()*      - initializes all the simulation parameter needed to define a task
    %    reward()*    - returns the instantaneous reward for the task
    %
    %                           *hyperlink broken because the method is abstract
    %
    methods (Abstract)
        
        taskparams=init(obj);
        % initializes all the simulation parameter needed to define a task,
        % its content depends on the task neeeds
        
        r = reward(obj);
        % returns a task reward given the current state, its content depends on the task
        % to be learned and on the learning algorithm used
    end
end