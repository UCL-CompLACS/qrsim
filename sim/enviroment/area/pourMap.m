function map = pourMap(Nr,Nc,p,rnd)
% given map size, build a map where with regions that
% belongs to one of the length(p)+1 classes (ground beiong always a class)
% the number of pixel for region i is roughly proportional to the probability
% p(i) for that region, hence sum(p)< 1 and P(ground) = 1-sum(p)

% the map
map = zeros(Nr,Nc);

% number of different classes
numClasses = length(p);

% rough number of squares for each class
N = p.*Nr*Nc;

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
    x = randi(Nr,1);
    y = randi(Nc,1);
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
        x = mod(x+round(d*sin(alpha)),Nr)+1;
        y = mod(y-round(d*cos(alpha)),Nc)+1;
        
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
                if(map(xx,yy)~=c)
                    map(xx,yy)=c;
                    n(c)=n(c)+1;
                    break
                end                
                % othrwise drift to the frontier
                if(xx==1 || xx==Nr || yy==1 || yy==Nc)
                    xD = xx+D1;
                    yD = yy+D2;
                    mask = ((xD>0)&(xD<=Nr)&(yD>0)&(yD<=Nc));
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