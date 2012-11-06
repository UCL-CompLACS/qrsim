classdef BoxWithPersonsArea<BoxArea
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
    end
    
    properties (Constant)
        personSize = 0.5;        
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
            obj=obj@BoxArea(objparams);
            
            obj.prngId = obj.simState.numRStreams+1;
            obj.simState.numRStreams = obj.simState.numRStreams + 1;
            
            assert(isfield(objparams,'numpersonsrange'),'boxwithpersonarea:numpersonsrange',...
                'If using a BoxWithPersonsArea, the task must define the parameter sourcesigmarange');
            obj.numPersonsRange = objparams.numpersonsrange;
            
            assert(isfield(objparams,'personfounddistancethreshold'),'boxwithpersonarea:personfounddistancethreshold',...
                'If using a BoxWithPersonsArea, the task must define the parameter personfounddistancethreshold');
            obj.dthr = objparams.personfounddistancethreshold;
            
            assert(isfield(objparams,'personfoundspeedthreshold'),'boxwithpersonarea:numpersonsrange',...
                'If using a BoxWithPersonsArea, the task must define the parameter personfoundspeedthreshold');
            obj.sthr = objparams.personfoundspeedthreshold;
            
            if(objparams.graphics.on)
                tmp.limits = objparams.limits;
                tmp.state = objparams.state;
                if(isfield(objparams,'graphics') && isfield(objparams.graphics,'backgroundimage'))
                    tmp.backgroundimage = objparams.graphics.backgroundimage;
                end
                
                obj.graphics=feval(objparams.graphics.type,tmp);
            end
        end
        
        function obj = reset(obj)
            % redraw a different plume pattern
            obj.init();
            % modify plot
            obj.graphics.update(obj.simState,obj.persons,obj.found);
        end
        
        function pjf = getPersonsJustFound(obj)
            % figures out if the UAV is currently sitting over a person
            % in which case it will be deemed as found
            
            pjf = obj.pjf;
            obj.pjf = zeros(length(obj.simState.platforms),size(obj.persons,2));
        end
        
        function pos = getPersonsPosition(obj)
            % returns position of persons
            % only used for cheating
            pos = zeros(3,size(obj.persons));
            for i=1:length(obj.persons)
                pos(:,i) = obj.persons{i}.center;
            end
        end
    end
    
    methods (Access=protected)
        function obj=init(obj)
            % generate the number and positions of the persons
            numPersons =  (obj.numPersonsRange(1)-1)+randi(obj.simState.rStreams{obj.prngId},obj.numPersonsRange(2)-obj.numPersonsRange(1)+1);
            
            % source position
            limits = reshape(obj.limits,2,3)';
            lph = 0.5*(limits(1:2,2)+limits(1:2,1));
            lm = 0.8*(limits(1:2,2)-limits(1:2,1));
            centers = [repmat(lph,1,numPersons)+repmat(lm,1,numPersons).*(rand(obj.simState.rStreams{obj.prngId},2,numPersons)-0.5);zeros(1,numPersons)];
            
            for i=1:numPersons,
               obj.persons{i}=Person(centers(:,i),obj.personSize); 
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

                UV = [];
                for i = 1:length(obj.persons)       
                    %uv = obj.simState.platforms{j}.camera.cam_prj(X(1:3),dcm(X),obj.persons{i}.center));
                    %if(~isempty(uv))
                    %    UV= [UV,uv];
                    if((norm(obj.persons{i}.center-X(1:3)) <= obj.dthr) && (norm(X(7:9))<= obj.sthr))
                        obj.pjf(j,i) = 1;
                    end
                end      
            end
            
            obj.found = obj.found | (sum(obj.pjf,1)>0);
            
            if(any(obj.pjf) && obj.graphicsOn)
                % modify plot
                obj.graphics.update(obj.simState,obj.persons,obj.found);
            end
        end
    end
end
