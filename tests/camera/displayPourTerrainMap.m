clear all;

Nr= 250;
Nc = 153;

p = [0.2;0.05];

rnd = rand(50*50*length(p),1);
tic
map = pourMap(Nr,Nc,p,rnd);
toc

figure(1);
pcolor(map);

