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
        graphics;
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
            obj.R =  angle2dcm(objparams.r(3),objparams.r(2),objparams.r(1),'ZYX');
            
            if(objparams.graphics.on)
                assert(isfield(objparams.graphics,'type'),'camerawithclassifier:nographicstype',...
                    'the platform config file must define a graphics.type');
                objparams.graphics.state = objparams.state;
                obj.graphics=feval(objparams.graphics.type,objparams.graphics);
            end
        end
        
        function cameraMeasurement = getMeasurement(obj,~)
            % returns a measurement estimate given the current noise free position
            %
            cameraMeasurement = obj.cameraMeasurements;
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
        
        function obj = updateGraphics(obj,X)
            obj.graphics.update(X,obj.R,obj.f,obj.c);
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
