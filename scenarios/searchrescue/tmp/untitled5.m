clear all;


Nr= 150;
Nc = 150;

p = [0.3;0.05];

rnd = rand(Nr*Nc*length(p),1);
tic
map = pourMap(Nr,Nc,p,rnd);
toc
figure(1);
pcolor(map);




