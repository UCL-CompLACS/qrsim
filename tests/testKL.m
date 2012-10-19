function [e]=testKL()
% returns 0 if no errors

TOL1 = 0.2;
TOL2 = 0.02;

%%% test using multivariate Gaussians distributed samples
% dimensions
k = 10;
% number of samples
N = 10000;

% P samples
muP = ones(k,1);
sigmaP = 0.5*eye(k,k)+0.5*ones(k,k);
P = mvnrnd(muP,sigmaP, N);

% Q samples
muQ = ones(k,1);
sigmaQ = 0.9*eye(k,k)+0.1*ones(k,k);
Q = mvnrnd(muQ,sigmaQ, 2*N);

% estimated KL using samples
klest = kl(P,Q);

% P and Q are multivariate Gaussians so we can compute the KL in close form
kltrue = 0.5*(trace(inv(sigmaQ)*sigmaP)+(muQ-muP)'*inv(sigmaQ)*(muQ-muP)-log(det(sigmaP)/det(sigmaQ))-k);

if(isWithinTolerance(kltrue,klest,TOL1))
    fprintf('KL test Gaussian [PASSED]\n');
    e = 0;
else
    fprintf('KL test Gaussian [FAILED]\n');
    e = 1;
end

%%% test using Reyleigh distributed samples
sigmaP = 1;
sigmaQ = 2;

% P samples
P = raylrnd(sigmaP,N,1);
% Q samples
Q = raylrnd(sigmaQ,N,1);

% estimated KL using samples
klest = kl(P,Q);

% P and Q are multivariate Gaussians so we can compute the KL in close form
kltrue = log(sigmaQ^2/sigmaP^2)+(sigmaP^2-sigmaQ^2)/sigmaQ^2;

if(isWithinTolerance(kltrue,klest,TOL2))
    fprintf('KL test Reyleigh [PASSED]\n');
    e = e & 0;
else
    fprintf('KL test Reyleigh [FAILED]\n');
    e = e & 1;
end

end


function [f] = isWithinTolerance(a,b,tol)
% ISWITHINTOLERANCE Checks if the elements of two matrices are within tolerance
%
%  ISWITHINTOLERANCE(A,B,TOL)
%
t = (abs(a-b)<tol);

f = all(t);
end
