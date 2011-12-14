% MEXIFY compile mex functions present in the simulator project
% Note: this script must be run from the root folder of the simulator'
%
% Example:
%   mexify()
%

curdir = pwd();

sources = {'ecef2lla','ecef2ned','lla2ecef','lla2utm','ned2ecef','polyval','utm2lla','pelicanODE'};

for i=1:length(sources),

p = which(sources{i});
idx = strfind(p,filesep);
cd(p(1:idx(end)))

mex([sources{i},'.c']);

end

%%% back to base
cd(curdir);
