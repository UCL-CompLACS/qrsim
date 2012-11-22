function e = testSetReset()
% test the reset and setState methods of the pelican object

clear all;

cd('setreset');
e = 0;

% after a setState X should be what was set
e = e | simpleSetState();

% with random seed
% init should give different eX than an init + reset but the same X
e = e | loudTest('initAndResetFromRandomSeed','init and reset with random seed');

% with fix seed
% init should give same eX and X than an init + reset
e = e | loudTest('initAndResetFromFixedSeed','init and reset with fixed seed');

% with fix seed, no wind no GPS:
e = e | loudTest('initAndResetFromFixedSeedNoiseless','init and reset with fixed seed no wind no GPS');

% with random seed:
% two setState to the same state should give the same X but different eX
e = e | loudTest('setAndRunFromRandomSeed','set and run twice with random seed');

% with fix seed:
% two setSate should give the same X and same eX
e = e | loudTest('setAndRunFromFixedSeed','set and run twice with fixed seed');

% with fix seed, no wind no GPS:
% two setSate should give the same X and same eX
e = e | loudTest('setAndRunNoiselessFromFixedSeed','set and run twice with fixed seed no wind no GPS');

% with random seed:
% two reset of qrsim should give the same X but different eX
e = e | loudTest('doubleQRSimResetWithRandomSeed','double qrsim reset with random seed','TaskNoWindRandomSeed');
e = e | loudTest('doubleQRSimResetWithRandomSeed','double qrsim reset with random seed windy','TaskWindRandomSeed');

% with fix seed:
% two reset of qrsim should give the same X and same eX
e = e | loudTest('doubleQRSimResetWithFixedSeed','double qrsim reset with fixed seed','TaskNoWindFixedSeed');
e = e | loudTest('doubleQRSimResetWithFixedSeed','double qrsim reset with fixed seed windy','TaskWindFixedSeed');

% with random seed:
% two reset of qrsim should give the same X but different eX
e = e | loudTest('initAndQRSimResetWithRandomSeed','init vs reset qrsim with random seed','TaskNoWindRandomSeed');
e = e | loudTest('initAndQRSimResetWithRandomSeed','init vs reset qrsim with random seed windy','TaskWindRandomSeed');

% with fix seed:
% the init E and eX and the ones after a reset of qrsim should be the same
e = e | loudTest('initAndQRSimResetWithFixedSeed','init vs reset qrsim with fixed seed','TaskNoWindFixedSeed');
e = e | loudTest('initAndQRSimResetWithFixedSeed','init vs reset qrsim with fixed seed windy','TaskWindFixedSeed');

cd('..');

end


function e = initAndQRSimResetWithFixedSeed(tsk)

e = 0;

U = [0;0;0.59004353928;0;11];

% create simulator object
qrsim = QRSim();

% load task parameters and do housekeeping
state = qrsim.init(tsk);

for i=1:50
    qrsim.step(U);
end
X1 = state.platforms{1}.getX();
eX1 = state.platforms{1}.getEX();

qrsim.resetSeed();
qrsim.reset();
for i=1:50
    qrsim.step(U);
end
X2 = state.platforms{1}.getX();
eX2 = state.platforms{1}.getEX();

e = e || ~all(X1==X2) || ~all(eX1==eX2);

% clear the state
clear state;

end

function e = initAndQRSimResetWithRandomSeed(tsk)

e = 0;

U = [0;0;0.59004353928;0;11];

% create simulator object
qrsim = QRSim();

% load task parameters and do housekeeping
state = qrsim.init(tsk);

for i=1:50
    qrsim.step(U);
end
X1 = state.platforms{1}.getX();
eX1 = state.platforms{1}.getEX();

qrsim.resetSeed();
qrsim.reset();
for i=1:50
    qrsim.step(U);
end
X2 = state.platforms{1}.getX();
eX2 = state.platforms{1}.getEX();

e = e || ~all(X1==X2) || all(eX1==eX2);

% clear the state
clear state;

end

function e = doubleQRSimResetWithRandomSeed(tsk)

e = 0;

U = [0;0;0.59004353928;0;11];

% create simulator object
qrsim = QRSim();

% load task parameters and do housekeeping
state = qrsim.init(tsk);

qrsim.resetSeed();
qrsim.reset();
for i=1:50
    qrsim.step(U);
end
X1 = state.platforms{1}.getX();
eX1 = state.platforms{1}.getEX();

qrsim.resetSeed();
qrsim.reset();
for i=1:50
    qrsim.step(U);
end
X2 = state.platforms{1}.getX();
eX2 = state.platforms{1}.getEX();

e = e || ~all(X1==X2) || all(eX1==eX2);

% clear the state
clear state;

end



function e = doubleQRSimResetWithFixedSeed(tsk)

e = 0;

U = [0;0;0.59004353928;0;11];

% create simulator object
qrsim = QRSim();

% load task parameters and do housekeeping
state = qrsim.init(tsk);

qrsim.resetSeed();
qrsim.reset();
for i=1:50
    qrsim.step(U);
end
X1 = state.platforms{1}.getX();
eX1 = state.platforms{1}.getEX();

qrsim.resetSeed();
qrsim.reset();
for i=1:50
   qrsim.step(U);
end
X2 = state.platforms{1}.getX();
eX2 = state.platforms{1}.getEX();

e = e || ~all(X1==X2) || ~all(eX1==eX2);

% clear the state
clear state;

end



function e = initAndResetFromRandomSeed()

e = 0;

setX = [1;2;3;0;0;pi;0;0;0;0;0;0];

% create simulator object
qrsim = QRSim();

% load task parameters and do housekeeping
state = qrsim.init('TaskNoWindRandomSeed');

X1 = state.platforms{1}.getX();
eX1 = state.platforms{1}.getEX();

state.platforms{1}.setX(setX);

X2 = state.platforms{1}.getX();
eX2 = state.platforms{1}.getEX();

e = e || ~all(X1==X2) || all(eX1==eX2);

% clear the state
clear state;

end


function e = initAndResetFromFixedSeed()

e = 0;

setX = [1;2;3;0;0;pi;0;0;0;0;0;0];

% create simulator object
qrsim = QRSim();

% load task parameters and do housekeeping
state = qrsim.init('TaskNoWindFixedSeed');

state.t=0;
state.rStreams = RandStream.create('mrg32k3a','seed',12345,'NumStreams',state.numRStreams,'CellOutput',1);
state.environment.gpsspacesegment.reset();

state.platforms{1}.setX(setX);

X1 = state.platforms{1}.getX();
eX1 = state.platforms{1}.getEX();

state.t=0;
state.rStreams = RandStream.create('mrg32k3a','seed',12345,'NumStreams',state.numRStreams,'CellOutput',1);
state.environment.gpsspacesegment.reset();

state.platforms{1}.setX(setX);

X2 = state.platforms{1}.getX();
eX2 = state.platforms{1}.getEX();

e = e || ~all(X1==X2) || ~all(eX1==eX2);

% clear the state
clear state;

end


function e = initAndResetFromFixedSeedNoiseless()

e = 0;

setX = [1;2;3;0;0;pi;0;0;0;0;0;0];

% create simulator object
qrsim = QRSim();

% load task parameters and do housekeeping
state = qrsim.init('TaskNoiselessGPSNoWindFixedSeed');


state.platforms{1}.setX(setX);

X1 = state.platforms{1}.getX();
eX1 = state.platforms{1}.getEX();

qrsim.resetSeed();
qrsim.reset();
state.platforms{1}.setX(setX);

X2 = state.platforms{1}.getX();
eX2 = state.platforms{1}.getEX();

e = e || ~all(X1==X2) || ~all(eX1==eX2);

% clear the state
clear state;

end

function e = setAndRunFromRandomSeed()

e = 0;

U = [0;0;0.59004353928;0;11];
setX = [1;2;3;0;0;pi;0;0;0;0;0;0];

% create simulator object
qrsim = QRSim();

% load task parameters and do housekeeping
state =  qrsim.init('TaskNoWindRandomSeed');

for i=1:50
    qrsim.step(U);
end

X1 = state.platforms{1}.getX();
eX1 = state.platforms{1}.getEX();

state.platforms{1}.setX(setX);

for i=1:50
    qrsim.step(U);
end

X2 = state.platforms{1}.getX();
eX2 = state.platforms{1}.getEX();

e = e || ~all(X1==X2) || all(eX1==eX2);

% clear the state
clear state;

end


function e = setAndRunFromFixedSeed()

e = 0;

U = [0;0;0.59004353928;0;11];
setX = [1;2;3;0;0;pi;0;0;0;0;0;0];

% create simulator object
qrsim = QRSim();

% load task parameters and do housekeeping
state = qrsim.init('TaskNoWindFixedSeed');


state.t=0;
state.rStreams = RandStream.create('mrg32k3a','seed',12345,'NumStreams',state.numRStreams,'CellOutput',1);
state.environment.gpsspacesegment.reset();
state.platforms{1}.setX(setX);

for i=1:50
    qrsim.step(U);
end

X1 = state.platforms{1}.getX();
eX1 = state.platforms{1}.getEX();

state.t=0;
state.rStreams = RandStream.create('mrg32k3a','seed',12345,'NumStreams',state.numRStreams,'CellOutput',1);
state.environment.gpsspacesegment.reset();
state.platforms{1}.setX(setX);

for i=1:50
    qrsim.step(U);
end

X2 = state.platforms{1}.getX();
eX2 = state.platforms{1}.getEX();

e = e || ~all(X1==X2) || ~all(eX1==eX2);

% clear the state
clear state;

end


function e = setAndRunNoiselessFromFixedSeed()

e = 0;

U = [0;0;0.59004353928;0;11];
setX = [1;2;3;0;0;pi;0;0;0;0;0;0];

% create simulator object
qrsim = QRSim();

% load task parameters and do housekeeping
state = qrsim.init('TaskNoiselessGPSNoWindFixedSeed');

state.platforms{1}.setX(setX);

for i=1:50
    qrsim.step(U);
end

X1 = state.platforms{1}.getX();
eX1 = state.platforms{1}.getEX();

qrsim.resetSeed();
qrsim.reset();
state.platforms{1}.setX(setX);

for i=1:50
    qrsim.step(U);
end

X2 = state.platforms{1}.getX();
eX2 = state.platforms{1}.getEX();

e = e || ~all(X1==X2) || ~all(eX1==eX2);

% clear the state
clear state;

end

function e = simpleSetState()

e = 0;

% create simulator object
qrsim = QRSim();

% load task parameters and do housekeeping
state = qrsim.init('TaskNoWindRandomSeed');

% failing
shortX = [0;1;2];
e = e | loudTest('failingState','state too short',shortX,state,'pelican:wrongsetstate');

longX = [1;2;3;4;5;6;7;8;9;10;11;12;13;14];
e = e | loudTest('failingState','state too long',longX,state,'pelican:wrongsetstate');

wrongX = [1;2;3;4;5];
e = e | loudTest('failingState','state size wrong 1',wrongX,state,'pelican:wrongsetstate');

wrongX = [1;2;3;4;5;6;7;8];
e = e | loudTest('failingState','state size wrong 2',wrongX,state,'pelican:wrongsetstate');


limits = state.platforms{1}.getStateLimits();

oobX = [limits(1,2)*1.1;0;0];
e = e | loudTest('failingState','posx value out of bounds',oobX,state,'pelican:wrongsetstate');

oobX = [0;limits(2,2)*1.1;0];
e = e | loudTest('failingState','posy value out of bounds',oobX,state,'pelican:wrongsetstate');

oobX = [0;0;limits(3,2)*1.1];
e = e | loudTest('failingState','posz value out of bounds',oobX,state,'pelican:wrongsetstate');

validX = [1;2;3;0.01;0.01;1];
e = e | loudTest('validSetState','valid state of size 6',validX,state);

validX = [1;2;3;0.01;0.01;1;0.01;0.01;0.01;0.01;0.01;0.01];
e = e | loudTest('validSetState','valid state of size 12',validX,state);

validX = [1;2;3;0.01;0.01;1;0.01;0.01;0.01;0.01;0.01;0.01;state.platforms{1}.MASS*state.platforms{1}.G];
e = e | loudTest('validSetState','valid state of size 13',validX,state);

% clear the state
clear state;

end

function e = failingState(X,state,id)

e = 0;

try
    state.platforms{1}.setX(X);
    e = 1;
catch exception
    if(~strcmp(exception.identifier,id))
        e = 1;
        fprintf('\nUNEXPECTED EXCEPTION:%s \nMESSAGE:%s\n',exception.identifier,exception.message);
    end
end

end


function e = validSetState(x,state)

e = 0;

try
    state.platforms{1}.setX(x);
catch exception
    e = 1;
    fprintf('\nUNEXPECTED EXCEPTION:%s \nMESSAGE:%s\n',exception.identifier,exception.message);
end

X = state.platforms{1}.getX();
if(length(x)==6)
    
    e = e | ~all(X(1:12)==[x;zeros(6,1)]);
else
    if (length(x)==12)
        e = e | ~all(X(1:12)==x);
    else
        if (length(x)==13)
            e = e | ~all(X==x);
        end
    end
end

end

function [ e ] = loudTest(fun,msg,varargin)
%LOUDTEST run a test function an print result in console

switch size(varargin,2)
    case 3
        e = feval(fun,varargin{1},varargin{2},varargin{3});
    case 2
        e = feval(fun,varargin{1},varargin{2});
    case 1
        e = feval(fun,varargin{1});
    otherwise    
        e = feval(fun);
end

if(e)
    fprintf(['Test ',msg,' [FAILED]\n']);
else
    fprintf(['Test ',msg,' [PASSED]\n']);
end

end
