function [xf,yf]=pourAt(map,x,y,c)

d = [1 1 0 -1 -1  0  1 -1;
     1 0 1 -1  0 -1 -1  1];

% pour a drop of color c at location x,y in the map

if(x>0 && x<size(map,1) && y>0 && y<size(map,2))
    if(map(x,y)~=c)
        xf = x;
        yf = y;
    else
        i = randi(8,1);
        [xf,yf]=pourAt(map,x+d(1,i),y+d(2,i),c);
    end
else
   xf = 1;
   yf = 1;
end

end
