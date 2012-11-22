function [ e ] = testSeed()
%test that two runs with the same seed produce identical outputs

clear all;

cd('seed');

N = 100;
e = 0;

% run it once with fix seed
[X1,eX1] = runSim('TaskFixSeed',N);

% run it again with the same initial seed
[X2,eX2] = runSim('TaskFixSeed',N);

r = ~all(all(X1==X2)) || ~all(all(eX1==eX2));

if(r)
    fprintf('Test comparison of runs with fix seed [FAILED]\n');
else
    fprintf('Test comparison of runs with fix seed [PASSED]\n');
end

e = e || r;

% run it again with random initial seed
[X1,eX1] = runSim('TaskRandomSeed',N);

% run it again with another with random initial seed
[X2,eX2] = runSim('TaskRandomSeed',N);

r = ~all(all(X1==X2)) || all(all(eX1==eX2));

if(r)
    fprintf('Test comparison of runs with random seed [FAILED]\n');
else
    fprintf('Test comparison of runs with random seed [PASSED]\n');
end
e = e || r;

cd('..');

end

function [X,eX] = runSim(task,N)

eX=zeros(23,N);
X=zeros(13,N);

% a control that in absence of noise gives perfect hover
U = [0;0;0.59004353928;0;11];

% create simulator object
qrsim = QRSim();

% load task parameters and do housekeeping
state = qrsim.init(task);


for i=1:N    
    % step simulator
    qrsim.step(U);
          
    eX(1:20,i) = state.platforms{1}.getEX();
    eX(21:23,i) = state.platforms{1}.getA();
    X(:,i) = state.platforms{1}.getX();
    
    if(mod(i,10)==0)
        fprintf('.');
    end
end

% clear the state
clear state;

end
