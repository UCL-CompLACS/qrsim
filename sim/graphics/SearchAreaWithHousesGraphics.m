classdef SearchAreaWithHousesGraphics<handle
    % Class that handles the 3D visualization of the flight area of the simulator
    % for the search and rescue task.
    % This implementation is very basic but has the advantage of not depending on any
    % additional toolbox
    %
    % SearchAreaWithHousesGraphics methos:
    %   SearchAreaWithHousesGraphics(objparams) - constructs the object
    %
    properties (Constant)
        PERSONSIZE = 0.30; % radius in meters of the patch representing the person
    end
    
    properties (Access = protected)
       gHandle; % graphics handle
    end    
        
    methods (Sealed)
        
          function obj = SearchAreaWithHousesGraphics(objparams)
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
            
            cube = [-1, 1, 1;-1, 1,-1;-1,-1,-1;-1,-1, 1; 1, 1, 1; 1, 1,-1; 1,-1,-1;1,-1, 1];
            bf = [1 2 3 4; 5 6 7 8; 4 3 7 8; 1 5 6 2; 1 4 8 5; 6 7 3 2];
       
            
            % plot obstacles as boxes
            for i = 1:size(objparams.boxes,2),
                b = repmat(objparams.boxes(1:3,i)',size(cube,1),1)+(cube.*repmat(objparams.boxes(4:6,i)',size(cube,1),1))*angleToDcm(0,0,objparams.boxes(7,i),'XYZ');
                                
                objparams.state.display3d.box(i) = patch('Vertices',b,'Faces',bf);
                %set(objparams.state.display3d.box(i) ,'FaceAlpha',0.5,'EdgeAlpha',0);                
                set(objparams.state.display3d.box(i),'EdgeColor', [0.527 0.221 0.076],'FaceColor', [0.627 0.321 0.176]); 
                set(objparams.state.display3d.box(i),'FaceAlpha',0.8,'EdgeAlpha',1);
            end
                        
            
            %ground grid
            xstep = (objparams.limits(2)-objparams.limits(1))/objparams.nr;
            ystep = (objparams.limits(4)-objparams.limits(3))/objparams.nc;
            
            xx = repmat(objparams.limits(1)+(0:xstep:(objparams.nr-1)*xstep)',1,objparams.nc);
            yy = repmat(objparams.limits(3)+(0:ystep:(objparams.nc-1)*ystep),objparams.nr,1);
            
            obj.gHandle;% = pcolor(xx,yy,-0.1*ones(objparams.nr,objparams.nc));
            
            
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

     
        
        function obj = update(obj,state,persons,found,map)
            % draw coloured patches to display persons
            % red for persons to be found blue for persons already found
            
            set(0,'CurrentFigure',state.display3d.figure)
            %hold on;
            if(0)%~isempty(map))
                set(obj.gHandle,'CData',map);
                caxis([-10 10]);
            end
            
            if(0)%~isempty(persons))
                if(~isfield(state.display3d,'persons'))
                    for i=1:size(persons,2),
                        xdata = [persons{i}.bb(1,1:3)',persons{i}.bb(1,2:4)'];
                        ydata = [persons{i}.bb(2,1:3)',persons{i}.bb(2,2:4)'];
                        zdata = [persons{i}.bb(3,1:3)',persons{i}.bb(3,2:4)'];
                        state.display3d.persons{i} = patch(xdata,ydata,zdata,'r','EdgeColor','r');
                    end
                else
                    if(size(persons,2)~=size(state.display3d.persons))
                        for i=1:size(state.display3d.persons,2),
                            delete(state.display3d.persons{1,i});
                        end
                        state.display3d.persons={};
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
end
