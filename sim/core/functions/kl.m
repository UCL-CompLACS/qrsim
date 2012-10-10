function [ klest ] = kl(P,Q)
%UNTITLED Summary of this function goes here
%   Detailed explanation goes here

d = size(P,2);
m = size(P,1);
n = size(Q,1);

sumlog = 0;
for i=1:n,    
    rhoi = knnsearch(P(i,:),P,i);
    nui = knnsearch(P(i,:),Q);
       
    sumlog = sumlog + log(nui/rhoi);
end
klest = (d/n)*sumlog+log(m/(n-1));

end

