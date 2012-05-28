function [ e ] = testCollision()
%test that two runs with the same seed produce identical outputs

clear all;

e = 0;

cd('collision');

U = [0,0;0,0;0.59004353928,0.59004353928;0,0;11,11];

qrsim = QRSim();

state = qrsim.init('TaskTwoUAVS');

%%% test a bunch of cases in which two heleicopter are placed closer than the
%%% collision distance

qrsim.step(U);

e = ~(state.platforms{1}.isValid() && state.platforms{2}.isValid());


N = 100;

% position of first chopper
posHA = 200*rand(3,N)-100;
r = state.platforms{1}.getCollisionDistance()*rand(1,N);
theta = pi*rand(1,N);
psi = 2*pi*rand(1,N);

% position of second chopper
posHB = posHA+[r.*cos(psi).*sin(theta);r.*sin(psi).*sin(theta);r.*cos(theta)];

for i = 1:N

    state.platforms{1}.setX([posHA(:,i);zeros(9,1)]);
    state.platforms{2}.setX([posHB(:,i);zeros(9,1)]);

    qrsim.step(U);
    
    e = e || (state.platforms{1}.isValid() || state.platforms{2}.isValid());
    
end    

if(e)
    fprintf('Test collision checking [FAILED]\n');
else
    fprintf('Test collision checking [PASSED]\n');
end

cd('..');

end
