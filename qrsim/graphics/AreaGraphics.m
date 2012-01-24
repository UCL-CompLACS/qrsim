classdef AreaGraphics<handle
    % Class that handles the 3D visualization of the working area of the simulator
    % This implementation is very basic but has the advantage of not depending on any
    % additional toolbox
    %
    % AreaGraphics methos:
    %   AreaGraphics(objparams) - constructs the object
    %
    methods (Sealed)
        
        function obj = AreaGraphics(objparams)
            % constructs the object
            %
            % Example:
            %   obj = AreaGraphics(objparams)
            %        objparams = [minx maxx miny maxy minz maxz]  meters
            %
            global state;
            
            set(0,'CurrentFigure',state.display3d.figure)
            
            % ground patch
            cx = [objparams(1) objparams(1);
                objparams(1) objparams(2);
                objparams(2) objparams(2)];
            
            cy = [objparams(3) objparams(4);
                objparams(4) objparams(3);
                objparams(3) objparams(4)];
            
            cz = zeros(3,2);
            
            state.display3d.ground = patch(cx,cy,cz,'FaceColor',[0.2,0.4,0.2],'EdgeColor','none');
            
            
            %invert axis to be coherent with NED
            set(gca,'ZDir','rev');
            set(gca,'YDir','rev');
            
            
            % a reasonable starting view
            view([-30,25]);
            camzoom(1.8);
            set(gca,'CameraViewAngleMode','Manual');
            
            % set up a correct size for the plot
            axis(objparams);
            arx = objparams(2)-objparams(1);
            ary = objparams(4)-objparams(3);
            arz = objparams(6)-objparams(5);
            set(gca,'PlotBoxAspectRatio',[arx ary arz])
            
            % give names to things
            grid on;
            xlabel('X');
            ylabel('Y');
            zlabel('Z');
        end
        
    end
end
