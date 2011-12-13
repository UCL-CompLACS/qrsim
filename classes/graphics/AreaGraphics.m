classdef AreaGraphics<handle
    %INIT3DGRAPHICS
    % initialize the common part of the 3D visualization
    % i.e. the figure with correct axis and size and the ground patch
    
    methods (Sealed)
        
        function obj = AreaGraphics(objparams)
            
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
            axis(objparamslimits);
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
