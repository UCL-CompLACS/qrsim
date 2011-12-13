function init(configFile)

    % init
    % housekeeping function to load the desired
    % configuration and to ensure that everything 
    % else is in the right place
        
    addpath('functions');
    addpath_recurse('classes');
    addpath_recurse('configs');
    
    global params;

    % load the required configuration
    eval(configFile);
    
    if params.display3d.on == 1
            state.display3d.figure = figure('Name','3D Window','NumberTitle','off','Position',[20,20,params.display3d.width,params.display3d.height]);
            state.display3d.area = AreaGraphics(params.environment.area);
    end    

end

