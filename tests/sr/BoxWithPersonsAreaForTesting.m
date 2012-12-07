classdef BoxWithPersonsAreaForTesting<BoxWithPersonsArea
    % extended version of BoxWithPersonsArea which allows to set explicitly 
    % the person position
    
    properties
    end
    
    methods
        function obj=BoxWithPersonsAreaForTesting(objparams)            
           obj=obj@BoxWithPersonsArea(objparams);
        end
        
        function obj=setPersonsCenters(obj,c)
            for i=1:length(obj.persons),
                obj.persons{i}.setCenter(c(:,i)); 
            end
            if(obj.graphicsOn)
                % modify plot
                obj.graphics.update(obj.simState,obj.persons,obj.found,obj.terrain.getMap());
            end
        end    
    end
    
end

