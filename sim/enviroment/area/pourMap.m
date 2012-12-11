function map = pourMap(NNr,NNc,p,rnd)
% given map size, build a map where regions belongs to one of the length(p)+1 
% classes (ground being always the class 1).
% The number of pixel for region i is roughly proportional to the probability
% p(i) for that region, hence sum(p)< 1 and P(ground) = 1-sum(p)

% the small map
nr = 50;
nc = 50;
smap = zeros(nr,nc);

% number of different classes
numClasses = length(p);

% rough number of squares for each class
N = p.*nr*nc;

% spread directions
D = [1 0 -1  0 ;
     0 1  0 -1 ];
D1 = D(1,:);
D2 = D(2,:);

% use passed random numbers
nrnd = length(rnd);
rcnt = 1;


% cell counter for each class
n = zeros(numClasses,1);

% for each class 
for c=1:numClasses,    
    x = randi(nr,1);
    y = randi(nc,1);
    while n(c)<N(c)
        % Exponential jumps between pour locations
        %d = 4*(-log(rand()));
        d = 4*(-log(rnd(rcnt)));
        rcnt = rcnt+1;
        if(rcnt>nrnd), rcnt=1; end
        % in random direction
        alpha = 2*pi*rnd(rcnt);
        rcnt = rcnt+1;
        if(rcnt>nrnd), rcnt=1; end        
        x = mod(x+round(d*sin(alpha)),nr)+1;
        y = mod(y-round(d*cos(alpha)),nc)+1;
        
        % random amound of pouring
        %nn = 10+randi(100,1);
        nn = 10+ceil(100*rnd(rcnt));
        rcnt = rcnt+1;
        if(rcnt>nrnd), rcnt=1; end        
        for j=1:nn,
            % check if poured enough
            if (n(c)>= N(c)), break; end
            xx = x;
            yy = y;
            while 1
                % pour a drop of color c at location x,y
                if(smap(xx,yy)~=c)
                    smap(xx,yy)=c;
                    n(c)=n(c)+1;
                    break
                end                
                % othrwise drift to the frontier
                if(xx==1 || xx==nr || yy==1 || yy==nc)
                    xD = xx+D1;
                    yD = yy+D2;
                    mask = ((xD>0)&(xD<=nr)&(yD>0)&(yD<=nc));
                    %k = randi(sum(mask),1);
                    k = ceil(sum(mask)*rnd(rcnt));
                    rcnt = rcnt+1;
                    if(rcnt>nrnd), rcnt=1; end
                    DD = D(:,mask);
                    xx = xx+DD(1,k);
                    yy = yy+DD(2,k);
                else
                    %k = randi(4,1);
                    k = ceil(4*rnd(rcnt));
                    rcnt = rcnt+1;
                    if(rcnt>nrnd), rcnt=1; end
                    xx = xx+D1(k);
                    yy = yy+D2(k);
                end
            end
        end
    end    
end

[X,Y] = meshgrid(0:NNc/(nc-1):NNc,0:NNr/(nr-1):NNr);
[x,y] = meshgrid(0:NNc/(NNc-1):NNc,0:NNr/(NNr-1):NNr);
map = interp2(X,Y,smap,x,y,'nearest');
