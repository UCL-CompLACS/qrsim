function mexify(varargin)
% MEXIFY compile/clean mex functions present in the simulator project
%
% Examples:
%   mexify('compile') - to compile mex sources
%   mexify('clean')   - to remove compiled mex
%

curdir = pwd();

if(isempty(varargin))
    fprintf('option parameter missing\n');
    fprintf('  Usage:\n\tmexify(''compile'')   - to compile mex sources\n');
    fprintf('\tmexify(''clean'')   - to remove compiled mex\n');
    return;
elseif (~strcmp(varargin{1},'compile')&&~strcmp(varargin{1},'clean'))
    fprintf('option not defined\n');
    fprintf('  Usage:\n\tmexify(''compile'')   - to compile mex sources\n');
    fprintf('\tmexify(''clean'')   - to remove compiled mex\n');
    return;
end


sources = {'ecefToLla','ecefToNed','llaToEcef','llaToUtm','nedToEcef','polyval','utmToLla','dcm','pelicanODE'};

disp('Handling the mex functions part of the simulator;');
disp('You might need to run mex -setup if this is the first time you use the mex compiler.');

for i=1:length(sources),
    
    p = which(sources{i});
    
    if(isempty(p))
        error('qrsim needs to be in the path to compile the mex sources');
    end
    
    idx = strfind(p,filesep);
    cd(p(1:idx(end)));
    
    if (strcmp(varargin{1},'compile'))
        fprintf('compiling %s\n',sources{i});
        mex([sources{i},'.c']);
    else
        if(exist([sources{i},'.',mexext],'file'))
            delete([sources{i},'.',mexext]);
            fprintf('removing %s.%s\n',sources{i},mexext);
        end
    end
    %%% back to base
    cd(curdir);
end
fprintf('Done!\n\n');
