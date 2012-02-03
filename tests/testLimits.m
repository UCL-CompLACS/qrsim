function [ e ] = testLimits()
%test the checks we are imposing on each of the state variables,
% on the flight volume and on the control inputs

clear all;

cd('limits');

e = 0;

% test the case in which we start out of the boundaries
e = e | testStartingOutOfBounds('test of helicopter starting out of bounds');


% test the case in which we sart from inside the area and we
% to a wp outside using a PID
e = e | testFlyingOutOfBounds('test of helicopter flying out of the test area');


% test control input limits
e = e | testControlsOutOfBounds('test of control inputs out of bounds');

cd('..');

end


function e = testControlsOutOfBounds(msg)

clear('global');

% new state structure
global state;

e = 0;

% create simulator object
qrsim = QRSim();

% load task parameters and do housekeeping
qrsim.init('TaskNoWind');

% controls
% pt  [-0.89..0.89] rad commanded pitch 
% trl [-0.89..0.89] rad commanded roll 
% th  [0..1] unitless commanded throttle
% ya  [-4.4..4.4] rad/s commanded yaw velocity
% bat [9..12] Volts battery voltage

UUgood = [0.2,-0.2,  0,   0,   0,  0,  0,  0,  0,   0;
            0,   0,0.1,-0.1,   0,  0,  0,  0,  0,   0;
          0.6, 0.6,0.6, 0.6, 0.1,0.9,0.6,0.6,0.6, 0.6;
            0,   0,  0,   0,   0,  0, -1,  1,  0,   0;
           11,  11, 11,  11,  11, 11, 11, 11,  9,  12];

for i = 1: size(UUgood,2),    
    try
        qrsim.step(UUgood(:,i));
    catch exception
        e = e || 1;
        fprintf('\nUNEXPECTED EXCEPTION:%s \nMESSAGE:%s\n',exception.identifier,exception.message);
    end    
end


UUbad = [  1, -1,  0,  0,   0,  0,  0,  0,  0,  0;
           0,  0,  1, -1,   0,  0,  0,  0,  0,  0;
         0.6,0.6,0.6,0.6,-0.6,1.6,0.6,0.6,0.6,0.6;
           0,  0,  0,  0,   0,  0, -5,  5,  0,  0;
          11, 11, 11, 11,  11, 11, 11, 11,  8, 13];

for i = 1: size(UUbad,2),    
    try
        qrsim.step(UUbad(:,i));
        e = e || 1;
    catch exception
        if(~strcmp(exception.identifier,'pelican:inputoob'))
            e = 1;
            fprintf('\nUNEXPECTED EXCEPTION:%s \nMESSAGE:%s\n',exception.identifier,exception.message);
        end
    end    
end

if(e)
    fprintf(['Test ',msg,' [FAILED]\n']);
else
    fprintf(['Test ',msg,' [PASSED]\n']);
end

end


function e = testFlyingOutOfBounds(msg)

clear('global');

% new state structure
global state;

e = 0;

% number of steps we run the simulation for
N = 100;

% create simulator object
qrsim = QRSim();

% load task parameters and do housekeeping
qrsim.init('TaskNoWind');

wps=[   0,   0, 100, 0;
        0,   0,-100, 0;
      100,   0,   0, 0;
     -100,   0,   0, 0;
        0, 100,   0, 0;
        0,-100,   0, 0];

for j = 1:size(wps,1)
    
    for i=1:N,
        
        % compute controls
        U=quadrotorPID(state.platforms(1).eX,wps(j,:));
        
        % step simulator
        qrsim.step(U);
        
        if(~state.platforms(1).valid)
            break;
        end
    end
    e = e || state.platforms(1).valid;
    
    qrsim.reset();
    
end

if(e)
    fprintf(['Test ',msg,' [FAILED]\n']);
else
    fprintf(['Test ',msg,' [PASSED]\n']);
end

end


function e = testStartingOutOfBounds(msg)

e = 0;

clear('global');

% new state structure
global state;

qrsim = QRSim();

U = [0;0;0.59004353928;0;11];

qrsim.init('TaskNoWind');

limits = state.platforms(1).stateLimits;

for i=1:size(limits,1),
    
    % test positive limits
    l = limits(:,1)*0.5; % safely within limits
    l(i) = limits(i,1)*1.01; % out of limits (this relies on the max and min limits being one positive the other negative)
    
    state.platforms(1).setState(l);
    
    qrsim.step(U);
    
    e = e || state.platforms(1).valid;
    
    qrsim.reset();
    
    
    % test negative limits
    l = limits(:,2)*0.5; % safely within limits
    l(i) = limits(i,2)*1.01; % out of limits (this relies on the max limits being one positive the other negative)
    
    state.platforms(1).setState(l);
    
    qrsim.step(U);
    
    e = e || state.platforms(1).valid;
    
    qrsim.reset();
    
end

% clear the state
clear global state;

if(e)
    fprintf(['Test ',msg,' [FAILED]\n']);
else
    fprintf(['Test ',msg,' [PASSED]\n']);
end

end
