classdef QRSim<handle
    %QRSIM Summary of this class goes here
    %   Detailed explanation goes here
    
    properties (Access=public)
        par %config lfile
        paths =[];  %path
        task   % task
    end
    
    methods (Static,Access=private)
        function paths = toPathArray(p)
            ps = genpath(p);
            
            cps = textscan(ps,'%s','Delimiter',':');
            cps = cps{1};
            paths = [];
            
            for i=1:length(cps)
                cp = cps{i};
                if(isempty(strfind(cp,'.svn'))&&isempty(strfind(cp,'.git')))
                   paths = [paths,cp,':']; %#ok<AGROW>
                end
            end  
        end
    end
    
    methods (Access=public)
        function obj = QRSim()
            p = which('QRSim.m');
            
            idx = strfind(p,'/');
            
            obj.paths = toPathArray(p(1:idx(end)));
            
            addpath(obj.paths);
        end
        
        function delete(obj)
            rmpath(obj.paths);
        end
        
        function obj = init(obj,taskName)
            % INIT
            % Initializes the simulator state given a task.
            
            global state;           
            
            % load the required configuration
            obj.task = feval(taskName);
           
            obj.par = obj.task.init();
            
            % simulation time
            state.t = 0;
            
            % simulation timestep
            state.DT = obj.par.DT;
            
            % random number generator stream
            if(obj.par.seed~=0)
                state.rStream = RandStream('mt19937ar','Seed',obj.par.seed);
            else
                state.rStream = RandStream('mt19937ar','Seed',sum(100*clock));
            end
            
            %%% instantiates the objects that are part of the environment
            
            % 3D visualization
            if (obj.par.display3d.on == 1)
                state.display3d.figure = figure('Name','3D Window','NumberTitle','off','Position',...
                    [20,20,obj.par.display3d.width,obj.par.display3d.height]);
                state.environment.area = feval(obj.par.environment.area.type, obj.par.environment.area);
            end
            
            obj.createObjects();                  
        end
        
        function obj=reset(obj)
            %resets the simulator to the state specified in the configuration files
            global state; %#ok<NUSED>
            
            clear('state.environment.gpsspacesegment','state.environment.wind','state.platforms');
             
            obj.createObjects();
        end
  
        
        function obj=step(obj,U)
            %increments time and steps forward in sequence all the enviroment object and platforms.
            global state;
            
            % update time
            state.t=state.t+state.DT;
                        
            %%% step all the common objects
            
            % step the gps
            state.environment.gpsspacesegment.step([]);
            
            % step the wind
            state.environment.wind.step([]);
            
            
            % alterantively define a constant input
            % note that the one below is a trim state and will
            % not produce any motion of the platform
            %U=[00.2;0.01;0.59;0.2;10];
            
            % alternatively one could compute the helicopter
            % input given the current state and a target
            
            %%% step all the platforms
            
            for i=1:length(state.platforms)
                state.platforms(i).step(U(:,i));
            end
        end
    end
            
    methods (Sealed,Access=private)
        
        function obj=createObjects(obj)
            
            global state;
            
            % space segment of GPS
            state.environment.gpsspacesegment = feval(obj.par.environment.gpsspacesegment.type,...
                obj.par.environment.gpsspacesegment);
            
            % common part of Wind
            state.environment.wind = feval(obj.par.environment.wind.type, obj.par.environment.wind);          
            
            %%% instantiates the platform objects
            
            for i=1:length(obj.par.platforms)
                p = loadPlatformConfig(obj.par.platforms(i).configfile, obj.par);
                p.X = obj.par.platforms(i).X;
                state.platforms(i)=feval(p.type,p);
            end
            
        end  
    end
    
end
