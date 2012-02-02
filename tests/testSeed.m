function [ e ] = testSeed()
%test that two runs with the same seed produce identical outputs

clear all;

cd('seed');

N = 1000;

% run it once with fix seed
eX1 = runSim('TaskFixSeed',N);

% run it again with the same initial seed
eX2 = runSim('TaskFixSeed',N);


e = ~all(all(eX1==eX2));

% run it again with random initial seed
eX1 = runSim('TaskRandomSeed',N);

% run it again with another with random initial seed
eX2 = runSim('TaskRandomSeed',N);


e = e || all(all(eX1==eX2));

cd('..');

end

function eX = runSim(task,N)

eX=zeros(23,N);

% a control that in absence of noise gives perfect hover
U = [0;0;0.59004353928;0;11];

% new state structure
global state;

% create simulator object
qrsim = QRSim();

% load task parameters and do housekeeping
qrsim.init(task);


for i=1:N    
    % step simulator
    qrsim.step(U);
          
    eX(1:20,i) = state.platforms(1).eX;
    
    if(mod(i,1000)==0)
        fprintf('.');
    end
    eX(21:23,i) = state.platforms(1).a;
end

% clear the state
clear global state;

end
