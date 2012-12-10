function [ e ] = testLimits()
%test the checks we are imposing on each of the state variables,
% on the flight volume and on the control inputs

clear all;

cd('limits');

e = 0;

% test the case in which we start out of the boundaries
e = e | testSettingStateOutOfBounds('helicopter setting state out of bounds');

% test the case in which we start out of the boundaries
e = e | testConfigFileStateOutOfBounds('TaskNoWindPlatformOutOfBounds1','helicopter config file state out of bounds 1');
e = e | testConfigFileStateOutOfBounds('TaskNoWindPlatformOutOfBounds2','helicopter config file state out of bounds 2');
e = e | testConfigFileStateOutOfBounds('TaskNoWindPlatformOutOfBounds3','helicopter config file state out of bounds 3');

% test the case in which we sart from inside the area and we
% to a wp outside using a PID
e = e | testFlyingOutOfBounds('helicopter flying out of the test area');


% test control input limits
e = e | testControlsOutOfBounds('control inputs out of bounds');

cd('..');

end


function e = testControlsOutOfBounds(msg)

e = 0;

% create simulator object
qrsim = QRSim();

% load task parameters and do housekeeping
state = qrsim.init('TaskNoWind'); %#ok<NASGU>

UwrongSize =[0.2,-0.2;
    0,   0;
    0.6, 0.6;
    0,   0;
    11,  11];

% test wrong control size
try
    qrsim.step(UwrongSize);
    e = e || 1;
catch exception
    if(~strcmp(exception.identifier,'qrsim:wronginputsize'))
        e = e || 1;
        fprintf('\nUNEXPECTED EXCEPTION:%s \nMESSAGE:%s\n',exception.identifier,exception.message);
    end
end


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

e = 0;

addpath(['..',filesep,'..',filesep,'controllers']);

% number of steps we run the simulation for
N = 600;

% create simulator object
qrsim = QRSim();

% load task parameters and do housekeeping
state = qrsim.init('TaskNoWind');

wps = [   0,    0, 100, -100,   0,    0;
          0,    0,   0,    0, 100, -100;
        100, -100,   0,    0,   0,    0];
        
pid = WaypointPID(state.DT);

for j = 1:size(wps,1)
    
    for i=1:N,
        
        % compute controls
        U=pid.computeU(state.platforms{1}.getEX(),wps(:,j),0);
        
        % step simulator
        qrsim.step(U);
        
        if(~state.platforms{1}.isValid())
            break;
        end
    end
    e = e || state.platforms{1}.isValid();
    
    qrsim.reset();    
end

if(e)
    fprintf(['Test ',msg,' [FAILED]\n']);
else
    fprintf(['Test ',msg,' [PASSED]\n']);
end

end


function e = testSettingStateOutOfBounds(msg)

e = 0;

qrsim = QRSim();

state = qrsim.init('TaskNoWind');

limits = state.platforms{1}.getStateLimits();

for i=1:size(limits,1),
    
    for j=1:1,
        l = limits(:,j)*0.5; % safely within limits
        l(i) = limits(i,j)*1.01; % out of limits (this relies on the max and min limits being one positive the other negative)
        
        try
            state.platforms{1}.setX(l);
            e = e || 1;
        catch exception
            if(~strcmp(exception.identifier,'pelican:settingoobstate'))
                e = 1;
                fprintf('\nUNEXPECTED EXCEPTION:%s \nMESSAGE:%s\n',exception.identifier,exception.message);
            end
        end
    end
end

if(e)
    fprintf(['Test ',msg,' [FAILED]\n']);
else
    fprintf(['Test ',msg,' [PASSED]\n']);
end

end

function e = testConfigFileStateOutOfBounds(task,msg)

e = 0;

qrsim = QRSim();

try
    state = qrsim.init(task); %#ok<NASGU>
    e = e || 1;
catch exception
    if(~strcmp(exception.identifier,'pelican:settingoobstate'))
        e = 1;
        fprintf('\nUNEXPECTED EXCEPTION:%s \nMESSAGE:%s\n',exception.identifier,exception.message);
    end
end

if(e)
    fprintf(['Test ',msg,' [FAILED]\n']);
else
    fprintf(['Test ',msg,' [PASSED]\n']);
end

end
