classdef QRSim<handle
    % main simulator class
    % This class gives access to all aspects of the simulator
    %
    % QRSim properties:
    %   par    - parameters from task
    %   paths  - paths
    %   task   - task
    %
    % QRSim methods:
    %   init(taskName)  - initialises the simulator given a task
    %   reset()         - resets the simulator to the state specified in the task
    %   delete()        - destructor
    %   step(obj,U)     - increments time and steps forward in sequence all the enviroment
    %                     objects and platforms.
    %
            
    properties (Access=public)
        par % parameters from task
        paths =[];  %paths
        task   % task
    end
    
    methods (Access=public)
        function obj = QRSim()
            % constructs object and sets up the paths
            %
            % Example:
            %  obj = QRSim();
            %       obj - new qrsim object
            %
            p = which('QRSim.m');
            
            idx = strfind(p,'/');
            
            obj.paths = obj.toPathArray(p(1:idx(end)));
            
            addpath(obj.paths);
        end
        
        function delete(obj)
            % destructor, cleanes the path
            % this is called automatically by Matlab when using clear on a QRSim object.
            %
            % Example:
            %   qrsim = QRSim();
            %   clear qrsim;
            %
            if(strfind(path,obj.paths))
                rmpath(obj.paths);
            end
        end
        
        function obj = init(obj,taskName)
            % Initializes the simulator state given a task.
            %
            % Example:
            %    obj.init('task_name');
            %       task_name - class name of the task
            %
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
                set(state.display3d.figure,'DoubleBuffer','on');
                state.environment.area = feval(obj.par.environment.area.type, obj.par.environment.area);
            end
            
            obj.createObjects();                  
        end
        
        function obj=reset(obj)
            %resets the simulator to the state specified in the task
            %
            % Example:
            %    obj.reset(); 
            %
            global state; %#ok<NUSED>
            
            clear('state.environment.gpsspacesegment','state.environment.wind','state.platforms');
             
            obj.createObjects();
        end
  
        
        function obj=step(obj,U)
            %increments time and steps forward in sequence all the enviroment object and platforms.
            %
            % Example:
            %  obj.step(U);
            %     U - 5 by m matrix of control inputs for each of the m platforms 
            %
            global state;
                        
            %%% step all the common objects
            
            % step the gps
            state.environment.gpsspacesegment.step([]);
            
            % step the wind
            state.environment.wind.step([]);
            
            %%% step all the platforms given U
            
            for i=1:length(state.platforms)
                state.platforms(i).step(U(:,i));
            end
            
            % force figure refresh
            if(obj.par.display3d.on == 1)
                refresh(state.display3d.figure);
            end
                                    
            % update time
            state.t=state.t+state.DT;
        end
    end
            
    methods (Sealed,Access=private)
        
        function obj=createObjects(obj)
            % create environment and platform objects from the saved parameters

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
        
    methods (Static,Access=private)
        function paths = toPathArray(p)
            % build a list of subpaths path recursively removing versioning subdirs
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
    
end
