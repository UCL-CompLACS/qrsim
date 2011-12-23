% MEXIFY compile mex functions present in the simulator project
%
% Example:
%   mexify()
%

curdir = pwd();

sources = {'ecef2lla','ecef2ned','lla2ecef','lla2utm','ned2ecef','polyval','utm2lla','pelicanODE'};

disp('Compiling the mex functions part of the simulator;');
disp('You might need to run mex -setup if this is the first time you use the mex compiler.');

for i=1:length(sources),
    
    fprintf('compiling %s\n',sources{i});
    p = which(sources{i});
    
    if(isempty(p))
        error('run init to initialize the path');
    end
    
    idx = strfind(p,filesep);
    cd(p(1:idx(end)));
    
    mex([sources{i},'.c']);
    
    %%% back to base
    cd(curdir);
    
end
