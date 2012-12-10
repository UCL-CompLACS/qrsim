function [D] = knnsearch(Q,R,exclude)
% KNNSEARCH   Linear k-nearest neighbor (KNN) search
% IDX = knnsearch(Q,R,exclude) searches the reference data set R (n x d array
% representing n points in a d-dimensional space) to find the nearest
% neighbors of each query point represented by each row of Q (m x d array).
% Samples with index specified in exclude are not searched.
%
assert((size(Q,2)==size(R,2)),'query points and reference samples must have the same number of dimensions');   

% Check outputs
nargoutchk(0,1);

[N,M] = size(Q);
L=size(R,1);
D = zeros(N,1);

% Loop for each query point
for k=1:N
    d=zeros(L,1);
    for t=1:M
        d=d+(R(:,t)-Q(k,t)).^2;
    end
    if (~isempty(exclude))
        d(exclude(k))=inf;
    end
    D(k)=min(d);
end

D=sqrt(D);
