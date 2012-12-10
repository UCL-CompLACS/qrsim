function [ klest ] = kl(P,Q)
%KLEST Estimates KL divergence
% estimates the KL divergence between two distributions P and Q represented
% as a set of samples

d = size(P,2);
n = size(P,1);
m = size(Q,1);

w = 0;
sumlog = 0;
for i=1:n,    
    rhon_i = knnsearch(P(i,:),P,i);
    num_i = knnsearch(P(i,:),Q,[]);
       
    if((num_i > 1e-20)&&(rhon_i > 1e-20)) 
       sumlog = sumlog + log(num_i/rhon_i);
    else
       w = w+1; 
    end
end

if(m==w)
    klest = 0; 
else    
    klest = (d/(n-w))*sumlog+log((m-w)/(n-w-1));
end

end

