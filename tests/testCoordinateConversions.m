function [e] = testCoordinateConversions()

fprintf('this unit test will take a while...\n');
fprintf('during the test you might see warnings from the mex compiler,\n these are normal.\n');

% assumes to be running from the test directory

cd('../qrsim/core/functions');

e = 0;

tollla = [1e-11;1e-11;1e-8];

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

% testing lla to ecef MATLAB conversions
wt = 0;

for lat = -86:8:86, %chosen to fall in the middle of a zone
    for lon = -177:6:177, %chosen to fall in the middle of a zone
        for h = 0:10:100,
            inlla = [lat;lon;h];
            
            outlla = ecef2lla(lla2ecef(inlla));
            
            wt = wt + isWithinTolerance(inlla,outlla,tollla);
        end
    end
    fprintf('.');
end

if(wt==0)
    wts='FAILED';
else
    wts='PASSED';
end

e = e && wt;

fprintf('\ntest of MATLAB lla2ecef and ecef2lla [%s]\n',wts);

% compile and cross test ecef2lla
mex ecef2lla.c

wt = 0;

for lat = -86:8:86, %chosen to fall in the middle of a zone
    for lon = -177:6:177, %chosen to fall in the middle of a zone
        for h = 0:10:100,
            inlla = [lat;lon;h];
            
            outlla = ecef2lla(lla2ecef(inlla));
            
            wt = wt + isWithinTolerance(inlla,outlla,tollla);
        end
    end
    fprintf('.');
end

if(wt==0)
    wts='FAILED';
else
    wts='PASSED';
end

e = e && wt;

fprintf('\ntest of MEX ecef2lla [%s]\n',wts);


% compile and cross test lla2ecef
delete(['ecef2lla.',mexext]);
mex lla2ecef.c

wt = 0;

for lat = -86:8:86, %chosen to fall in the middle of a zone
    for lon = -177:6:177, %chosen to fall in the middle of a zone
        for h = 0:10:100,
            inlla = [lat;lon;h];
            
            outlla = ecef2lla(lla2ecef(inlla));
            
            wt = wt + isWithinTolerance(inlla,outlla,tollla);
        end
    end
    fprintf('.');
end

if(wt==0)
    wts='FAILED';
else
    wts='PASSED';
end

e = e && wt;

fprintf('\ntest of MEX lla2ecef [%s]\n',wts);

% put back things as they were
if(existsecef2lla)
    mex ecef2lla.c
end

if(~existslla2ecef)
    delete([ 'lla2ecef.',mexext]);
end


%%% lla to utm

% get rid of mex
existslla2utm = exist(['lla2utm.',mexext],'file');
existsutm2lla = exist(['utm2lla.',mexext],'file');
if(existslla2utm)
    delete(['lla2utm.',mexext]);
end

if(existsutm2lla)
    delete(['utm2lla.',mexext]);
end

% testing lla to utm MATLAB  conversions
wt = 0;

for lat = -86:8:86, %chosen to fall in the middle of a zone
    for lon = -177:6:177, %chosen to fall in the middle of a zone
        for h = 0:10:100,
            inlla = [lat;lon;h];
            [E,N,utmzone,H] = lla2utm(inlla);
            outlla = utm2lla(E,N,utmzone,H);
            
            wt = wt + isWithinTolerance(inlla,outlla,tollla);
        end
    end
    fprintf('.');
end

if(wt==0)
    wts='FAILED';
else
    wts='PASSED';
end

e = e && wt;

fprintf('\ntest of MATLAB lla2utm and utm2lla [%s]\n',wts);

% compile and cross test lla2utm
mex lla2utm.c

wt = 0;

for lat = -86:8:86, %chosen to fall in the middle of a zone
    for lon = -177:6:177, %chosen to fall in the middle of a zone
        for h = 0:10:100,
            inlla = [lat;lon;h];
            [E,N,utmzone,H] = lla2utm(inlla);
            outlla = utm2lla(E,N,utmzone,H);
            
            wt = wt + isWithinTolerance(inlla,outlla,tollla);
        end
    end
    fprintf('.');
end

if(wt==0)
    wts='FAILED';
else
    wts='PASSED';
end

e = e && wt;

fprintf('\ntest of MEX lla2utm [%s]\n',wts);

% compile and cross test utm2lla
delete(['lla2utm.',mexext]);
mex utm2lla.c

wt = 0;

for lat = -86:8:86, %chosen to fall in the middle of a zone
    for lon = -177:6:177, %chosen to fall in the middle of a zone
        for h = 0:10:100,
            inlla = [lat;lon;h];
            [E,N,utmzone,H] = lla2utm(inlla);
            outlla = utm2lla(E,N,utmzone,H);
            
            wt = wt + isWithinTolerance(inlla,outlla,tollla);
        end
    end
    fprintf('.');
end

if(wt==0)
    wts='FAILED';
else
    wts='PASSED';
end

e = e && wt;

fprintf('\ntest of MEX lla2utm [%s]\n',wts);

% put back things as they were
if(~existsutm2lla)
    delete(['utm2lla.',mexext]);
end
if(existslla2utm)
    mex 'lla2utm.c'
end


tolned = [1e-8;1e-8;1e-8];

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

% testing lla to utm MATLAB  conversions

wt = 0;

for lat = -86:8:86, %chosen to fall in the middle of a zone
    for lon = -177:6:177, %chosen to fall in the middle of a zone
        for h = 0:10:100,
            
            [E,N,zone,H] = lla2utm([lat;lon;h]);
            utmorigin.E = E;
            utmorigin.N = N;
            utmorigin.zone = zone;
            utmorigin.h = H;
            
            for x = -100:10:100
                for y = -100:10:100
                    
                    inned = [x;y;h];
                    outned = ecef2ned(ned2ecef(inned,utmorigin),utmorigin);
                    
                    wt = wt + isWithinTolerance(inned,outned,tolned);
                end
            end
            if(wt>0)
                break;
            end
        end
        if(wt>0)
            break;
        end
    end
    fprintf('.');
    if(wt>0)
        break;
    end
end

if(wt==0)
    wts='FAILED';
else
    wts='PASSED';
end

e = e && wt;

fprintf('\ntest of MATLAB ned2ecef and ecef2ned [%s]\n',wts);


% compile and cross test ned2ecef
mex ned2ecef.c

wt = 0;

for lat = -86:8:86, %chosen to fall in the middle of a zone
    for lon = -177:6:177, %chosen to fall in the middle of a zone
        for h = 0:10:100,
            
            [E,N,zone,H] = lla2utm([lat;lon;h]);
            utmorigin.E = E;
            utmorigin.N = N;
            utmorigin.zone = zone;
            utmorigin.h = H;
            
            for x = -100:10:100
                for y = -100:10:100
                    
                    inned = [x;y;h];
                    outned = ecef2ned(ned2ecef(inned,utmorigin),utmorigin);
                    
                    wt = wt + isWithinTolerance(inned,outned,tolned);
                end
            end
            if(wt>0)
                break;
            end
        end
        if(wt>0)
            break;
        end
    end
    fprintf('.');
    if(wt>0)
        break;
    end
end

if(wt==0)
    wts='FAILED';
else
    wts='PASSED';
end

e = e && wt;

fprintf('\ntest of MEX ned2ecef [%s]\n',wts);


% compile and cross test ecef2ned
delete(['ned2ecef.',mexext]);

mex ecef2ned.c

wt = 0;

for lat = -86:8:86, %chosen to fall in the middle of a zone
    for lon = -177:6:177, %chosen to fall in the middle of a zone
        for h = 0:10:100,
            
            [E,N,zone,H] = lla2utm([lat;lon;h]);
            utmorigin.E = E;
            utmorigin.N = N;
            
            utmorigin.zone = zone;
            utmorigin.h = H;
            
            for x = -100:10:100
                for y = -100:10:100
                    inned = [x;y;h];
                    outned = ecef2ned(ned2ecef(inned,utmorigin),utmorigin);
                    
                    wt = wt + isWithinTolerance(inned,outned,tolned);
                end
            end
            if(wt>0)
                break;
            end
        end
        if(wt>0)
            break;
        end
    end
    disp('.');
    if(wt>0)
        break;
    end
end

if(wt==0)
    wts='FAILED';
else
    wts='PASSED';
end

e = e && wt;

fprintf('test of MEX ecef2ned [%s]\n',wts);

if(~existsecef2ned)
    delete(['ecef2ned.',mexext]);
end

if(existsned2ecef)
    mex ecef2ned.c
end

cd('../../../tests');
