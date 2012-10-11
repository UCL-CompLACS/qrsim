function [ klest ] = kl(P,Q)
%UNTITLED Summary of this function goes here
%   Detailed explanation goes here

d = size(P,2);
m = size(P,1);
n = size(Q,1);

w = 0;
sumlog = 0;
for i=1:n,    
    rhoi = knnsearch(P(i,:),P,i);
    nui = knnsearch(P(i,:),Q);
       
    if((nui > 1e-20)&&(rhoi > 1e-20)) 
       sumlog = sumlog + log(nui/rhoi);
    else
       w = w+1; 
    end
end

if(n==w)
    klest = 0; 
else    
    klest = (d/(n-w))*sumlog+log((m-w)/(n-w-1));
end

end

