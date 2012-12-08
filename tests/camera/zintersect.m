function pp = zintersect(p,t)


z=0;
x=(p(1)-t(1))*((z-t(3))/(p(3)-t(3)))+t(1);
y=(p(2)-t(2))*((z-t(3))/(p(3)-t(3)))+t(2);


pp=[x;y;z];