classdef BoxWithPersonsArea<Area
    % Defines a simple box shaped area in which is present a plume with concentration described by a 3d Gaussian
    %
    % BoxWithPersonsArea Methods:
    %    BoxWithPersonsArea(objparams)   - constructs the object
    %    reset()                        - does nothing
    %    getOriginUTMCoords()           - returns origin
    %    getLimits()                    - returns limits
    %
    
    properties (Access=protected)
        prngId;
        numPersonsRange;
        persons;
        found;
        dthr;   % distance threshold
        sthr; % speed threshold
        pjf;
        personSize;
        terrain;
        pInClass;
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
            %
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
            size = obj.personSize;
        end
        
        function pjf = getPersonsJustFound(obj,~)
            % figures out if the UAV is currently sitting over a person
            % in which case it will be deemed as found
            
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
            % returns persons
            pers = obj.persons;
        end
        
        function tclass = getTerrainClass(obj,pts)
            % returns persons
            tclass = obj.terrain.getClass(pts);
        end
    end
    
    methods (Access=protected)
        function obj=init(obj)
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
