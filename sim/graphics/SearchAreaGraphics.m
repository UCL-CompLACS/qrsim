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
        PERSONSIZE = 0.5; % size in meters of the patch representing the person
    end
    
    properties (Access = private)
        p;
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
            obj.p = obj.PERSONSIZE.*[cos(0:0.3:2*pi+0.3)' sin(0:0.3:2*pi+0.3)'];
        end
        
        function obj = update(obj,state,persons,found)
            % draw coloured patches to display persons
            % red for persons to be found blue for persons already found
            
            set(0,'CurrentFigure',state.display3d.figure)            
            hold on;
            
            if(~isempty(persons))
                if(~isfield(state.display3d,'persons'))
                    for i=1:size(persons,2),
                        state.display3d.persons{i} = patch(persons(1,i)+obj.p(:,1),persons(2,i)+obj.p(:,2),-0.02*ones(size(obj.p,1),1),'r','EdgeColor','r');
                    end
                else
                    for i=1:size(persons,2),
                        set(state.display3d.persons{i},'XData',persons(1,i)+obj.p(:,1));
                        set(state.display3d.persons{i},'YData',persons(2,i)+obj.p(:,2));
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
