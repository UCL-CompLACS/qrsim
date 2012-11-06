classdef SearchAreaGraphics<AreaGraphics
    % Class that handles the 3D visualization of the flight area of the simulator
    % for the search and rescue task.
    % This implementation is very basic but has the advantage of not depending on any
    % additional toolbox
    %
    % SearchAreaGraphics methos:
    %   SearchAreaGraphics(objparams) - constructs the object
    %
    properties (Constant)
        PERSONSIZE = 0.30; % radius in meters of the patch representing the person
    end
    
    methods (Sealed)
        
        function obj = SearchAreaGraphics(objparams)
            % constructs the object
            %
            % Example:
            %   obj = SearchAreaGraphics(objparams)
            %        objparams.limits = [minx maxx miny maxy minz maxz]  meters
            %        objparams.backgroundimage = the image file to be used as background
            
            obj=obj@AreaGraphics(objparams); 
        end
        
        function obj = update(obj,state,persons,found)
            % draw coloured patches to display persons
            % red for persons to be found blue for persons already found
            
            set(0,'CurrentFigure',state.display3d.figure)            
            hold on;
            
            if(~isempty(persons))
                if(~isfield(state.display3d,'persons'))
                    for i=1:size(persons,2),
                        xdata = [persons{i}.bb(1,1:3)',persons{i}.bb(1,2:4)'];
                        ydata = [persons{i}.bb(2,1:3)',persons{i}.bb(2,2:4)'];
                        zdata = [persons{i}.bb(3,1:3)',persons{i}.bb(3,2:4)'];             
                        state.display3d.persons{i} = patch(xdata,ydata,zdata,'r','EdgeColor','r');
                    end
                else
                    for i=1:size(persons,2),
                        xdata = [persons{i}.bb(1,1:3)',persons{i}.bb(1,2:4)'];
                        ydata = [persons{i}.bb(2,1:3)',persons{i}.bb(2,2:4)'];
                        zdata = [persons{i}.bb(3,1:3)',persons{i}.bb(3,2:4)'];  
                        set(state.display3d.persons{i},'XData',xdata);
                        set(state.display3d.persons{i},'YData',ydata);
                        set(state.display3d.persons{i},'ZData',zdata);                        
                        if(found(i)==0)
                            set(state.display3d.persons{i},'EdgeColor','r');
                            set(state.display3d.persons{i},'FaceColor','r');
                        else
                            set(state.display3d.persons{i},'EdgeColor','b');
                            set(state.display3d.persons{i},'FaceColor','b');
                        end
                    end
                end
            end
        end        
    end
end
