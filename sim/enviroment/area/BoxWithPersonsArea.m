classdef BoxWithPersonsArea<BoxArea
    % Defines a simple box shaped area in which is present a plume with concentration described by a 3d Gaussian
    %
    % BoxWithPersonsArea Methods:
    %    BoxWithPersonsArea(objparams)   - constructs the object
    %    reset()                        - does nothing
    %    getOriginUTMCoords()           - returns origin
    %    getLimits()                    - returns limits
    %
    properties (Constant)
        DTHR = 1;   % distance threshold
        STHR = 0.2; % speed threshold
    end
    
    properties (Access=protected)
        prngId;
        numPersonsRange;
        persons;
        found;
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
                'If using a GaussianPlumeArea, the task must define the parameter sourcesigmarange');                     
            obj.numPersonsRange = objparams.numpersonsrange;
           
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
        
        function pjf = getPersonsJustFound(obj,X)
            % figures out if the UAV is currently sitting over a person
            % in which case it will be deemed as found
           
            pjf = zeros(1,size(obj.persons,2));
            for i = 1:size(obj.persons,2)
                if((norm(obj.persons(:,i)-X(1:3)) <= obj.DTHR) && (norm(X(7:9))<= obj.STHR))
                   pjf(i) = 1; 
                end
            end
            
            obj.found = obj.found | pjf;
        end        
               
        function pos = getPersonsPosition(obj)
            % returns position of persons
            pos = obj.persons;
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
            obj.persons = [repmat(lph,1,numPersons)+repmat(lm,1,numPersons).*(rand(obj.simState.rStreams{obj.prngId},2,numPersons)-0.5);zeros(1,numPersons)];
            
            obj.found = zeros(1,size(obj.persons,2));
        end
    end
end
