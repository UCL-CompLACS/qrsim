classdef TaskNoGPSSpacesegmenttStartB<Task
    % Task used to test assertions on DT
    %
    methods (Sealed,Access=public)
                
        function obj = TaskNoGPSSpacesegmenttStartB(state)
            obj = obj@Task(state);
        end

        function updateReward(obj,U)
            % reward not defined
        end
        
        function taskparams=init(obj)
            % loads and returns all the parameters for the various simulator objects
            
            taskparams.dt = 0.02; % task timestep i.e. rate at which controls
                               % are supplied and measurements are received
            
            taskparams.seed = 0; %set to zero to have a seed that depends on the system time
            
            %%%%% visualization %%%%%
            % 3D display parameters
            taskparams.display3d.on = 0;
            taskparams.display3d.width = 1000;
            taskparams.display3d.height = 600;            
            
            %%%%% environment %%%%%
            % these need to follow the conventions of axis(), they are in m, Z down
            % note that the lowest Z limit is the refence for the computation of wind shear and turbulence effects
            taskparams.environment.area.limits = [-10 20 -7 7 -20 0];
            taskparams.environment.area.type = 'BoxArea';
            
            % originutmcoords is the location of the RVC (our usual flying site)
            % generally when this is changed gpsspacesegment.orbitfile and 
            % gpsspacesegment.svs need to be changed
            [E N zone h] = llaToUtm([51.71190;-0.21052;0]);
            taskparams.environment.area.originutmcoords.E = E;
            taskparams.environment.area.originutmcoords.N = N;
            taskparams.environment.area.originutmcoords.h = h;
            taskparams.environment.area.originutmcoords.zone = zone;

            taskparams.environment.area.graphics.type = 'AreaGraphics';
            
            % GPS
            % The space segment of the gps system
            taskparams.environment.gpsspacesegment.on = 1; % if off the gps returns the noiseless position
            taskparams.environment.gpsspacesegment.dt = 0.2;
            
            taskparams.environment.gpsspacesegment.type = 'GPSSpaceSegmentGM';  
            
            % real satellite orbits from NASA JPL
            taskparams.environment.gpsspacesegment.orbitfile = 'ngs15992_16to17.sp3';          
            % id number of visible satellites, the one below are from a typical flight day at RVC
            % these need to match the contents of gpsspacesegment.orbitfile
            taskparams.environment.gpsspacesegment.svs = [3,5,6,7,13,16,18,19,20,22,24,29,31];
            % the following model is from [2]
            taskparams.environment.gpsspacesegment.PR_BETA = 2000;     % process time constant
            taskparams.environment.gpsspacesegment.PR_SIGMA = 0.1746;  % process standard deviation
                        
        end
        
        function reset(obj) 
            % initial state
        end 

        function r=reward(obj) 
            % nothing this is just a test task
        end
    end
    
end
