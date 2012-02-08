function [ e ] = testCollision()
%test that two runs with the same seed produce identical outputs

e = 0;

clear all;

cd('collision');

U = [0,0;0,0;0.59004353928,0.59004353928;0,0;11,11];

% new state structure
global state;

qrsim = QRSim();

qrsim.init('TaskTwoUAVS');

%%% test a bunch of cases in which two heleicopter are placed closer than the
%%% collision distance

qrsim.step(U);

e = ~(state.platforms(1).valid && state.platforms(2).valid);


N = 100;

% position of first chopper
posHA = 200*rand(3,N)-100;
r = state.platforms(1).params.collisionDistance*rand(1,N);
theta = pi*rand(1,N);
psi = 2*pi*rand(1,N);

% position of second chopper
posHB = posHA+[r.*cos(psi).*sin(theta);r.*sin(psi).*sin(theta);r.*cos(theta)];

for i = 1:N

    state.platforms(1).setState([posHA(:,i);zeros(9,1)]);
    state.platforms(2).setState([posHB(:,i);zeros(9,1)]);

    qrsim.step(U);
    
    e = e || (state.platforms(1).valid || state.platforms(2).valid);
    
end    

% clear the state
clear global state;

cd('..');

end
