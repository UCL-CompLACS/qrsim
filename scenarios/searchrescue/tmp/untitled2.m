clear all;

m= 100;
n = 70;
mm1 = perlin(m,n);
    mm1(mm1>=0)=1;
    mm1(mm1<0)=2;
    mm2 = perlin(m,n);
    mm2(mm2>=0)=3;
    mm2(mm2<0)=5;
    mm = mm1;
%     v= zeros(4,2);
%    v(1,1) = sum(sum(mm==4));
%    v(1,2) = 4;
%    v(2,1) = sum(sum(mm==5)); 
%    v(2,2) = 5;
%    v(3,1) = sum(sum(mm==6));
%    v(3,2) = 6;
%    v(4,1) = sum(sum(mm==7)); 
%    v(4,2) = 7;
%   
%    
%    sort(v,2);
%    
%    mm(mm==v(1,2))=v(4,2);
%    v(4,1)=v(1,1)+v(4,1);
%    v(1,:)=[];
%    
%    mm(mm==v(1,2))=3;
%    mm(mm==v(2,2))=2;   
%    mm(mm==v(3,2))=1;
%     
%    sum(mm==3)
    
    pcolor(mm);
    axis equal;