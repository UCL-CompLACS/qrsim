function [e]=testPolyVal()

% returns 0 if no errors

fprintf('during the test you might see warnings from the mex compiler,\n these are normal.\n');

% assumes to be running from the test directory


addpath(pwd());

cd(['..',filesep,'sim',filesep,'core',filesep,'functions']);

tol =  1e-20;

I = 100;
J = 50;

ym = zeros(I*J,1);
yc = zeros(I*J,1);

rStream = RandStream('mt19937ar','Seed',1234);

existspolyval = exist(['polyval.',mexext],'file');
if(existspolyval)
    delete(['polyval.',mexext]);
end

rehash();

for i=1:I,
    
    for j=1:J,
        p = rand(rStream,1,i);
        x = 100*randn(rStream,1,1);
        ym(i*J+j) = polyval(p,x,[],[0,100]);
    end
    
end

mex polyval.c
rehash();

rStream = RandStream('mt19937ar','Seed',1234);

for i=1:I,
    
    for j=1:J,
        p = rand(rStream,1,i);
        x = 100*randn(rStream,1,1);
        yc(i*J+j) = polyval(p,x,[],[0,100]);
    end
    
end

if(isWithinTolerance(ym,yc,tol))
    fprintf('polyval test [PASSED]\n');
    e = 0;
else
    fprintf('polyval test [FAILED]\n');
    e = 1;
end

if(~existspolyval)
    delete(['polyval.',mexext]);
end

cd(['..',filesep,'..',filesep,'..',filesep,'tests']);


end


function [f] = isWithinTolerance(a,b,tol)
% ISWITHINTOLERANCE Checks if the elements of two matrices are within tolerance
%
%  ISWITHINTOLERANCE(A,B,TOL)
%
t = (abs(a-b)<tol);

f = all(t);
end
