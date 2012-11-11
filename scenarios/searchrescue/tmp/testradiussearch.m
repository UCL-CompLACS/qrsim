

pts = 2*rand(200,2);
exclude = [zeros(100,1);ones(100,1)];
q = [1 1];
r = 1;
idx = knnradiussearch(q,pts,r,exclude);

circle = [r*sin(0:0.1:(2*pi))+q(1);r*cos(0:0.1:(2*pi))+q(2)];

figure();
plot(pts(:,1),pts(:,2),'.');
hold on;
plot(pts(idx,1),pts(idx,2),'*r');
axis equal;
plot(circle(1,:),circle(2,:),'g');