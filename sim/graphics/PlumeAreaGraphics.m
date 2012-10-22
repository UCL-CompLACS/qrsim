classdef PlumeAreaGraphics<AreaGraphics
    % Class that handles the 3D visualization of the working area of the simulator
    % in the presence of a dispersed plume.
    % This implementation is very basic but has the advantage of not depending on any
    % additional toolbox
    %
    % PlumeAreaGraphics methos:
    %   PlumeAreaGraphics(objparams) - constructs the object
    %
    properties (Constant)
        DOTSIZE = 15; % size of the plume dots
        C1 = 10; % offset concentration value to get meaningful colormap values
        C2 = 1e-15; %min concentration value to ensure that samples are always displayed
    end
    
    methods (Sealed)
        
        function obj = PlumeAreaGraphics(objparams)
            % constructs the object
            %
            % Example:
            %   obj = PlumeAreaGraphics(objparams)
            %        objparams.limits = [minx maxx miny maxy minz maxz]  meters
            %        objparams.backgroundimage = the image file to be used as background 
            
            obj=obj@AreaGraphics(objparams);            
        end
        
        function obj = update(obj,state,sources,wind,positions,values)
            % draw coloured samples to display concentration
            
            set(0,'CurrentFigure',state.display3d.figure)
            
            hold on;

            colormap hot;
            
            if(~isempty(positions))
                if(~isfield(state.display3d,'plume'))
                    state.display3d.plume = scatter3(positions(1,:),positions(2,:),positions(3,:),obj.DOTSIZE,obj.C1+log(values+obj.C2),'filled');
                 else
                    set(state.display3d.plume,'XData',positions(1,:));
                    set(state.display3d.plume,'YData',positions(2,:));
                    set(state.display3d.plume,'ZData',positions(3,:));
                    set(state.display3d.plume,'CData',obj.C1+log(values+obj.C2));  
                 end    
            end
            
            if(~isfield(state.display3d,'sources') && ~isempty(sources))
                state.display3d.sources = plot3(sources(1,:),sources(2,:),sources(3,:),'*');
            
                for i=1:size(sources,2),
                    l = [sources(:,i),sources(:,i)+wind*4];
                    state.display3d.dirs(i) = plot3(l(1,:),l(2,:),l(3,:),'-','LineWidth',2);
                end    
            end
        end

    end
end
