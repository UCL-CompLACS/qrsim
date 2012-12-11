classdef CameraGraphics<handle
    % Class that displays the camera frustum, the camera frame
    % and the camera observations given the current
    % position and orientation of the UAV
    %
    % CameraGraphics Methods:
    %   CameraGraphics(params)  - constructs the object
    %   update()                         - does nothing
    %
    
    properties (Access = protected)
        simState;           % simulator state handle
        gHandle;            % graphics handle
        renderFrame;        % render frame flag
        renderObservations; % render obs flag
    end
    
    methods (Sealed)
        function obj=CameraGraphics(objparams)
            % constructs the object
            %
            % Example:
            %   obj =  CameraGraphics(params);
            %          params.renderframe - on if the camera frame is to be renedered
            %          params.renderobservations - on if the camera frame if the observations have to be renedered
            %          
            
            obj.simState = objparams.state;
            
            if(isfield(objparams,'renderframe'))
                obj.renderFrame = objparams.renderframe;
            end
            if(isfield(objparams,'renderobservations'))
                obj.renderObservations = objparams.renderobservations;
            end
            set(0,'CurrentFigure',obj.simState.display3d.figure);
            hold on;
            obj.gHandle.trjData.x = 0;
            obj.gHandle.trjData.y = 0;
            obj.gHandle.trjData.z = 0;
            obj.gHandle.frustum = line('XData',obj.gHandle.trjData.x,'YData',obj.gHandle.trjData.y,...
                'ZData',obj.gHandle.trjData.z);
                        
            if(obj.renderObservations)                
                 obj.gHandle.frameObs = surf(zeros(4),zeros(4), -0.05*ones(4),zeros(4));
                 set(obj.gHandle.frameObs,'EdgeColor','none');
                 caxis([-10 10]);
            else
                obj.renderObservations = 0;
            end
            
            if(obj.renderFrame)
                obj.simState.display3d.camFigure{objparams.id} = figure(10+objparams.id);
                obj.gHandle.frame = plot(0,0,'*r');
                axis equal;
                axis([0 1280 0 960]);
                title(['image frame of uav ' num2str(objparams.id)]);
                % image origin on the top left
                % of the frame, x positive in the right
                % and y positive downwards
                set(gca,'YDir','reverse')
            else
                obj.renderFrame = 0;
            end
        end
    end
    
    methods (Static)
        function pp = z0intersect(p,t)
            % compute intersection with ground z=0
            pp(1,1)=(p(1)-t(1))*((-t(3))/(p(3)-t(3)))+t(1);
            pp(1,2)=(p(2)-t(2))*((-t(3))/(p(3)-t(3)))+t(2);
            pp(1,3)=0;
        end
    end
    
    methods
        function obj = update(obj,X,R,f,c,llkd,cg,gridDims)
            % updates the object
            
            % translation
            t = X(1:3);
            
            % world to body frame
            Rp =  dcm(X);
            
            % points in front of the camera to
            % display field of view, the distance chosen
            % is arbitrary
            s=[ c(1)  c(1) -c(1) -c(1);
                c(2) -c(2)  c(2) -c(2);
                f(1)  f(1)  f(1)  f(1)]./1000;
            
            % bring the chosen points to world coords
            % by composing camera to body frame (R'),
            % and body to world frame transformations (r + t)
            ss = Rp'*R'*s;
            ss = ss+repmat(t,1,4);
            
            % compute intersection point of the camera field
            % of view with z=0
            gp1 = obj.z0intersect(ss(:,1),t);
            gp2 = obj.z0intersect(ss(:,2),t);
            gp3 = obj.z0intersect(ss(:,3),t);
            gp4 = obj.z0intersect(ss(:,4),t);
            
            set(0,'CurrentFigure',obj.simState.display3d.figure)
            
            x = [t(1),gp1(1),gp2(1),t(1),gp2(1),gp4(1),t(1),gp4(1),gp3(1),t(1),gp3(1),gp1(1)];
            y = [t(2),gp1(2),gp2(2),t(2),gp2(2),gp4(2),t(2),gp4(2),gp3(2),t(2),gp3(2),gp1(2)];
            z = [t(3),gp1(3),gp2(3),t(3),gp2(3),gp4(3),t(3),gp4(3),gp3(3),t(3),gp3(3),gp1(3)];
            set(obj.gHandle.frustum,'XData',x);
            set(obj.gHandle.frustum,'YData',y);
            set(obj.gHandle.frustum,'ZData',z);
            
            if(obj.renderFrame)
                UV = [];
                persons = obj.simState.environment.area.getPersonsPosition();
                for i = 1:size(persons,2)
                    uv = cam_prj(X(1:3), dcm(X) ,persons(:,i), c , f, R);
                    UV= [UV,uv];
                end
                                
                if(~isempty(UV))
                    set(obj.gHandle.frame,'XData',UV(1,:));
                    set(obj.gHandle.frame,'YData',UV(2,:));
                else
                    set(obj.gHandle.frame,'XData',[]);
                    set(obj.gHandle.frame,'YData',[]);
                end
            end
            
            if(obj.renderObservations)
                if(size(llkd,1)>=4)
                    llkdmat = reshape(llkd,gridDims(2),gridDims(1));
                    xcgmat = reshape(cg(1,:),gridDims(2),gridDims(1));
                    ycgmat = reshape(cg(2,:),gridDims(2),gridDims(1));
                    
                    set(obj.gHandle.frameObs,'XData',xcgmat);
                    set(obj.gHandle.frameObs,'YData',ycgmat);
                    set(obj.gHandle.frameObs,'ZData',-0.05*ones(size(xcgmat)));
                    set(obj.gHandle.frameObs,'CData',llkdmat);
                    caxis([-10 10]);
                end
            end

        end
        
        function obj = reset(obj)
            % does nothing
            if(obj.renderFrame) 
                set(obj.gHandle,'XData',[]);
                set(obj.gHandle,'YData',[]);
            end
        end
    end
    
end
