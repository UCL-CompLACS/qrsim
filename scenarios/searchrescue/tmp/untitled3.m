
clear all;
close all;

figure();

subplot(1,3,1);

[x,y,z,c] = sphericalMixture(2);

surf(x,y,z,c);
hold on;
plot3(1,1,5,'b*');
plot3([0,1],[0,1],[0,5],'r');
axis equal;

title('grass');

subplot(1,3,2);
[x,y,z,c] = sphericalMixture(12);

surf(x,y,z,c);
hold on;
plot3(1,1,5,'b*');
plot3([0,1],[0,1],[0,5],'r');
axis equal;

title('bushes');

subplot(1,3,3);
[x,y,z,c] = sphericalMixture(45);

surf(x,y,z,c);
hold on;
plot3(1,1,5,'b*');
plot3([0,1],[0,1],[0,5],'r');
axis equal;

title('forest');


