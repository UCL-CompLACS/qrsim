classdef BoxWithPersonsArea<Area
    % Defines a simple box shaped area in which the ground is split in
    % areas of different classes and there are persons present at randomly
    % generated locations.
    %
    % BoxWithPersonsArea Methods:
    %    BoxWithPersonsArea(objparams)  - constructs the object
    %    reset()                        - does nothing
    %    getOriginUTMCoords()           - returns origin
    %    getLimits()                    - returns limits
    %    getPersonSize()                - returns size of the person patch 
    %    getPersonsJustFound()          - returns an array of size equal to the number of persons containing 
    %                                     a one if the person was found in the current timestep
    %    getPersons()                   - returns the array of persons objects
    %    getPersonsPosition()           - returns the position of persons
    %    getTerrainClass(pts)           - returns the terrain class at the specified gound points
    %    
    
    properties (Access=protected)
        prngId;         % pseudorandom number genereator id
        numPersonsRange;% min and max value for the number of persons in the area
        persons;        % array of Person objects
        found;          % person found flags
        dthr;           % distance threshold to define a person as found
        sthr;           % speed threshold to define a person as found
        pjf;            % person just found flags
        personSize;     % size the person on the ground
        terrain;        % handle to the terrain object
        pInClass;       % probability of the persons belonging to each of the terrain classes  
    end
    
    methods (Sealed,Access=public)
        function obj = BoxWithPersonsArea(objparams)
            % constructs the object
            %
            % Example:
            %
            %   obj=BoxWithPersonsArea(objparams)
            %               objparams.limits - x,y,z limits of the area
            %               objparams.originutmcoords - structure containing the origin in utm coord
            %               objparams.graphics.type - class type for the graphics object
            %                                         (only needed if the 3D display is active)
            %               objparams.sourcesigmarange - min,max values for the width of the Gaussian concentration
            %                                         (with of the concentration along the principal axes is drawn
            %                                          randomly with uniform probability from the specified range)
            %               objparams.state - handle to the simulator state
            %               objparams.numpersonsrange - number of person selected at random between these limits
            %               objparams.personsize - size of the edge of the square patch representing a person [m]
            %               objparams.personfounddistancethreshold  - distance within which a person is deemed as found [m]
            %               objparams.personfoundspeedthreshold - speed lower than which the uav has to travel when close to a person to deem it found [m/s]
            %               objparams.terrain.type - terrain Class
            %               objparams.terrain.graphics - terrain graphics Class     
            %               objparams.terrain.classpercentages - array with the perentage of terrain that should be covered by that class         
            %               objparams.personinclassprob - array with the probability of a person to belong to a specific terrain class 
             
            obj=obj@Area(objparams);
            
            obj.prngId = obj.simState.numRStreams+1;
            obj.simState.numRStreams = obj.simState.numRStreams + 1;
            
            assert(isfield(objparams,'numpersonsrange'),'boxwithpersonarea:nonumpersonsrange',...
                'If using a BoxWithPersonsArea, the task must define the parameter numpersonsrange');
            obj.numPersonsRange = objparams.numpersonsrange;
            
            assert(isfield(objparams,'personsize'),'boxwithpersonarea:nopersonssize',...
                'If using a BoxWithPersonsArea, the task must define the parameter personssize');
            obj.personSize = objparams.personsize;
            
            assert(isfield(objparams,'personfounddistancethreshold'),'boxwithpersonarea:nopersonfounddistancethreshold',...
                'If using a BoxWithPersonsArea, the task must define the parameter personfounddistancethreshold');
            obj.dthr = objparams.personfounddistancethreshold;
            
            assert(isfield(objparams,'personfoundspeedthreshold'),'boxwithpersonarea:nopersonfoundspeedthreshold',...
                'If using a BoxWithPersonsArea, the task must define the parameter personfoundspeedthreshold');
            obj.sthr = objparams.personfoundspeedthreshold;
            
            assert(isfield(objparams,'terrain') && isfield(objparams.terrain,'type'),'boxwithpersonarea:noterraintype',...
                'If using a BoxWithPersonsArea, the task must define the parameter terrain.type');
                                    
            assert(isfield(objparams,'personinclassprob'),'boxwithpersonarea:nopersoninclassprob',...
                'If using a terrain of type PourTerrain, the config file must define the array personincalssprob'); 
            
            assert(sum(objparams.personinclassprob)<=1,'boxwithpersonarea:badpersoninclassprob',...
                'the sum of the terrain classpercentages parameters must be <=1 since they are probabilities');
            
            obj.pInClass = objparams.personinclassprob;
            objparams.terrain.limits = objparams.limits;
            objparams.terrain.state = objparams.state;
            obj.terrain = feval(objparams.terrain.type, objparams.terrain);
            
            tmp.limits = objparams.limits;
            tmp.state = objparams.state;
            [tmp.nr tmp.nc] = obj.terrain.getMapSize();
            if(objparams.graphics.on)
                obj.graphics=feval(objparams.graphics.type,tmp);
            end
        end
        
        function obj = reset(obj)
            % resets object 
            %
            % note: this is generally called by qrsim
            %
            
            % redraw terrain model;
            obj.terrain.reset();
            % redraw set of persons positions
            obj.init();            
            if(obj.graphicsOn)
                % modify plot
                obj.graphics.update(obj.simState,obj.persons,obj.found,obj.terrain.getMap());
            end
	        obj.bootstrapped = 1;
        end
        
        function size = getPersonSize(obj)
            % returns size of the person patch             
            size = obj.personSize;
        end
        
        function pjf = getPersonsJustFound(obj,~)
            % returns an array of size equal to the number of persons containing 
            % a 1 if the person was found (i.e. the UAV is currently sitting over the person)
            % in the current timestep
            
            pjf = obj.pjf;
            obj.pjf = zeros(length(obj.simState.platforms),size(obj.persons,2));
        end
        
        function pos = getPersonsPosition(obj)
            % returns position of persons
            % mostly used for cheating
            pos = zeros(3,size(obj.persons,2));
            for i=1:size(obj.persons,2),
                pos(:,i) = obj.persons{i}.center;
            end
        end
        
        function pers = getPersons(obj)
            % returns the array of persons objects
            pers = obj.persons;
        end
        
        function pers = getNumberOfPersons(obj)
            % returns the number of persons in the area
            pers = length(obj.persons);
        end
        
        function tclass = getTerrainClass(obj,pts)
            % returns the terrain class at the specified gound points
            tclass = obj.terrain.getClass(pts);
        end
    end
    
    methods (Access=protected)
        function obj=init(obj)
            % initialises the object by generating a new ground map and a
            % new set of persons positions
            
            % generate the number and positions of the persons
            numPersons =  (obj.numPersonsRange(1)-1)+randi(obj.simState.rStreams{obj.prngId},obj.numPersonsRange(2)-obj.numPersonsRange(1)+1);
            
            % persons position
            limits = reshape(obj.limits,2,3)';
            lph = 0.5*(limits(1:2,2)+limits(1:2,1));
            lm = 0.8*(limits(1:2,2)-limits(1:2,1));
            
            % for each of the person work out their class an then do rej
            % sampling to generate center
            pacc = triu(toeplitz(ones(size(obj.pInClass)))) * obj.pInClass';            
            
            obj.persons={};
            for i=1:numPersons
                % randomly generate a terrain class according to the specified probabilities 
                tclass = find(pacc<rand(obj.simState.rStreams{obj.prngId},1,1),1,'first');
                if(~isempty(tclass))
                    tclass = tclass - 1;
                else
                    tclass = size(obj.pInClass,2);
                end
                
                % draw a person location and keep drawing until we do not
                % get the desired terrain class
                center = [lph+lm.*(rand(obj.simState.rStreams{obj.prngId},2,1)-0.5);0];
                while(obj.terrain.getClass(center)~=tclass)
                    center = [lph+lm.*(rand(obj.simState.rStreams{obj.prngId},2,1)-0.5);0];
                end
                
                % add the person to the array
                obj.persons{i}=Person(center,obj.personSize);
            end
            
            obj.found = zeros(1,numPersons);
            obj.pjf = zeros(length(obj.simState.platforms),numPersons);
        end
        
        function obj = update(obj, ~)
            % takes care of changing the colour of the person patch if
            % found
            %
            % Note:
            %  this method is called automatically by the step() of the Steppable parent
            %  class and should not be called directly.
            %
            
            obj.pjf =  zeros(length(obj.simState.platforms),length(obj.persons));
            for j = 1:length(obj.simState.platforms)
                X = obj.simState.platforms{j}.getX();
                
                %UV = [];
                for i = 1:length(obj.persons)
                    %uv = obj.simState.platforms{j}.camera.cam_prj(X(1:3),dcm(X),obj.persons{i}.center));
                    %if(~isempty(uv))
                    %    UV= [UV,uv];
                    if(~obj.found(i) && (norm(obj.persons{i}.center-X(1:3)) <= obj.dthr) && (norm(X(7:9))<= obj.sthr))
                        obj.pjf(j,i) = 1;
                    end
                end
            end
            
            obj.found = obj.found | (sum(obj.pjf,1)>0);

            if(any(any(obj.pjf)) && obj.graphicsOn)
                % modify plot
                obj.graphics.update(obj.simState,obj.persons,obj.found,[]);
            end
        end
    end
end
