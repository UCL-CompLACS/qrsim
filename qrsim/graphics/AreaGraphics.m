classdef AreaGraphics<handle
    % Class that handles the 3D visualization of the working area of the simulator
    % This implementation is very basic but has the advantage of not depending on any
    % additional toolbox
    %
    
    methods (Sealed)
        
        function obj = AreaGraphics(objparams)
            % constructs the object
            %
            % Example:
            %   obj = AreaGraphics(objparams)
            %        objparams.limits = [minx maxx miny maxy minz maxz]  meters
            %
            global state;
            
            set(0,'CurrentFigure',state.display3d.figure)
            
            % ground patch
            cx = [objparams.limits(1) objparams.limits(1);
                objparams.limits(1) objparams.limits(2);
                objparams.limits(2) objparams.limits(2)];
            
            cy = [objparams.limits(3) objparams.limits(4);
                objparams.limits(4) objparams.limits(3);
                objparams.limits(3) objparams.limits(4)];
            
            cz = zeros(3,2);
            
            state.display3d.ground = patch(cx,cy,cz,'FaceColor',[0.2,0.4,0.2],'EdgeColor','none');
            
            
            %invert axis to be coherent with NED
            set(gca,'ZDir','rev');
            set(gca,'YDir','rev');
            
            
            % a reasonable starting view
            view([-30,25]);
            camzoom(1.4);
            set(gca,'CameraViewAngleMode','Manual');
            
            % set up a correct size for the plot
            axis(objparams.limits);
            arx = objparams.limits(2)-objparams.limits(1);
            ary = objparams.limits(4)-objparams.limits(3);
            arz = objparams.limits(6)-objparams.limits(5);
            set(gca,'PlotBoxAspectRatio',[arx ary arz])
            
            % give names to things
            grid on;
            xlabel('X');
            ylabel('Y');
            zlabel('Z');
        end
        
    end
end
