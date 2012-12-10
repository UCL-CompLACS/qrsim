function idx = knnradiussearch(Q,R,r,exclude)
% KNNSEARCH   Linear nearest neighbor (KNN) search
% IDX = knnradiusssearch(Q,R,radius,exclude) searches the reference data set R (n x d array
% representing n points in a d-dimensional space) to find the neighbours
% with distance lower than the specified radius from of each query point represented 
% by each row of Q (m x d array).
% Samples with index specified in exclude are not searched.
%
assert((size(Q,2)==size(R,2)),'query points and reference samples must have the same number of dimensions');   

% Check outputs
nargoutchk(0,1);

[M,D] = size(Q);
N=size(R,1);
idx = false(N,M);
r2 = r*r;

% Loop for each query point
for k=1:M
    d=zeros(N,1);
    for t=1:D
        d=d+(R(:,t)-Q(k,t)).^2;
    end    
    if (~isempty(exclude))
        idx(:,k) = (d<r2).*(~exclude);
    else
        idx(:,k) = (d<r2);
    end    
end

