classdef CameraGraphics<handle
    % Class that displays the camera frustum goven the current
    % position and orientation of the UAV
    %
    % CameraGraphics Methods:
    %   CameraGraphics(params)  - constructs the object
    %   update()                         - does nothing
    %
       
    properties (Access = protected)
        simState;
        gHandle;
    end
    
    methods (Sealed)
        function obj=CameraGraphics(objparams)
            % constructs the object
            obj.simState = objparams.state;
            % set(0,'CurrentFigure',obj.simState.display3d.figure)
            obj.gHandle.trjData.x = 0;
            obj.gHandle.trjData.y = 0;
            obj.gHandle.trjData.z = 0;
            obj.gHandle.frustum = line('XData',obj.gHandle.trjData.x,'YData',obj.gHandle.trjData.y,...
                    'ZData',obj.gHandle.trjData.z);
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
        function obj = update(obj,X,R,f,c)
            % translation
            t = X(1:3);
            
            % body to world frame
            r =  dcm(X)';

            % points in front of the camera to
            % display field of view, the distance chosen
            % is arbitrary
            s=[ c(1)  c(1) -c(1) -c(1);
                c(2) -c(2)  c(2) -c(2);
                f(1)  f(1)  f(1)  f(1)]./1000;
            
            % bring the chosen points to world coords 
            % by composing camera to body frame (R'),  
            % and body to wolr frame transformations (r + t)
            ss = r*R'*s;
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
        end
        
        function obj = reset(obj)
             % does nothing       
        end
    end
    
end
