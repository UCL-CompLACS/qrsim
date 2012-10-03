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
            %        objparams.backgroundimage = the image file to be used as background 
            
            set(0,'CurrentFigure',objparams.state.display3d.figure)
            
            %ground patch
            if(~isfield(objparams,'backgroundimage'))
                
                cx = [objparams.limits(1) objparams.limits(1);
                    objparams.limits(1) objparams.limits(2);
                    objparams.limits(2) objparams.limits(2)];
                
                cy = [objparams.limits(3) objparams.limits(4);
                    objparams.limits(4) objparams.limits(3);
                    objparams.limits(3) objparams.limits(4)];
                
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
                
                areasize = abs(objparams.limits*[1 0; -1 0; 0 1; 0 -1; 0 0; 0 0]);
                
                % get the relevant (i.e. scaled) chunk of the texture,
                % if the simulated are is larger than the texture then all
                % the texture is used but is not stretched.                
                if areasize(1)<tsize(1) 
                    nsx = floor((areasize(1)/tsize(1))*size(texture,2));
                    minnsx = floor(size(texture,2)/2 - nsx/2);
                    maxnsx = floor(size(texture,2)/2 + nsx/2);
                    vx = objparams.limits(1):objparams.limits(2);
                else
                    minnsx = 1;
                    maxnsx = size(texture,2);
                    vx = -(tsize(1)/2):(tsize(1)/2);
                end
                
                if areasize(2)<tsize(2) 
                    nsy = floor((areasize(2)/tsize(2))*size(texture,1));
                    minnsy = floor(size(texture,1)/2 - nsy/2);
                    maxnsy = floor(size(texture,1)/2 + nsy/2);
                    vy = objparams.limits(3):objparams.limits(4);
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
            
            %invert axis to be coherent with NED
            set(gca,'ZDir','rev');
            set(gca,'YDir','rev');             
            
            %p = [70;20;-15];
            %pp = [p,p-[5;5;0],p-[5;4;0],p-[4;5;0],p-[5;5;0]];
            %objparams.state.display3d.wind = line(pp(1,:),pp(2,:),pp(3,:));
            %set(objparams.state.display3d.wind,'color','r');
            %set(objparams.state.display3d.wind,'LineWidth',2);            
            %objparams.state.display3d.text = text(68,18,-18,'MEAN WIND','FontSize',15,'Color','r');
            
            % a reasonable starting view
            view([-30,35]);
            camzoom(1.8);
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
