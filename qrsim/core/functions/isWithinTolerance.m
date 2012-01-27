 function [f] = isWithinTolerance(a,b,tol)
 % ISWITHINTOLERANCE Checks if the elements of two matrices are within tolerance
 %  
 %  ISWITHINTOLERANCE(A,B,TOL)
 %
    t = (abs(a-b)<tol);
    
    z = ones(size(a,1),size(a,2));
    
    f = (t==z);
 end