function conf = loadConfig( fname )
% LOADCONFIG loads configuration data froma script
% Evaluates the script passed as fname and returns the structure c defined
% by the script.
%
%   Examples:
%
%      conf = loadConfig( fname );
%
 global loadConfigFlag;
 
 loadConfigFlag=1; %#ok<NASGU>
 
 eval(fname);
 
 loadConfigFlag = 0;
 
 if(~exist('c','var'))
     error('bad syntax in the configuation file %s',fname);
 else 
    conf = c;
    clear c;
 end
end

