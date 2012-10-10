function D=knnsearch(varargin)
% KNNSEARCH   Linear k-nearest neighbor (KNN) search
% IDX = knnsearch(Q,R,K) searches the reference data set R (n x d array
% representing n points in a d-dimensional space) to find the k-nearest
% neighbors of each query point represented by eahc row of Q (m x d array).


% Check inputs
narginchk(2,3);

Q=varargin{1};
R=varargin{2};

assert((size(Q,2)==size(R,2)),'query points and reference samples must have the same number of dimensions');   

if (nargin==3)
    exclude = varargin{3};
    assert((size(Q,1)==size(exclude,1)),'exclude list must have the same lenght of the query point');
else
    exclude = [];
end


% Check outputs
nargoutchk(0,1);

% C2 = sum(C.*C,2)';
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
