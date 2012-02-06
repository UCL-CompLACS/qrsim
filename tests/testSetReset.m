function e = testSetReset()
% test the reset and setState methods of the pelican object

clear all;

cd('setreset');

% after a setState X should be what was set
e = simpleSetState();

% with random seed
% init should give different eX than an init + reset but the same X
e = e | initAndResetFromRandomSeed('set twice with random seed');

% with fix seed
% init should give same eX and X than an init + reset
e = e | initAndResetFromFixedSeed('set twice with fixed seed');

% with random seed:
% two setState to the same state should give the same X but different eX
e = e | setAndRunFromRandomSeed('set and run twice with random seed');

% with fix seed:
% two setSate should give the same X and same eX
e = e | setAndRunFromFixedSeed('set and run twice with fixed seed');


cd('..');

end


function e = initAndResetFromRandomSeed(msg)

e = 0;

% new state structure
global state;
setX = [1;2;3;0;0;pi;0;0;0;0;0;0];

% create simulator object
qrsim = QRSim();

% load task parameters and do housekeeping
qrsim.init('TaskNoWindRandomSeed');

X1 = state.platforms(1).X;
eX1 = state.platforms(1).eX;

state.platforms(1).setState(setX);

X2 = state.platforms(1).X;
eX2 = state.platforms(1).eX;

e = e || ~all(X1==X2) || all(eX1==eX2);

% clear the state
clear global state;

if(e)
    fprintf(['Test ',msg,' [FAILED]\n']);
else
    fprintf(['Test ',msg,' [PASSED]\n']);
end

end


function e = initAndResetFromFixedSeed(msg)

e = 0;

% new state structure
global state;
setX = [1;2;3;0;0;pi;0;0;0;0;0;0];

% create simulator object
qrsim = QRSim();

% load task parameters and do housekeeping
qrsim.init('TaskNoWindFixedSeed');

X1 = state.platforms(1).X;
eX1 = state.platforms(1).eX;

state.platforms(1).setState(setX);

X2 = state.platforms(1).X;
eX2 = state.platforms(1).eX;

e = e || ~all(X1==X2) || ~all(eX1==eX2);

% clear the state
clear global state;

if(e)
    fprintf(['Test ',msg,' [FAILED]\n']);
else
    fprintf(['Test ',msg,' [PASSED]\n']);
end

end

function e = setAndRunFromRandomSeed(msg)

e = 0;

% new state structure
global state;
U = [0;0;0.59004353928;0;11];
setX = [1;2;3;0;0;pi;0;0;0;0;0;0];

% create simulator object
qrsim = QRSim();

% load task parameters and do housekeeping
qrsim.init('TaskNoWindRandomSeed');

state.platforms(1).setState(setX);

for i=1:50
    qrsim.step(U);
end    

X1 = state.platforms(1).X;
eX1 = state.platforms(1).eX;

state.platforms(1).setState(setX);

for i=1:50
    qrsim.step(U);
end    

X2 = state.platforms(1).X;
eX2 = state.platforms(1).eX;

e = e || ~all(X1==X2) || all(eX1==eX2);

% clear the state
clear global state;

if(e)
    fprintf(['Test ',msg,' [FAILED]\n']);
else
    fprintf(['Test ',msg,' [PASSED]\n']);
end

end


function e = setAndRunFromFixedSeed(msg)

e = 0;

% new state structure
global state;
U = [0;0;0.59004353928;0;11];
setX = [1;2;3;0;0;pi;0;0;0;0;0;0];

% create simulator object
qrsim = QRSim();

% load task parameters and do housekeeping
qrsim.init('TaskNoWindFixedSeed');

state.platforms(1).setState(setX);
    

X1 = state.platforms(1).X;
eX1 = state.platforms(1).eX;

state.platforms(1).setState(setX);

for i=1:50
    qrsim.step(U);
end    

X2 = state.platforms(1).X;
eX2 = state.platforms(1).eX;

e = e || ~all(X1==X2) || ~all(eX1==eX2);

% clear the state
clear global state;

if(e)
    fprintf(['Test ',msg,' [FAILED]\n']);
else
    fprintf(['Test ',msg,' [PASSED]\n']);
end

end



function e = simpleSetState()

e = 0;

% new state structure
global state;

% create simulator object
qrsim = QRSim();

% load task parameters and do housekeeping
qrsim.init('TaskNoWindRandomSeed');

% failing
shortX = [0;1;2];
e = e || failingState(shortX,'pelican:wrongsetstate','state too short');

longX = [1;2;3;4;5;6;7;8;9;10;11;12;13;14];
e = e || failingState(longX,'pelican:wrongsetstate','state too long');

wrongX = [1;2;3;4;5];
e = e || failingState(wrongX,'pelican:wrongsetstate','state size wrong 1');

wrongX = [1;2;3;4;5;6;7;8];
e = e || failingState(wrongX,'pelican:wrongsetstate','state size wrong 2');


limits = state.platforms(1).stateLimits;

oobX = [limits(1,2)*1.1;0;0];
e = e || failingState(oobX,'pelican:wrongsetstate','posx value out of bounds');

oobX = [0;limits(2,2)*1.1;0];
e = e || failingState(oobX,'pelican:wrongsetstate','posy value out of bounds');

oobX = [0;0;limits(3,2)*1.1];
e = e || failingState(oobX,'pelican:wrongsetstate','posz value out of bounds');

validX = [1;2;3;0.01;0.01;1];
e = e || validSetState(validX,'valid state of size 6');

validX = [1;2;3;0.01;0.01;1;0.01;0.01;0.01;0.01;0.01;0.01];
e = e || validSetState(validX,'valid state of size 12');

validX = [1;2;3;0.01;0.01;1;0.01;0.01;0.01;0.01;0.01;0.01;state.platforms(1).MASS*state.platforms(1).G];
e = e || validSetState(validX,'valid state of size 13');

% clear the state
clear global state;

end

function e = failingState(X,id,msg)

global state;
e = 0;

try
    state.platforms(1).setState(X);
    e = 1;
catch exception
    if(~strcmp(exception.identifier,id))
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


function e = validSetState(X,msg)

global state;
e = 0;

try
    state.platforms(1).setState(X);
catch exception
    e = 1;
    fprintf('\nUNEXPECTED EXCEPTION:%s \nMESSAGE:%s\n',exception.identifier,exception.message);
end

if(length(X)==6)
    e = e || ~all(state.platforms(1).X(1:12)==[X;zeros(6,1)]);
else
    if (length(X)==12)
        e = e || ~all(state.platforms(1).X(1:12)==X);
    else
        if (length(X)==13)
            e = e || ~all(state.platforms(1).X==X);
        end        
    end
end

if(e)
    fprintf(['Test ',msg,' [FAILED]\n']);
else
    fprintf(['Test ',msg,' [PASSED]\n']);
end

end