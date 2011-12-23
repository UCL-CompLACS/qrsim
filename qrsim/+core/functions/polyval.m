function [y, delta] = polyval(p,x,S,mu)
%POLYVAL Evaluate polynomial.
%   Y = POLYVAL(P,X) returns the value of a polynomial P evaluated at X. P
%   is a vector of length N+1 whose elements are the coefficients of the
%   polynomial in descending powers.
%
%       Y = P(1)*X^N + P(2)*X^(N-1) + ... + P(N)*X + P(N+1)
%
%   If X is a matrix or vector, the polynomial is evaluated at all
%   points in X.  See POLYVALM for evaluation in a matrix sense.
%
%   [Y,DELTA] = POLYVAL(P,X,S) uses the optional output structure S created
%   by POLYFIT to generate prediction error estimates DELTA.  DELTA is an
%   estimate of the standard deviation of the error in predicting a future
%   observation at X by P(X).
%
%   If the coefficients in P are least squares estimates computed by
%   POLYFIT, and the errors in the data input to POLYFIT are independent,
%   normal, with constant variance, then Y +/- DELTA will contain at least
%   50% of future observations at X.
%
%   Y = POLYVAL(P,X,[],MU) or [Y,DELTA] = POLYVAL(P,X,S,MU) uses XHAT =
%   (X-MU(1))/MU(2) in place of X. The centering and scaling parameters MU
%   are optional output computed by POLYFIT.
%
%   Example:
%      Evaluate the polynomial p(x) = 3x^2+2x+1 at x = 5,7, and 9:
%
%      p = [3 2 1];
%      polyval(p,[5 7 9])%
%
%   Class support for inputs P,X,S,MU:
%      float: double, single
%
%   See also POLYFIT, POLYVALM.

%   Copyright 1984-2010 The MathWorks, Inc.
%   $Revision: 5.16.4.8 $  $Date: 2010/02/25 08:10:27 $

%   DELTA can be used to compute a 100(1-alpha)% prediction interval
%   for future observations at X, as Y +/- DELTA*t(alpha/2,df), where
%   t(alpha/2,df) is the upper (alpha/2) quantile of the Student's t
%   distribution with df degrees of freedom.  Since t(.25,df) < 1 for any
%   degrees of freedom, Y +/- DELTA is at least a 50% prediction interval
%   in all cases.  For large degrees of freedom, the confidence level
%   approaches approximately 68%.

% Check input is a vector
if ~(isvector(p) || isempty(p))
    error('MATLAB:polyval:InvalidP',...
            'P must be a vector.');
end

nc = length(p);
if isscalar(x) && (nargin < 3) && nc>0 && isfinite(x) && all(isfinite(p(:)))
    % Make it scream for scalar x.  Polynomial evaluation can be
    % implemented as a recursive digital filter.
    y = filter(1,[1 -x],p);
    y = y(nc);
    return
end

siz_x = size(x);
if nargin == 4
   x = (x - mu(1))/mu(2);
end

% Use Horner's method for general case where X is an array.
y = zeros(siz_x);
if nc>0, y(:) = p(1); end
for i=2:nc
    y = x .* y + p(i);
end

if nargout > 1
    if nargin < 3 || isempty(S)
        error('MATLAB:polyval:RequiresS',...
                'S is required to compute error estimates.');
    end
    
    % Extract parameters from S
    if isstruct(S),  % Use output structure from polyfit.
      R = S.R;
      df = S.df;
      normr = S.normr;
    else             % Use output matrix from previous versions of polyfit.
      [ms,ns] = size(S);
      if (ms ~= ns+2) || (nc ~= ns)
          error('MATLAB:polyval:SizeS',...
                'S matrix must be n+2-by-n where n = length(p).');
      end
      R = S(1:nc,1:nc);
      df = S(nc+1,1);
      normr = S(nc+2,1);
    end

    % Construct Vandermonde matrix for the new X.
    x = x(:);
    V(:,nc) = ones(length(x),1,class(x));
    for j = nc-1:-1:1
        V(:,j) = x.*V(:,j+1);
    end

    % S is a structure containing three elements: the triangular factor of
    % the Vandermonde matrix for the original X, the degrees of freedom,
    % and the norm of the residuals.
    E = V/R;
    e = sqrt(1+sum(E.*E,2));
    if df == 0
        warning('MATLAB:polyval:ZeroDOF',['Zero degrees of freedom implies ' ...
                'infinite error bounds.']);
        delta = Inf(size(e));
    else
        delta = normr/sqrt(df)*e;
    end
    delta = reshape(delta,siz_x);
end

