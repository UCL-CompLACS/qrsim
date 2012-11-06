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
        graphics;
        cId;
        obsModel;
        lkr;
        wg;
        gridSize;
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
            
            prngId = obj.simState.numRStreams+1;
            obj.simState.numRStreams = obj.simState.numRStreams + 1;
            
            obj.obsModel = GPObsModel(obj.simState, prngId);
        end
        
        function obj = reset(obj)
            % nothing to be reinitialized
            obj.obsModel.reset(); 
            obj.lkr=[];
            obj.wg=[];
            obj.gridSize=[];
        end
        
        function obj = setState(obj,~)
            % this object has no state
        end
        
        function obj = updateGraphics(obj,X)
            % update the camera related graphics
            obj.graphics.update(X,obj.R,obj.f,obj.c);
        end
        
        function uvs = cam_prj(obj, tp, Rp ,points)
            % project points from world coordinate to the camera frame.
            % note we return a cell array with an empty column if
            % the point is not in frame
            n = size(points,2);
            uvs = cell(1,n);
            for i=1:n,
                uvs{i} = cam_prj(tp, Rp ,points(:,i), obj.c , obj.f, obj.R);
            end
        end
        
        function uvs = inv_cam_prjZ0(obj, tp, Rp ,uvs)
            % project points from world coordinate to the camera frame.
            n = size(uvs,2);
            points = zeros(3,n);
            for i=1:n,
                points(:,i) = inv_cam_prjZ0(Rp,tp,uvs(:,i), obj.c , obj.f, obj.R);
            end
        end      
        
        function [wg,gridSize,lkr] = getMeasurement(obj,~)
            % given a current state of the system 
            % returns the patches on the ground visible by the camera
            % and the associated likelihood ratios computed by the
            % classifier.
            %
            % Note:
            % the corner points of the ground patches are layed out in a regular
            % gridSize(1) x gridSize(2) grid pattern, we return them stored in a
            % 3*N matrix obtained scanning the grid left to right and top to bottom.
            % this means that the 4 cornes of window i,j
            % are wg(:,(i-1)*(nf(1)+1)+j+[0,1,nf(1)+1,nf(1)+2])
            
            gridSize = obj.gridSize;
            lkr = obj.lkr;
            wg = obj.wg;
        end
    end
    
    methods (Static)
        function a=area(bb)
            % compute area of a convex quadrilateral.
            ac = bb(:,1)-bb(:,4);
            bd = bb(:,2)-bb(:,3);
            a = 0.5*abs(ac(1)*bd(2)-ac(2)*bd(1));
        end    
    end
    
    methods (Sealed,Access=protected)
        function obj=update(obj,X)
            % get the person scale by projecting a "fake" person sitting
            % on the ground where a ray on the camera center hits
            tp = X(1:3);
            Rp = dcm(X);
            
            cg = obj.inv_cam_prjZ0(Rp,tp,obj.c(:));
            sz = obj.simState.environment.area.getPersonSize();
            bbg = [cg(1)+sz cg(1)+sz cg(1)-sz cg(1)-sz;
                   cg(2)-sz cg(2)+sz cg(2)-sz cg(2)+sz;
                         0        0        0        0];
                     
            bbf = obj.cam_prj(tp, Rp ,bbg); 
            % very rough width of a person        
            sz = sqrt(obj.area(bbf));
            
            % given the mean of the two sides of the reprojected patch,
            % define a grid of windows over the frame, 
            % windows wi, centers cwi 
            nf = round((2*obj.c(:))./sz);
            obj.gridSize = nf;
            n = Nf(1)*nf(2);
            df = floor((2*obj.c(:))./nf);
            offf = floor(rem(2*obj.c(:),df)./2);
            
            % we store windows corners row wise, left to right 
            % and top to bottom, this means that the cornes of the
            % window i,j are wf(:,(i-1)*(nf(1)+1)+j+[0,1,nf(1)+1,nf(1)+2])
            % similarly the centers of window i,j is wf(:,(i-1)*nf(1)+j))            
            wf = zeros(2,(nf(1)+1)*(nf(2)+1));
            cf = zeros(2,n);
            for j=1:nf(2)+1,
                for i=1:nf(1)+1,
                    wf(:,i+(j-1)*(nf(1)+1)) = offf+ [(i-1)*df(1);(j-1)*df(2)];
                end
            end
            
            for j=1:nf(2),
                for i=1:nf(1),
                  cf(:,i+(j-1)*nf(1)) = offf+df./2+[(i-1)*df(1);(j-1)*df(2)];
                end
            end
            
            % grounds patches W and ground centers Cw
            % they obviously are layed out as the one in the frame
            obj.wg = obj.inv_cam_prjZ0(tp, Rp ,wf);
            cg = obj.inv_cam_prjZ0(tp, Rp ,cf); 
            
            % compute the terrain class for each patch center
            tclass = obj.simState.area.getTerrainClass(cg);
            
            % get real persons
            pg = obj.simState.environment.area.getPersons();
            
            pcf=[]; %person centers
            pid=[]; %person id
            sigma=[]; % person's area
            alphaBeta = []; % sperical coord of camera in target frame 
            delta = cell(1,n);
            for i=1:length(pg),                
                % reproject center to current frame
                picf = obj.cam_prj(tp, Rp ,pg{i}.center);
                % if visible, compute sigma, d, alpha, beta and 
                % indicator variable delta 
                if(~isempty(picf))
                    pcf=[pcf,picf];%#ok<AGROW>
                    pid=[pid,i]; %#ok<AGROW>
                    pibbf = obj.cam_prj(tp, Rp ,pg{i}.bb);
                    sigma = [sigma,obj.area(pibbf)];%#ok<AGROW>
                    
                    % we use center corners and a few other mid points to
                    % work out what windows can see this person                    
                    pif = [pibbf,picf,...
                        0.25*(pibbf(:,[4,2,3,4])+pibbf(:,[3,1,1,2]))+0.5*repmat(picf,1,4)];
                    for j=1:size(pif,2)
                        % work out to what window point j belongs 
                        idx = floor((pif(:,j)-offf)./df)+[1;1];
                        % add it to the list if not already present
                        if(~any(delta{(idx(1)-1)*nf(1)+idx(2)})==i)
                            delta{(idx(1)-1)*nf(1)+idx(2)}(end+1)=i;
                        end
                    end    
                end
            end
            
            % build cell array with a vector for each wi, contanining
            % the input variables to the GPs, they would be
            % [px,py,pz,tclass,d,sigma,alpha,beta]  if person is visible
            % [px,py,pz,tclass]  if person is not visible
            xstar = cell(1,n);
            which = zeros(1,n);
            for i=1:length(delta)
                if(isempty(delta(i)))
                    % no person is visible
                    xstars(i) =
                else
                    xstars(i) =
                    which(i) = 1;
                end
            end
            
            % pass the input to the GP models to obtain classifiers scores
            ystar = obj.obsModel.sample(which, xstar);
            
            % compute positive and negative query points
            
            % compute likelihood ratio
            obj.lkr =  obj.obsModel.computeLikelihoodRatio(xqueryp, xqueryn, ystar);
            
            % update GP models
            obj.obsModel.updatePosterior();            
        end
    end
end
