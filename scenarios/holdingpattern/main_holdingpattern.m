% Clear any open windows
clear all, close all;

% Include the default simulation core and PID controllers
addpath(['..',filesep,'..',filesep,'sim']);
addpath(['..',filesep,'..',filesep,'controllers']);

% Create simulator object
qrsim = QRSim();

% Load task parameters
state = qrsim.init('TaskHoldingPattern');

% 3D NED velocity [vx;vy;vz] in m/s for cat i
U = cell(state.task.numPlatforms);

% Run the scenario and at every timestep generate a control - this is
% really just a very simple force-based approach to joint platform control.
% Each platform will greedily travel towards the landing position (0,0) 
% unless it comes within 5 times the collision distance. When this happens
% the platform experiences an additive repulsive force from the peer that
% grows exponentially as the two platforms come closer together.
tstart = tic;
for i = 1:state.task.durationInSteps,
    tloop=tic;
    
    % A quick and easy way of computing velocity controls for each platform 
    for j = 1:state.task.numPlatforms
        
        % Check that there was no collision
        if ~state.platforms{j}.isValid()
            
            % Flush all simulator events
            qrsim.flush();
            
            % Return  errpr
            error('Collision detected');
            
        end
            
        % Unit vector in the direction of the landing position
        u = state.task.landingPosition(1:2) - state.platforms{j}.getEX(1:2);
        u = u / norm(u);
        
        % Keep away from other platforms if closer than 5*collisionDistance
        for k = 1:state.task.numPlatforms
            if (k==j), continue, end;
            
            % Check for no collision
            if state.platforms{k}.isValid()                  
                
                % 2D vector in the direction of the peer
                d = state.platforms{k}.getEX(1:2) - state.platforms{j}.getEX(1:2);
                
                % If we are getting within 2 times collision distance
                if norm(d) < 5 * state.platforms{j}.getCollisionDistance()
                    u = u - d*exp(1/norm(d));
                end
                
            end
            
        end
        
        % Scale by the max allowed velocity
        U{j} = state.task.velPIDs{j}.maxv * u / norm(u);
        
    end
    
    % Step the simulator
    qrsim.step(U);
    
    % If we are rendering, then pause a little to draw in realtime
    if state.display3dOn
        pause(max(0,state.task.dt-toc(tloop))); 
    end
    
end

% Flush all simulator events
qrsim.flush();

