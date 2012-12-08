function e = testKNNRadiousSearch()
display_on = 0;

pts = 2*rand(200,2);
exclude = [zeros(100,1);ones(100,1)];
q = [1 1];
r = 1;
idx = knnradiussearch(q,pts,r,exclude);

circle = [r*sin(0:0.1:(2*pi))+q(1);r*cos(0:0.1:(2*pi))+q(2)];

Diffs = mat2cell([pts(idx,1)-q(1,1),pts(idx,2)-q(1,2)],ones(1,sum(idx)),[2]);

D = cellfun(@norm,Diffs);

if(any(D>r))
    disp('test KNN radious search [FAILED]');
    e = 1;
else
    disp('test KNN radious search [PASSED]');
    e = 0;
end

if(display_on)
    figure(1);
    plot(pts(:,1),pts(:,2),'.');
    hold on;
    plot(pts(idx,1),pts(idx,2),'*r');
    axis equal;
    plot(circle(1,:),circle(2,:),'g');
end