clear all;

mm1 = perlin(300);
    mm1(mm1>=0)=1;
    mm1(mm1<0)=2;
    mm2 = perlin(300);
    mm2(mm2>=0)=3;
    mm2(mm2<0)=5;
    mm = mm1+mm2;
    v= zeros(4,2);
   v(1,1) = sum(sum(mm==4));
   v(1,2) = 4;
   v(2,1) = sum(sum(mm==5)); 
   v(2,2) = 5;
   v(3,1) = sum(sum(mm==6));
   v(3,2) = 6;
   v(4,1) = sum(sum(mm==7)); 
   v(4,2) = 7;
  
   
   sort(v,2);
   
   mm(mm==v(1,2))=v(4,2);
   v(4,1)=v(1,1)+v(4,1);
   v(1,:)=[];
   
   mm(mm==v(1,2))=3;
   mm(mm==v(2,2))=2;   
   mm(mm==v(3,2))=1;
    
%     mm3 = perlin(300);
%     mm3(mm3>0)=16;
%     mm3(mm3<0)=-20;
    
%     mm(mm==38)=2; 
%     mm(mm==34)=2;
%     mm(mm==31)=4; 
%     mm(mm==27)=5;
%     mm(mm==-9)=4;
%     mm(mm==-5)=5;
%     mm(mm==-2)=2; 
%     mm(mm==2)=2; 

%     mm((mm>-7)&(mm<7))=0;
%     mm((mm>0)&(mm<5))=2.5;
 %    mm(mm<-7)=-7;
    
    pcolor(mm);
    