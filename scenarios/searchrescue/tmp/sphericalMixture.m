function [x,y,z,c] = sphericalMixture(nn)

n = nn+randi(10,1);

poss = repmat([-pi/2;-pi],1,n)+rand(2,n).*repmat([pi/2;2*pi],1,n);
sds = 5+10*rand(1,n);


mp = [-pi/2:0.05:0,0];
ma =[-pi:0.1:pi,pi];

c = ones(length(mp),length(ma));
x = zeros(length(mp),length(ma));
y = zeros(length(mp),length(ma));
z = zeros(length(mp),length(ma));

for i=1:length(mp),
   for j=1:length(ma),  
       for k=1:n,  
           d = poss(:,k)-[mp(i);ma(j)];
           d(2)=min([d(2),d(2)+2*pi]);
           if(abs(d(2)-2*pi)<abs(d(2)))
              d(2) =  d(2) - 2*pi*sign(d(2));
           end
           
           c(i,j)=c(i,j)*(1-exp(-(d'*d)/2*sds(k)^2));
       end
       x(i,j) =  c(i,j)*sin(mp(i))*cos(ma(j));
       y(i,j) =  c(i,j)*sin(mp(i))*sin(ma(j));
       z(i,j) =  c(i,j)*cos(mp(i));  
   end
end
c = 1-c;
