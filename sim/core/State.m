classdef State<handle
    % Data structure that holds the full state of a qrsim simulation
    % The main purpouse of this structure is to to provide a handle to the 
    % simulator state so that ist can be referenced whenever needed
    % withouth wasteful copying of data
    
    properties (Access=public)
        numRStreams;  % number of random streams in teh simulation        
        rStreams;     % the random streams used throughout the simualtion
        DT;           % simulation time step
        t;            % current simulation time
        display3d;    % handle to the 3D graphic figure
        display3dOn;  % true if the display is on
        environment;  % handle to all the environment objects
        environment_; % handle to hidden environment objects
        platforms;    % cell array containing handles to all the platforms
        task;         % handle to the current task
        camerascnt_;  % cameras counter
    end
end

