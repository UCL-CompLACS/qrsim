 function [f] = isWithinTolerance(a,b,tol)
 % ISWITHINTOLERANCE Checks if the elements of two matrices are within tolerance
 %  
 %  ISWITHINTOLERANCE(A,B,TOL)
 %
    t = (abs(a-b)<tol);
    
    f = all(t);
 end