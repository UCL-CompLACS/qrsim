clear all;

Nr= 100;
Nc = 100;

O = 1; % red
C = 2; % blue
p = [0.05;0.15];

%assert((pO>=0 && pO<=1 && pC>=0 && pC<=1 && (pC+pO)<1),'po, pc and their sum must all be in the interval 0-1');

N = floor(p*Nr*Nc);

map = zeros(Nr,Nc);
n = [0;0];
pexp = [0.62;0.66];

ids = [-1 1 -Nr Nr -Nr-1 Nr+1 -Nr+1 Nr-1];
while(any(n<N))
    
    idxs = find(map==0);
    i = randi(length(idxs),1);
    
    if(all(n<N))
        r = rand(1);
        if(r<(p(O)/(p(O)+p(C))))
            cl = O;
        else
            cl = C;
        end
    else
        if(n(O)<N(O))
            cl=O;
        else
            cl=C;
        end
    end
    map(i) = cl;
    toExpand = [i;cl];
    n(cl) = n(cl)+1;
    
    while(~isempty(toExpand))
        
        j = toExpand(1,1);
        cl = toExpand(2,1);
        toExpand(:,1)=[];
        
        c = ceil(j/Nr);
        r = mod(j-1,Nr)+1;
        mask = ones(1,8);
        if(r==1)
            mask = mask & [0 1 1 1 0 1 1 0];
        end
        if(r==Nr)
            mask = mask & [1 0 1 1 1 0 0 1];
        end
        if(c==1)
            mask = mask & [1 1 0 1 0 1 0 1];
        end
        if(c==Nc)
            mask = mask & [1 1 1 0 1 0 1 0];
        end
        iids = j+ids(1,logical(mask));
        
        if(n(cl)<N(cl))            
            %if(sum(map(iids)==cl)>5)
            %    map(j)=cl;
            %    n(cl)= n(cl)+1;
            %else 
               if(rand(1)>pexp(cl))
                    map(j)=cl;
                    n(cl)= n(cl)+1;
                    tmp = iids(map(iids)==0);
                    tbd = [];
                    for k = 1:length(tmp)
                        if(any(toExpand(1,:)==tmp(k)))
                            tbd=[tbd,k];%#ok<AGROW>
                        end
                    end
                    tmp(tbd)=[];
                    
                    toExpand = [toExpand,[tmp;ones(1,length(tmp))*cl]]; %#ok<AGROW>
                else
                    if(all(mask))
                       map(j)=0; 
                    end    
                end
           % end
        end
    end
end
map(map==1)=4;
map(map==0)=1;% grass = green
map(map==2)=0;% clutter blue
map(map==4)=2;% occluded red
figure(1);
pcolor(map);
axis equal;