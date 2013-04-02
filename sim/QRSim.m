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
    %   init(taskName)      - initialises the simulator given a task
    %   reset()             - resets the simulator to the state specified in the task
    %   delete()            - destructor
    %   step(obj,U)         - increments time and steps forward in sequence all the enviroment
    %                         objects and platforms.
    %   resetSeed(varargin) - re-initialize the random number generator seed
    %
    
    properties (Constant)
        DT = 0.02; %simulator timestep
    end
    
    properties (Access=private)
        par           % task parameters
        paths =[];    % paths
        simState;     % handle to the state structure
        bootstrapped; % true if the object is boostrapped and valid
    end
    
    methods (Sealed,Access=public)
        function obj = QRSim()
            % Constructs object and sets up the paths
            %
            % Example:
            %  obj = QRSim();
            %       obj - new qrsim object
            %
            p = which('QRSim.m');
            
            idx = strfind(p,filesep);
            
            obj.paths = [obj.toPathArray(p(1:idx(end))),obj.toPathArray([p(1:idx(end)-4),'3rdparty'])];
            
            addpath(obj.paths);
            
            obj.simState = State();
        end
        
        function state = init(obj,taskName)
            % Initializes the simulator given a task.
            %
            % Example:
            %    obj.init('task_name');
            %       task_name - class name of the task
            %
            
            % simulation timestep
            obj.simState.DT = obj.DT;
            
            % counter for the number of independent random stream needed
            obj.simState.numRStreams = 0;
            
            % load the required configuration
            obj.simState.task = feval(taskName,obj.simState);
            
            obj.par = obj.simState.task.init();
            
            % simulation timestep
            assert(isfield(obj.par,'dt'),'qrsim:nodt','the task must define a dt');
            assert((rem(obj.par.dt,obj.DT)==0),'qrsim:nomultipledt','the task dt must be a multiple of the simulator DT (0.02s)');
            obj.simState.task.dt = obj.par.dt;
            
            % random number generator stream
            assert(isfield(obj.par,'seed'),'qrsim:noseed','the task must define a seed');
            
            %%% instantiates the objects that are part of the environment
            
            % 3D visualization
            assert(isfield(obj.par,'display3d')&&isfield(obj.par.display3d,'on'),'qrsim:nodisplay3d','the task must define display3d.on');
            obj.simState.display3dOn = obj.par.display3d.on;
            if (obj.par.display3d.on == 1)
                assert((isfield(obj.par.display3d,'width')&&isfield(obj.par.display3d,'height')),...
                    'qrsim:nodisplay3dwidthorheight',['If the 3D display is on, the task must define width and height '...
                    'parameters of the rendering window']);
                
                obj.simState.display3d.figure = figure('Name','3D Window','NumberTitle','off','Position',...
                    [20,20,obj.par.display3d.width,obj.par.display3d.height]);
                set(obj.simState.display3d.figure,'DoubleBuffer','on');
                set(obj.simState.display3d.figure, 'Renderer', 'OpenGL');
            end
            
            obj.createObjects();
            
            obj.resetSeed();
            obj.reset();
            
            % we return a handle to the state this should avoid copies
            state = obj.simState;
        end
        
        function obj=reset(obj)
            % resets the simulator to the state specified in the task, any random parameter is reinitialised
            %
            % Note: this function does not reinitialize the prngs seeds, if
            % this is required, you must call obj.resetSeed() BEFORE this function
            %
            % Example:
            %    obj.reset();
            %
            
            % simulation time
            obj.simState.t = 0;
            
            % reset all environment objects
            envObjs = fieldnames(obj.simState.environment);
            for i = 1:numel(envObjs)
                obj.simState.environment.(envObjs{i}).reset();
            end
            
            % reset task
            % note that this will also reset all the platforms states to their initial value
            obj.simState.task.reset();
            
            % reset all platforms
            %for i=1:length(obj.simState.platforms)
            %    obj.simState.platforms{i}.reset();
            %end
            
            % reset reward
            obj.simState.task.resetReward();
            
            obj.bootstrapped = 1;
        end
        
        function obj = resetSeed(obj,varargin)
            % re-initialize the random number generator seed
            %
            % Note: this does not call reset, often you want to call this
            % function BEFORE a reset
            %
            % Examples:
            %   obj.resetSeed()  - reset to the fixed or random seed specified by the task
            %
            %   obj.resetSeed(s) - reset to the seed s passed as argument
            %
            
            % note:
            % mrg32k3a has a period of 2^127 which shorter than the period of mt19937ar
            % however it guarantees independence between streams, so we prefer it
            %
            if(size(varargin)==1)
                obj.simState.rStreams = RandStream.create('mrg32k3a','seed',varargin{1},'NumStreams',obj.simState.numRStreams,'CellOutput',1);
            else
                if(obj.par.seed~=0)
                    obj.simState.rStreams = RandStream.create('mrg32k3a','seed',obj.par.seed,'NumStreams',obj.simState.numRStreams,'CellOutput',1);
                else
                    obj.simState.rStreams = RandStream.create('mrg32k3a','seed',sum(100*clock),'NumStreams',obj.simState.numRStreams,'CellOutput',1);
                end
            end
            
            obj.bootstrapped = 0;
        end
        
        function obj=step(obj,U)
            %increments time and steps forward in sequence all the enviroment object and platforms.
            %
            % Example:
            %  obj.step(U);
            %     U - 5 by m matrix of control inputs for each of the m platforms
            %
            
            assert((obj.bootstrapped==1),'qrsim:ntbootsrapped','after resetting the simulation seed, qrsim.reset() must be called to reinitilize all the simulation objects');
            
            for j=1:obj.simState.task.dt/obj.DT,
                % update time
                obj.simState.t=obj.simState.t+obj.simState.DT;
                
                % step all the environment objects
                envObjs = fieldnames(obj.simState.environment);
                for i = 1:numel(envObjs)
                    obj.simState.environment.(envObjs{i}).step([]);
                end
                
                % see if the task is the one generating the controls
                UfromTask = obj.simState.task.step(U);
                if(~isempty(UfromTask))
                    UU = UfromTask;
                else
                    UU = U;
                end
                
                % step all the platforms given UU
                assert(size(obj.simState.platforms,2)==size(UU,2),'qrsim:wronginputsize',...
                    'the number of colum of the control input matrix has to be equal to the number of platforms');
                
                for i=1:length(obj.simState.platforms)
                    obj.simState.platforms{i}.step(UU(:,i));
                end
            end
            
            % update the task reward
            obj.simState.task.updateReward(U);
            
            % force figure refresh
            if(obj.par.display3d.on == 1)
                refresh(obj.simState.display3d.figure);
            end
            
        end
        
        function r = reward(obj)
            % returns the task reward
            r = obj.simState.task.reward();
        end
    end
    
    methods (Access=public)
        function delete(obj)
            % destructor, cleans the path
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
    end
    
    methods (Sealed,Access=private)
        
        function obj=createObjects(obj)
            % create environment and platform objects from the saved parameters
            
            %%%% NOTE:
            %%%% the order in which the objects are created (i.e. added to
            %%%% the environment structure), is also the order in which
            %%%% they will be reset and updated.
            
            % space segment of GPS
            assert(isfield(obj.par.environment,'gpsspacesegment')&&isfield(obj.par.environment.gpsspacesegment,'on'),...
                'qrsim:nogpsspacesegment',['the task must define environment.gpsspacesegment.on\n',...
                'this can be environment.gpsspacesegment.on=0; if no GPS is needed']);
            obj.par.environment.gpsspacesegment.DT = obj.DT;
            obj.par.environment.gpsspacesegment.state = obj.simState;
            if(obj.par.environment.gpsspacesegment.on)
                assert(isfield(obj.par.environment.gpsspacesegment,'type'),...
                    'qrsim:nogpsspacesegmenttype','the task must define environment.gpsspacesegment.type');
                obj.simState.environment.gpsspacesegment = feval(obj.par.environment.gpsspacesegment.type,...
                    obj.par.environment.gpsspacesegment);
            else
                obj.simState.environment.gpsspacesegment = feval('GPSSpaceSegment',...
                    obj.par.environment.gpsspacesegment);
            end
            
            % common part of Wind
            assert(isfield(obj.par.environment,'wind')&&isfield(obj.par.environment.wind,'on'),'qrsim:nowind',...
                'the task must define environment.wind this can be environment.wind.on=0; if no wind is needed');
            obj.par.environment.wind.DT = obj.DT;
            obj.par.environment.wind.state = obj.simState;
            if(obj.par.environment.wind.on)
                assert(isfield(obj.par.environment.wind,'type'),...
                    'qrsim:nowindtype','the task must define environment.wind.type');
                
                assert(isfield(obj.par.environment.area,'limits'),...
                    'qrsim:noarealimits','the task must define environment.area.limits');
                
                obj.par.environment.wind.zOrigin = obj.par.environment.area.limits(6);
                
                obj.simState.environment.wind =feval(obj.par.environment.wind.type, obj.par.environment.wind);
            else
                obj.simState.environment.wind = feval('Wind', obj.par.environment.wind);
            end
            
            % flying area
            assert(isfield(obj.par,'environment')&&isfield(obj.par.environment,'area')&&isfield(obj.par.environment.area,'type'),'qrsim:noareatype','A task must always define an enviroment.area.type ');
            obj.par.environment.area.graphics.on = obj.par.display3d.on;
            obj.par.environment.area.DT = obj.DT;
            obj.par.environment.area.state = obj.simState;
            obj.simState.environment.area = feval(obj.par.environment.area.type, obj.par.environment.area);
            
            
            %%% instantiates the platform objects
            assert(isfield(obj.par,'platforms')&&(~isempty(obj.par.platforms)),'qrsim:noplatforms','the task must define at least one platform');
            for i=1:length(obj.par.platforms)
                assert(isfield(obj.par.platforms(i),'configfile'),'qrsim:noplatforms','the task must define a configfile for each platform');
                p = loadPlatformConfig(obj.par.platforms(i).configfile, obj.par);
                p.DT = obj.DT;
                
                assert(~isfield(obj.par.platforms(i),'X'),'qrsim:platformsx',['platforms(i).X is not used any longher to define the initial platform state,',...
                    'for that purpouse call platforms{i}.setX within the reset() method of your task']);
                
                p.graphics.on = obj.par.display3d.on;
                p.state = obj.simState;
                assert(isfield(p,'aerodynamicturbulence')&&isfield(p.aerodynamicturbulence,'on'),'qrsim:noaerodynamicturbulence',...
                    'the platform config file must define an aerodynamicturbulence if not needed set aerodynamicturbulence.on = 0');
                
                assert(isfield(p,'type'),'qrsim:noplatformtype','the platform config file must define a platform type');
                obj.simState.platforms{i}=feval(p.type,p);
            end
            
        end
    end
    
    methods (Static,Access=private)
        function paths = toPathArray(p)
            % builds a list of subpaths path recursively removing versioning subdirs
            ps = genpath(p);
            
            cps = textscan(ps,'%s','Delimiter',pathsep);
            cps = cps{1};
            paths = [];
            
            for i=1:length(cps)
                cp = cps{i};
                if(isempty(strfind(cp,'.svn'))&&isempty(strfind(cp,'.git')))
                    paths = [paths,cp,pathsep]; %#ok<AGROW>
                end
            end
        end
    end
    
end
