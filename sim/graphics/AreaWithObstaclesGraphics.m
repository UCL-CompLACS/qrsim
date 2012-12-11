classdef AreaWithObstaclesGraphics<handle
    % Class that handles the 3D visualization a the working area of the simulator
    % in which are present some cylinder like objects.
    % This implementation is very basic but has the advantage of not depending on any
    % additional toolbox
    %
    % AreaWithObstaclesGraphics methos:
    %   AreaWithObstaclesGraphics(objparams) - constructs the object
    %                    objparams.obstacles - obstacles
    %
    methods (Sealed)
        
        function obj = AreaWithObstaclesGraphics(objparams)
            % constructs the object
            %
            % Example:
            %   obj = AreaGraphics(objparams)
            %        objparams = [minx maxx miny maxy minz maxz]  meters
            %
            
            set(0,'CurrentFigure',objparams.state.display3d.figure)
            hold on;
            limits = objparams.limits;
            
            %ground patch
            if(~isfield(objparams,'backgroundimage'))
                
                cx = [limits(1) limits(1);
                    limits(1) limits(2);
                    limits(2) limits(2)];
                
                cy = [limits(3) limits(4);
                    limits(4) limits(3);
                    limits(3) limits(4)];
                
                cz = zeros(3,2);
                
                objparams.state.display3d.ground = patch(cx,cy,cz,'FaceColor',[0.2,0.4,0.2],'EdgeColor','none');
                
            else
                
                texture = imread(objparams.backgroundimage);
                texture = imrotate(texture,-90); %alingns the image coords to NED
                
                dotpos = strfind(objparams.backgroundimage,'.');
                
                assert(~isempty(dotpos),'areagraphics:badfilename',...
                    'the backgroundimage parameter does not seem to be a valid image file name');
                
                csvdatafile = [objparams.backgroundimage(1:dotpos),'csv'];
                
                assert(exist(csvdatafile,'file')==2,'areagraphics:missingimagedata',...
                    'the file specifying the parameters of the backgroundimage is not present');
                
                bbox = csvread(csvdatafile); % no need to rotate, osgb is aligned with NED                
                tsize = abs([bbox(1,2)-bbox(2,2),bbox(2,1)-bbox(1,1)]);
                
                areasize = abs(limits*[1 0; -1 0; 0 1; 0 -1; 0 0; 0 0]);
                
                % get the relevant (i.e. scaled) chunk of the texture,
                % if the simulated are is larger than the texture then all
                % the texture is used but is not stretched.                
                if areasize(1)<tsize(1) 
                    nsx = floor((areasize(1)/tsize(1))*size(texture,2));
                    minnsx = floor(size(texture,2)/2 - nsx/2);
                    maxnsx = floor(size(texture,2)/2 + nsx/2);
                    vx = limits(1):limits(2);
                else
                    minnsx = 1;
                    maxnsx = size(texture,2);
                    vx = -(tsize(1)/2):(tsize(1)/2);
                end
                
                if areasize(2)<tsize(2) 
                    nsy = floor((areasize(2)/tsize(2))*size(texture,1));
                    minnsy = floor(size(texture,1)/2 - nsy/2);
                    maxnsy = floor(size(texture,1)/2 + nsy/2);
                    vy = limits(3):limits(4);
                else
                    minnsy = 1;
                    maxnsy = size(texture,1);
                    vy = -(tsize(2)/2):(tsize(2)/2);
                end
                               
                texture = texture(minnsy:maxnsy,minnsx:maxnsx,:);      
                
               
                [x,y] = meshgrid(vx,vy);
                z = zeros(size(vy,2),size(vx,2));
                objparams.state.display3d.ground = surface(x,y,z);
                
                set(objparams.state.display3d.ground,'facecolor','texturemap');
                set(objparams.state.display3d.ground,'edgecolor','none');
                set(objparams.state.display3d.ground,'cdata',texture);
                
            end
            
            % plot obstacles as cylinders
            for i = 1:size(objparams.obstacles,2),
                [X,Y,Z] = cylinder(objparams.obstacles(4,i)-0.2,16);
                
                objparams.state.display3d.obstacle(i) = surface(X+objparams.obstacles(1,i), ...
                     Y+objparams.obstacles(2,i), ...
                     Z*abs(objparams.obstacles(3,i))+objparams.obstacles(3,i));
                set(objparams.state.display3d.obstacle(i),'EdgeColor', [0.627 0.321 0.176],'FaceColor', [0.627 0.321 0.176]); 
                set(objparams.state.display3d.obstacle(i),'FaceAlpha',0.7,'EdgeAlpha',1);
            end
            
            %invert axis to be coherent with NED
            set(gca,'ZDir','rev');
            set(gca,'YDir','rev');
            
            
            % a reasonable starting view
            view([-30,25]);
            camzoom(1.8);
            set(gca,'CameraViewAngleMode','Manual');
            
            % set up a correct size for the plot
            axis(limits);
            arx = limits(2)-limits(1);
            ary = limits(4)-limits(3);
            arz = limits(6)-limits(5);
            set(gca,'PlotBoxAspectRatio',[arx ary arz])
            
            % give names to things
            grid on;
            xlabel('X');
            ylabel('Y');
            zlabel('Z');
        end
        
    end
end
