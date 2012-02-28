function m = dcm( X )
%DCM compute the direct cosin rotation that transforms from the ref frame to the body frame.
%
%This is nothing more then a call to the more general angleToDcm using a state as input and 
%the rotation order defined for our platform 

m =  angleToDcm(X(6),X(5),X(4));

end

