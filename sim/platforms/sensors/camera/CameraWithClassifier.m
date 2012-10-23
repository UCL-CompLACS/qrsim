classdef CameraWithClassifier < Sensor
    % Class that simulates a camera with a person classifier.
    % Given the current position of the helicopter and of a person in the
    % environment we compute the camera view and use the observation model
    % to generate the likelihood ratio produced by the classifier
    %
    % CameraWithClassifier Methods:
    %    CameraWithClassifier(objparams)    - constructor
    %    getMeasurement(X)          - return
    %    update(X)                  - generates a new noise sample
    %    setState(X)                - nothing
    %    reset()                    - nothing
    %
    
    properties (Access=public)
        R;  % rotation from platform to camera frame
        f;  % focal length
        c;  % principal point
        cameraMeasurements;
        graphics;
        cId;
    end
    
    methods (Sealed,Access=public)
        function obj=CameraWithClassifier(objparams)
            % constructs the object.
            % Perspective projection and coordinat transformations are set
            % up given the task parameters
            %
            % Example:
            %
            %   obj=CameraClassifier(objparams)
            %                objparams.dt - timestep of this object
            %                objparams.on - 1 if the object is active
            %                objparams.f - focal length
            %                objparams.c - principal point
            %                objparams.r - rotation between camera and body in Euler angles
            %
            obj=obj@Sensor(objparams);
            
            assert(isfield(objparams,'f'),'camera:f','the platform config must define the camera.f parameters');
            obj.f = objparams.f;
            assert(isfield(objparams,'c'),'camera:c','the platform config must define the camera.c parameters');
            obj.c = objparams.c;
            assert(isfield(objparams,'r'),'camera:r','the platform config must define the camera.r parameters');
            obj.R =  angle2dcm(objparams.r(3),objparams.r(2),objparams.r(1),'ZYX');
                        
            if(isempty(obj.simState.camerascnt_))
                obj.simState.camerascnt_ = 0;
            end
            obj.simState.camerascnt_ = obj.simState.camerascnt_ + 1;
            obj.cId = obj.simState.camerascnt_;
            
            if(objparams.graphics.on)
                assert(isfield(objparams.graphics,'type'),'camerawithclassifier:nographicstype',...
                    'the platform config file must define a graphics.type');
                objparams.graphics.state = objparams.state;
                objparams.graphics.id = obj.cId;
                obj.graphics=feval(objparams.graphics.type,objparams.graphics);
            end
        end
        
        function cameraMeasurement = getMeasurement(obj,~)
            % returns the current measurement
            cameraMeasurement = obj.cameraMeasurements;
        end
        
        function obj = reset(obj)
            % nothing to be reinitialized
        end
        
        function obj = setState(obj,~)
            % this object has no state
        end
        
        function obj = updateGraphics(obj,X)
            % update the camera related graphics
            obj.graphics.update(X,obj.R,obj.f,obj.c);
        end
        
        function uv = cam_prj(obj, tp, Rp ,point)
            % project points from world coordinate to the camera frame.
            
            uv = cam_prj(tp, Rp ,point, obj.c , obj.f, obj.R);
            
        end
    end
    
    methods (Sealed,Access=protected)
        function obj=update(obj,~)
            % generates a new noise sample and computes a new camera output
            
            %%% TODO
        end
    end
end
