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
        pg;
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
             % get real persons
            obj.pg = obj.simState.environment.area.getPersons();
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
            bb = [  sz sz -sz -sz;
                   -sz sz -sz  sz];
                 
            bbg = [bb(1,:)+cg(1);
                   bb(2,:)+cg(2);
                      zeros(1,4)];
                     
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
            
            pcf=[]; %person centers
            %pid=[]; %person id
            sigma=[]; % person's area 
            inview = zeros(1,n);
            k = 0;
            for i=1:length(obj.pg),                
                % reproject center to current frame
                picf = obj.cam_prj(tp, Rp ,obj.pg{i}.center);
                % if visible, compute sigma, d, alpha, beta and 
                % indicator variable inview 
                if(~isempty(picf))
                    pcf=[pcf,picf];%#ok<AGROW>
                    k = k+1;
                    %pid=[pid,i]; %#ok<AGROW>
                    pibbf = obj.cam_prj(tp, Rp ,obj.pg{i}.bb);
                    sigma = [sigma,obj.area(pibbf)];%#ok<AGROW>
                    
                    % we use center corners and a few other mid points to
                    % work out what windows can see this person                    
                    pif = [pibbf,picf,...
                        0.25*(pibbf(:,[4,2,3,4])+pibbf(:,[3,1,1,2]))+0.5*repmat(picf,1,4)];
                    for j=1:size(pif,2)
                        % work out to what window point j belongs 
                        idx = floor((pif(:,j)-offf)./df)+[1;1];
                        lidx = (idx(1)-1)*nf(1)+idx(2);
                        
                        % if this there is already a person for this window
                        % overwrite it only of the current is closer to the
                        % center
                        curpid = inview(lidx);
                        
                        if((curpid==0) || ...
                           (curpid~=0 && curpid~=k && (norm(cf(:,lidx)-pcf(:,k))<norm(cf(:,lidx)-pcf(:,curpid)))))
                            inview(lidx) = k;                            
                        end
                    end    
                end
            end
            
            % build cell array with a vector for each wi, contanining
            % the input variables to the GPs, they would be
            % [px,py,r,tclass,d,sigma,inc,sazi,cazi]  if person is visible
            % [px,py,r,tclass]  if person is not visible
            xstar = cell(1,n);
            xqueryp = zeros(8,n);
            xqueryn = zeros(4,n);            
           
            which = zeros(1,n);
            % i runs through all the windows in the current frame
            for i=1:length(inview)
                % work out the position of the camera center
                % in spherical coords wrt a NED frame located
                % at the center of the ground patch
                
                % ray from camera center to ground patch center
                tc = tp - cg(:,i);
                
                % radius in spherical coords
                r = norm(tc);
                
                % inclination
                inc = acos(-tc(3)./r);
                
                % azimuth express as it sin and cos to get
                % around wrapping problems
                sazi = tc(2)./norm(tc(1:2));
                cazi = tc(1)./norm(tc(1:2));  
                
                % area that a person placed at the patch center 
                % would have on the frame
                bbg = [bb(1,:)+cg(1,i);
                       bb(2,:)+cg(2,i);
                            zeros(1,4)];
                     
                bbf = obj.cam_prj(tp, Rp ,bbg);      
                sigmaf = obj.area(bbf);
                                
                xqueryp(1:3,i) = [X(1:2);r;tclass(i);0;sigmaf;inc;sazi;cazi];                
                xqueryn(1:3,i) = [X(1:2);r;tclass(i)];
                
                if(inview(i)~=0)
                    % one person is visible
                    
                    % distance in pixel coords
                    d = norm(cf(:,i)-pcf(:,inview(i)));
                    
                    xstar(i) = [X(1:2);r;tclass(i);d;sigma(inview(i));inc;sazi;cazi];
                    which(i) = 1;
                else
                    % no person is visible
                    xstar(i) = [X(1:2);r;tclass(i)];
                end
            end
            
            % pass the input to the GP models to obtain classifiers scores
            ystar = obj.obsModel.sample(which, xstar);
            
            % compute likelihood ratio
            obj.lkr =  obj.obsModel.computeLikelihoodRatio(xqueryp, xqueryn, ystar);
            
            % update GP models
            obj.obsModel.updatePosterior();            
        end
    end
end
