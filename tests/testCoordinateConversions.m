function [e] = testCoordinateConversions()

addpath('conversions');

% returns 0 if no errors

fprintf('this unit test will take a while...\n');
fprintf('during the test you might see warnings from the mex compiler,\n these are normal.\n');

% assumes to be running from the test directory

addpath(pwd());
cd(['..',filesep,'sim',filesep,'core',filesep,'functions']);

rehash();

e = 0;

tollla = [1e-11;1e-11;1e-7];
tolecef =[5e-7;5e-7;5e-7];
tolutm = [1e-4;1e-4;1e-15;1e-15;1e-15];
tolned = [5e-7;5e-7;5e-7];

%%% lla to ecef

% get rid of mex files
existslla2ecef = exist(['lla2ecef.',mexext],'file');
existsecef2lla = exist(['ecef2lla.',mexext],'file');
if(existslla2ecef)
    delete(['lla2ecef.',mexext]);
end

if(existsecef2lla)
    delete(['ecef2lla.',mexext]);
end

clear('lla2ecef');
clear('ecef2lla');
rehash();

% testing lla to ecef MATLAB against known data
wt = 1;

f = fopen(['..',filesep,'..',filesep,'..',filesep,'tests',filesep,'conversions',filesep,'ECEFTESTcoords.csv'],'r');
d = fscanf(f,'%f,%f,%f,%f,%f\n',[5,inf]);
fclose(f);

for i=1:size(d,1),
    
    inlla = [d(1:2,i);0];
    outecef = lla2ecef(inlla);
    testecef = d(3:5,i);
    
    wt = wt &&  isWithinTolerance(outecef,testecef,tolecef);
end
e = e || ~wt;

fprintf('\ntest of MATLAB lla2ecef against test data [%s]\n',wtToFailPass(wt));

% testing lla to ecef MATLAB conversions
wt = 1;

for lat = -78:8:78, %chosen to fall in the middle of a zone
    for lon = -177:6:177, %chosen to fall in the middle of a zone
        for h = 0:10:100,
            inlla = [lat;lon;h];
            
            outlla = ecef2lla(lla2ecef(inlla));
            
            wt = wt && isWithinTolerance(inlla,outlla,tollla);
        end
    end
    fprintf('.');
end

e = e || ~wt;

fprintf('\ntest of MATLAB lla2ecef and ecef2lla [%s]\n',wtToFailPass(wt));

% compile and cross test ecef2lla
clear('lla2ecef');
clear('ecef2lla');

mex ecef2lla.c

rehash();

wt = 1;

for lat = -78:8:78, %chosen to fall in the middle of a zone
    for lon = -177:6:177, %chosen to fall in the middle of a zone
        for h = 0:10:100,
            inlla = [lat;lon;h];
            
            outlla = ecef2lla(lla2ecef(inlla));
            
            wt = wt && isWithinTolerance(inlla,outlla,tollla);
        end
    end
    fprintf('.');
end

e = e || ~wt;

fprintf('\ntest of MEX ecef2lla [%s]\n',wtToFailPass(wt));


% compile and cross test lla2ecef
clear('lla2ecef');
clear('ecef2lla');

delete(['ecef2lla.',mexext]);
mex lla2ecef.c

rehash();

wt = 1;

for lat = -78:8:78, %chosen to fall in the middle of a zone
    for lon = -177:6:177, %chosen to fall in the middle of a zone
        for h = 0:10:100,
            inlla = [lat;lon;h];
            
            outlla = ecef2lla(lla2ecef(inlla));
            
            wt = wt && isWithinTolerance(inlla,outlla,tollla);
        end
    end
    fprintf('.');
end

e = e || ~wt;

fprintf('\ntest of MEX lla2ecef [%s]\n',wtToFailPass(wt));

% put back things as they were
if(existsecef2lla)
    mex ecef2lla.c
end

if(~existslla2ecef)
    delete([ 'lla2ecef.',mexext]);
end

clear('lla2ecef');
clear('ecef2lla');

%%% lla to utm

% get rid of mex
existsllaToUtm = exist(['lla2utm.',mexext],'file');
existsutmToLla = exist(['utm2lla.',mexext],'file');
if(existsllaToUtm)
    delete(['llaToUtm.',mexext]);
end

if(existsutmToLla)
    delete(['utmToLla.',mexext]);
end

clear('llaToUtm');
clear('utmToLla');
rehash();

% testing lla to utm MATLAB  gainst known data
wt = 1;

f = fopen(['..',filesep,'..',filesep,'..',filesep,'tests',filesep,'conversions',filesep,'UTMTESTcoords.csv'],'r');
d = fscanf(f,'%f,%f,%f,%f,%s\n',[7,inf]);
fclose(f);

for i=1:size(d,1),
    
    inlla = [d(1:2,i);0];
    [E,N,utmzone,~] = llaToUtm(inlla);
    oututm = [E;N;double(utmzone(1));double(utmzone(2));double(utmzone(3))];
    testutm = d(3:7,i);
    
    wt = wt &&  isWithinTolerance(oututm,testutm,tolutm);
end
e = e || ~wt;

fprintf('\ntest of MATLAB llaToUtm against test data [%s]\n',wtToFailPass(wt));

% testing lla to utm MATLAB  conversions
wt = 1;

for lat = -86:8:86, %chosen to fall in the middle of a zone
    for lon = -177:6:177, %chosen to fall in the middle of a zone
        for h = 0:10:100,
            inlla = [lat;lon;h];
            [E,N,utmzone,H] = llaToUtm(inlla);
            outlla = utmToLla(E,N,utmzone,H);
            
            wt = wt &&  isWithinTolerance(inlla,outlla,tollla);
        end
    end
    fprintf('.');
end

e = e || ~wt;

fprintf('\ntest of MATLAB llaToUtm and utmToLla [%s]\n',wtToFailPass(wt));

% compile and cross test llaToUtm
clear('llaToUtm');
clear('utmToLla');
mex llaToUtm.c

rehash();

wt = 1;

for lat = -78:8:78, %chosen to fall in the middle of a zone
    for lon = -177:6:177, %chosen to fall in the middle of a zone
        for h = 0:10:100,
            inlla = [lat;lon;h];
            [E,N,utmzone,H] = llaToUtm(inlla);
            outlla = utmToLla(E,N,utmzone,H);
            
            wt = wt &&  isWithinTolerance(inlla,outlla,tollla);
        end
    end
    fprintf('.');
end

e = e || ~wt;

fprintf('\ntest of MEX llaToUtm [%s]\n',wtToFailPass(wt));

% compile and cross test utmToLla
clear('llaToUtm');
clear('utmToLla');
delete(['llaToUtm.',mexext]);
mex utmToLla.c

rehash();

wt = 1;

for lat = -78:8:78, %chosen to fall in the middle of a zone
    for lon = -177:6:177, %chosen to fall in the middle of a zone
        for h = 0:10:100,
            inlla = [lat;lon;h];
            [E,N,utmzone,H] = llaToUtm(inlla);
            outlla = utmToLla(E,N,utmzone,H);
            
            wt = wt &&  isWithinTolerance(inlla,outlla,tollla);
        end
    end
    fprintf('.');
end

e = e || ~wt;

fprintf('\ntest of MEX utmToLla [%s]\n',wtToFailPass(wt));

% put back things as they were
if(~existsutmToLla)
    delete(['utmToLla.',mexext]);
end
if(existsllaToUtm)
    mex 'llaToUtm.c'
end

clear('llaToUtm');
clear('utmToLla');


%%% ned to ecef


% get rid of mex
existsned2ecef = exist(['ned2ecef.',mexext],'file');
existsecef2ned = exist(['ecef2ned.',mexext],'file');
if(existsned2ecef)
    delete(['ned2ecef.',mexext]);
end

if(existsecef2ned)
    delete(['ecef2ned.',mexext]);
end
clear('ned2ecef');
clear('ecef2ned');
rehash();

% testing lla to utm MATLAB  conversions
wt = 1;

for lat = 180*(rand(1,3)-0.5), %we pick a few random locations
    for lon = 360*(rand(1,3)-0.5),
        for h = 0:10:100,
            
            [E,N,zone,H] = llaToUtm([lat;lon;h]);
            utmorigin.E = E;
            utmorigin.N = N;
            utmorigin.zone = zone;
            utmorigin.h = H;
            
            for x = -100:10:100
                for y = -100:10:100
                    
                    inned = [x;y;h];
                    outned = ecef2ned(ned2ecef(inned,utmorigin),utmorigin);
                    
                    wt = wt &&  isWithinTolerance(inned,outned,tolned);
                end
            end
        end
        fprintf('.');
    end
end

e = e || ~wt;

fprintf('\ntest of MATLAB ned2ecef and ecef2ned [%s]\n',wtToFailPass(wt));

% compile and cross test ned2ecef
clear('ned2ecef');
clear('ecef2ned');
mex ned2ecef.c

rehash();

wt = 1;

for lat = 180*(rand(1,3)-0.5), %we pick a few random locations
    for lon = 360*(rand(1,3)-0.5),
        for h = 0:10:100,
            
            [E,N,zone,H] = llaToUtm([lat;lon;h]);
            utmorigin.E = E;
            utmorigin.N = N;
            utmorigin.zone = zone;
            utmorigin.h = H;
            
            for x = -100:10:100
                for y = -100:10:100
                    
                    inned = [x;y;h];
                    outned = ecef2ned(ned2ecef(inned,utmorigin),utmorigin);
                    
                    wt = wt &&  isWithinTolerance(inned,outned,tolned);
                end
            end
        end
        fprintf('.');
    end
end

e = e || ~wt;

fprintf('\ntest of MEX ned2ecef [%s]\n',wtToFailPass(wt));

% compile and cross test ecef2ned
clear('ned2ecef');
clear('ecef2ned');
delete(['ned2ecef.',mexext]);

rehash();

mex ecef2ned.c

wt = 1;

for lat = 180*(rand(1,3)-0.5), %we pick a few random locations
    for lon = 360*(rand(1,3)-0.5),
        for h = 0:10:100,
            
            [E,N,zone,H] = llaToUtm([lat;lon;h]);
            utmorigin.E = E;
            utmorigin.N = N;
            
            utmorigin.zone = zone;
            utmorigin.h = H;
            
            for x = -100:10:100
                for y = -100:10:100
                    inned = [x;y;h];
                    outned = ecef2ned(ned2ecef(inned,utmorigin),utmorigin);
                    
                    wt = wt &&  isWithinTolerance(inned,outned,tolned);
                end
            end
        end
        fprintf('.');
    end
end
fprintf('\n');
e = e || ~wt;

fprintf('test of MEX ecef2ned [%s]\n',wtToFailPass(wt));

if(~existsecef2ned)
    delete(['ecef2ned.',mexext]);
end

if(existsned2ecef)
    mex ecef2ned.c
end

clear('ned2ecef');
clear('ecef2ned');

cd(['..',filesep,'..',filesep,'..',filesep,'tests']);

%rmpath('conversions');

end

function [s]=wtToFailPass(f)

if(f)
    s='PASSED';
else
    s='FAILED';
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
