classdef CameraWithClassifier < Sensor
    % Class that simulates a camera with a person classifier.
    % Given the current position of the helicopter and of a person in the
    % environment we compute the camera view and use
    %
    % CameraWithClassifier Methods:
    %    CameraWithClassifier(objparams)    - constructor
    %    getMeasurement(X)          - return 
    %    update(X)                  - generates a new noise sample
    %    setState(X)                - reinitializes the current state and noise
    %    reset()                    - re-init the ids of the visible satellites
    %
    
    properties (Access=public)
        R;  % rotation from platform to camera frame
        f;  % focal length
        c;  % principal points
        cameraMeasurements;
    end
    
    methods (Sealed,Access=public)
        function obj=CameraWithClassifier(objparams)
            % constructs the object.
            % Selects the satellite vehicles visible to this receiver among the ones in
            % objparams.svs the total number of visible satellites is generate
            % randomly (uniform number between objparams.minmaxnumsv(1) and
            % objparams.minmaxnumsv(2)). The selection of satellites is kept FIX during
            % all the simulation.
            %
            % Example:
            %
            %   obj=CameraClassifier(objparams)
            %                objparams.dt - timestep of this object
            %                objparams.on - 1 if the object is active
            %                objparams.f - receiver noise standard deviation
            %                objparams.c - time delay in multiples of receiver's dt
            %
            obj=obj@Sensor(objparams);
                        
            assert(isfield(objparams,'f'),'camera:f','the platform config must define the camera.f parameters');
            obj.f = objparams.f;
            assert(isfield(objparams,'c'),'camera:c','the platform config must define the camera.c parameters');
            obj.c = objparams.c;
            assert(isfield(objparams,'r'),'camera:r','the platform config must define the camera.r parameters');
            obj.R =  angle2dcm(objparams.r(1),objparams.r(2),objparams.r(3),'ZYX');  
        end        
        
        function cameraMeasurement = getMeasurement(obj,~)
            % returns a measurement estimate given the current noise free position
            % 
            cameraMeasurement = obj.cameraMeasurement;            
        end
        
        function obj = reset(obj)
            % re-init the ids of the visible satellites
        end
        
        function obj = setState(obj,~)
            % re-initialise the state to a new value
        end
        
        function uv = cam_prj(t, R ,point)
            % world frame to camera frame
            p3 = obj.R*R*(point - t);
   
            % return an empty point if the 
            % camera does not point to the 3D point
            if(p3(3)<0)
                uv=[];
                return;
            end

            % pinhole projection
            p2 = p3(1:2)./p3(3);

            % intrinsic
            uv = p2.*obj.f + obj.c;

            % return an empty point if the 
            % camera reprojected point is 
            % outside the sensor area
            % for simplicity we assume the principal point
            % to be at the center of the sensor, i.e. a valid
            % pixel point p has coordinates  0<uv_p<2*f
            if( uv(1)<0 || uv(1)> 2*obj.c(1) || uv(2)<0 || uv(2)> 2*obj.c(2) )
                uv=[];
                return;
            end            
        end
        
        function pp = z0intersect(p,t)
            % compute intersection with ground z=0
            pp(1,1)=(p(1)-t(1))*((z-t(3))/(p(3)-t(3)))+t(1);
            pp(1,2)=(p(2)-t(2))*((z-t(3))/(p(3)-t(3)))+t(2);
            pp(1,3)=0;
        end   
        
        function updateGraphics(obj,X)
            
            t = X(1:3);
            R = angle2dcm(X(4),X(5),X(6),'ZYX'); 
            
           % points in front of the camera to
% display field of view, the distance chosen
% is arbitrary 
s=[  obj.c(1)  obj.c(1) -obj.c(1) -obj.c(1);
     obj.c(2) -obj.c(2)  obj.c(2) -obj.c(2);
     obj.f(1)  obj.f(1)  obj.f(1)  obj.f(1)]./1000;

% bring the chosen toint to world coords
ss = obj.R'*s;
ss = ss+repmat(t,1,4);

% compute intersection point of the camera field
% of view with z=0
gp1 = obj.z0intersect(ss(:,1),t);
gp2 = obj.z0intersect(ss(:,2),t);
gp3 = obj.z0intersect(ss(:,3),t);
gp4 = obj.z0intersect(ss(:,4),t);

% sketch of the camera
plot3([t(1),ss(1,1)],[t(2),ss(2,1)],[t(3),ss(3,1)],'-r');
plot3([t(1),ss(1,2)],[t(2),ss(2,2)],[t(3),ss(3,2)],'-r');
plot3([t(1),ss(1,3)],[t(2),ss(2,3)],[t(3),ss(3,3)],'-r');
plot3([t(1),ss(1,4)],[t(2),ss(2,4)],[t(3),ss(3,4)],'-r');

plot3([ss(1,1),ss(1,2)],[ss(2,1),ss(2,2)],[ss(3,1),ss(3,2)],'-r');
plot3([ss(1,2),ss(1,4)],[ss(2,2),ss(2,4)],[ss(3,2),ss(3,4)],'-r');
plot3([ss(1,4),ss(1,3)],[ss(2,4),ss(2,3)],[ss(3,4),ss(3,3)],'-r');
plot3([ss(1,3),ss(1,1)],[ss(2,3),ss(2,1)],[ss(3,3),ss(3,1)],'-r');

% camera intersection with the z=0 plane
plot3([t(1),gp1(1)],[t(2),gp1(2)],[t(3),gp1(3)],'-g');
plot3([t(1),gp2(1)],[t(2),gp2(2)],[t(3),gp2(3)],'-g');
plot3([t(1),gp3(1)],[t(2),gp3(2)],[t(3),gp3(3)],'-g');
plot3([t(1),gp4(1)],[t(2),gp4(2)],[t(3),gp4(3)],'-g');

plot3([gp1(1),gp2(1)],[gp1(2),gp2(2)],[gp1(3),gp2(3)],'-g');
plot3([gp2(1),gp4(1)],[gp2(2),gp4(2)],[gp2(3),gp4(3)],'-g');
plot3([gp4(1),gp3(1)],[gp4(2),gp3(2)],[gp4(3),gp3(3)],'-g');
plot3([gp3(1),gp1(1)],[gp3(2),gp1(2)],[gp3(3),gp1(3)],'-g');
            
            
        end    
    end   
        
    methods (Sealed,Access=protected)
        
        function obj=update(obj,X)
            % generates a new noise sample and computes a position estimate
            % The method converts the current noiseless receiver position X(1:3), to ECEF
            
            obj.simState.task;
                        
        end
    end
end
