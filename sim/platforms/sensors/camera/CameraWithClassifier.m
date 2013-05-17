classdef CameraWithClassifier < Sensor
    % Class that simulates a camera with a person classifier.
    % Given the current position of the helicopter and of a person in the
    % environment we compute the camera view and use the observation model
    % to generate the likelihood ratio produced by the classifier
    %
    % CameraWithClassifier Methods:
    %    CameraWithClassifier(objparams)    - constructor
    %    getMeasurement(X)          - return log likelihoood difference
    %    update(X)                  - generates a new noise sample
    %    setState(X)                - nothing
    %    reset()                    - nothing
    %    updateGraphics(X)          - update the camera graphics given the current state
    %
    properties (Access=public)
        R;                   % rotation from platform to camera frame
        f;                   % focal length
        c;                   % principal point
        graphics;            % handle to graphic object
        cId;                 % camera ID
        obsModel;            % handle to observation model
        llkd;                % log likelihood difference
        wg;                  % ground patches
        cg;                  % ground centers
        gridDims;            % ground grid dimensions
        pg;                  % person position on the ground
        displayObservations; % dispaly observation flag
    end
    
    methods (Sealed,Access=public)
        function obj=CameraWithClassifier(objparams)
            % constructs the object.
            % Perspective projection and coordinat transformations are set
            % up given the task parameters
            %
            % Example:
            %
            %   obj=CameraWithClassifier(objparams)
            %                objparams.dt - timestep of this object
            %                objparams.on - 1 if the object is active
            %                objparams.f - focal length
            %                objparams.c - principal point
            %                objparams.r - rotation between camera and body in Euler angles
            %                objparams.displayobservations - if 1 displays a patch with colors
            %                                                based on the log likelihood difference
            %                objparams.graphics.type - graphics object type
            %                objparams.obsmodeltype - observation model type
            %
            obj=obj@Sensor(objparams);
            
            assert(isfield(objparams,'f'),'camerawithclassifier:nof','the platform config must define the camera.f parameters');
            obj.f = objparams.f;
            assert(isfield(objparams,'c'),'camerawithclassifier:noc','the platform config must define the camera.c parameters');
            obj.c = objparams.c;
            assert(isfield(objparams,'r'),'camerawithclassifier:nor','the platform config must define the camera.r parameters');
            obj.R =  angleToDcm(objparams.r(3),objparams.r(2),objparams.r(1),'ZYX');
            
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
            
            assert(isfield(objparams,'obsmodeltype'),'camerawithclassifier:noobsmodeltype','the platform config must define the camera.obsmodeltype parameter');
            
            obsmodelparams.prngId = obj.simState.numRStreams+1;
            obj.simState.numRStreams = obj.simState.numRStreams + 1;
            obsmodelparams.psize = obj.simState.environment.area.getPersonSize();
            obsmodelparams.f = objparams.f;
            obsmodelparams.c = objparams.c;
            obsmodelparams.simState = obj.simState;
            obj.obsModel = feval(objparams.obsmodeltype, obsmodelparams);
        end
        
        function obj = reset(obj)
            % clear data structures and intialize observation model
            obj.obsModel.reset();
            obj.llkd = [];
            obj.wg = [];
            obj.gridDims = zeros(1,2);
            obj.cg = [];
            obj.bootstrapped = obj.bootstrapped +1;
        end
        
        function obj = setState(obj,~)
            % no state to be set
            obj.bootstrapped = 0;
        end
                
        function obj = updateGraphics(obj,X)
            % update the camera related graphics
            obj.graphics.update(X,obj.R,obj.f,obj.c,obj.llkd,obj.cg,obj.gridDims);
        end
                
        function m = getMeasurement(obj,~)
            % given a current state of the system
            % returns the patches on the ground visible by the camera
            % and the associated likelihood ratios computed by the
            % classifier.
            %
            % Note:
            % the corner points of the ground patches are layed out in a regular
            % gridDims(1) x gridDims(2) grid pattern, we return them stored in a
            % 3*N matrix (i.e. each point has x;y;z coordinates) obtained
            % scanning the grid left to right and top to bottom.
            % this means that the 4 cornes of window i,j
            % are wg(:,(i-1)*(gridDims(1)+1)+j+[0,1,gridDims(1)+1,gridDims(1)+2])
            m = CameraObservation();
            m.llkd = obj.llkd;
            m.wg = obj.wg;
            m.gridDims = obj.gridDims;
        end
    end
    
    methods (Sealed,Access=private)
        
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
        
        function points = inv_cam_prjZ0(obj, tp, Rp ,uvs)
            % project points from world coordinate to the camera frame.
            n = size(uvs,2);
            points = zeros(3,n);
            for i=1:n,
                points(:,i) = inv_cam_prjZ0(tp,Rp,uvs(:,i), obj.c , obj.f, obj.R);
            end
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
            
            fcg = obj.inv_cam_prjZ0(tp,Rp,obj.c(:));
            
            %set(0,'CurrentFigure',obj.simState.display3d.figure)
            %plot3(fcg(1),fcg(2),fcg(3),'m+');
            
            % get real persons
            obj.pg = obj.simState.environment.area.getPersons();
            
            hpsz = 0.5*obj.simState.environment.area.getPersonSize();
            bb = [  hpsz hpsz -hpsz -hpsz;
                -hpsz hpsz -hpsz  hpsz];
            
            bbg = [bb(1,:)+fcg(1);
                bb(2,:)+fcg(2);
                zeros(1,4)];
            
            bbf = obj.cam_prj(tp, Rp ,bbg);
            % very rough width of a person
            if(any(isempty(bbg)))
                % we are so close that a person is larger than the frame
                sz = obj.c(1)+obj.c(2);
                sigmaf = 2*obj.c(1)*2*obj.c(2);
            else
                sigmaf = obj.area(cell2mat(bbf));
                sz = sqrt(sigmaf);
            end
            
            % given the mean of the two sides of the reprojected patch,
            % define a grid of windows over the frame,
            % windows wf, centers cf
            nf = round((2*obj.c(:))./sz);
            obj.gridDims = nf;
            n = nf(1)*nf(2);
            df = floor((2*obj.c(:))./nf);
            offf = floor(rem(2*obj.c(:),df)./2);
            
            %%%%%
            %f10 = figure(10);
            %hold on;
            %axis([0 2*obj.c(1) 0 2*obj.c(2)]);
            %set(gca,'YDir','rev');
            %%%%%
            
            % we store windows corners column wise, top to bottom
            % and left to right, this means that the cornes of the
            % window i,j are wf(:,(j-1)*(nf(2)+1)+i+[0,1,nf(2)+1,nf(2)+2])
            % similarly the centers of window i,j is wf(:,(j-1)*nf(2)+i))
            wf = zeros(2,(nf(1)+1)*(nf(2)+1));
            cf = zeros(2,n);
            for j=1:nf(1)+1,
                for i=1:nf(2)+1,
                    wf(:,(j-1)*(nf(2)+1)+i) = offf + [(j-1)*df(1);(i-1)*df(2)];
                    %idx = (j-1)*(nf(2)+1)+i
                    %wf(:,idx)
                    %plot(wf(1,idx),wf(2,idx),'+');
                end
            end
            
            for j=1:nf(1),
                for i=1:nf(2),
                    cf(:,(j-1)*nf(2)+i) = offf+df./2+[(j-1)*df(1);(i-1)*df(2)];
                    %idx = (j-1)*nf(1)+i
                    %plot(cf(1,idx),cf(2,idx),'*r');
                end
            end
            
            %%%%%%
            %hwf= plot(wf(1,:),wf(2,:),'+');
            %hcf= plot(cf(1,:),cf(2,:),'.r');
            %%%%%%
            
            % grounds patches W and ground centers Cw
            % they obviously are layed out as the one in the frame
            obj.wg = obj.inv_cam_prjZ0(tp, Rp ,wf);
            obj.cg = obj.inv_cam_prjZ0(tp, Rp ,cf);
            
            %%%%%%
            %set(0,'CurrentFigure',obj.simState.display3d.figure);
            %hcg = plot3(obj.cg(1,:),obj.cg(2,:),obj.cg(3,:),'*r');
            %hwg = plot3(obj.wg(1,:),obj.wg(2,:),obj.wg(3,:),'+y');
            %%%%
            
            % compute the terrain class for each patch center
            tclass = obj.simState.environment.area.getTerrainClass(obj.cg);
            
            pcf=[]; %person centers
            sigma=[]; % person's area
            inview = zeros(1,n);
            k = 0;
            for i=1:length(obj.pg),
                % reproject center to current frame
                picf = cell2mat(obj.cam_prj(tp, Rp ,obj.pg{i}.center));
                % if visible, compute sigma, d, alpha, beta and
                % indicator variable inview
                if(~isempty(picf))
                    pcf=[pcf,picf];%#ok<AGROW>
                    k = k+1;
                    
                    pibbfc = obj.cam_prj(tp, Rp ,obj.pg{i}.bb);
                    pok = logical(cellfun(@(x) size(x,2),pibbfc));
                    pibbf = cell2mat(pibbfc(pok));
                    npvalid = size(pibbf,2);
                    if(npvalid==4)
                        % compute area properly
                        sigma = [sigma,obj.area(pibbf)];%#ok<AGROW>
                    else
                        % not completely in view, we make things up
                        % assuming the patch is square
                        tmp = pibbf-repmat(picf,1,npvalid);
                        halfDiag = mean(sqrt(diag(tmp'*tmp)));
                        sigma = [sigma,(sqrt(2)*halfDiag)^2]; %#ok<AGROW>
                    end
                    
                    % we use center corners and a few other mid points to
                    % work out what windows can see this person
                    pif = [picf,pibbf];
                    if(pok(4)&&pok(3)), pif = [pif,(pibbfc{4}+pibbfc{3}+picf)./3]; end %#ok<AGROW>
                    if(pok(2)&&pok(1)), pif = [pif,(pibbfc{2}+pibbfc{1}+picf)./3]; end %#ok<AGROW>
                    if(pok(3)&&pok(1)), pif = [pif,(pibbfc{3}+pibbfc{1}+picf)./3]; end %#ok<AGROW>
                    if(pok(4)&&pok(2)), pif = [pif,(pibbfc{4}+pibbfc{2}+picf)./3]; end %#ok<AGROW>
                    
                    %%%%%%
                    %figure(10);
                    %hpif=plot(pif(1,:),pif(2,:),'.g');
                    %%%%%%
                    
                    for j=1:size(pif,2)
                        % work out to what window point j belongs
                        idx = ceil((pif(:,j)-offf)./df);
                        % due to offf things can still be in frame without
                        % being on a border cell, we nudge those guys back in...
                        idx(idx==0)=1;
                        idx(idx(1)>nf(1))=nf(1);
                        idx(idx(2)>nf(2))=nf(2);
                        
                        lidx = (idx(1)-1)*nf(2)+idx(2);
                        
                        % if this there is already a person for this window
                        % overwrite it only if the current is closer to the
                        % center
                        curpid = inview(lidx);
                        
                        if((curpid==0) || (curpid~=0 && curpid~=k && ...
                                (norm(cf(:,lidx)-pcf(:,k))<norm(cf(:,lidx)-pcf(:,curpid)))))
                            inview(lidx) = k;
                        end
                        %plot(cf(1,lidx),cf(2,lidx),'*k');
                        %plot(pif(1,j),pif(2,j),'.k');
                    end
                    %%%%%%
                    %delete(hpif);
                    %%%%%%
                end
                
            end
            
            % build cell array with a vector for each wi, contanining
            % the input variables to the GPs, they would be
            % [px,py,r,tclass,d,sigma,inc,sazi,cazi]  if person is visible
            % [px,py,r,tclass]  if person is not visible
            xstar = cell(n,1);
            xqueryp = zeros(n,9);
            xqueryn = zeros(n,4);
            
            which = zeros(n,1);
            % i runs through all the windows in the current frame
            for i=1:length(inview)
                % work out the position of the camera center
                % in spherical coords wrt a NED frame located
                % at the center of the ground patch
                
                % ray from camera center to ground patch center
                tc = tp - obj.cg(:,i);
                
                % radius in spherical coords
                r = norm(tc);
                
                % inclination
                inc = acos(-tc(3)./r);
                
                % azimuth express as it sin and cos to get
                % around wrapping problems
                sazi = tc(2)./norm(tc(1:2));
                cazi = tc(1)./norm(tc(1:2));
                
                % we approximate the area that a person placed
                % at the patch center would have as the area it has for the
                % patch at the center of the frame
                
                xqueryp(i,:) = [obj.cg(1:2,i)' r tclass(i) 0 sigmaf inc sazi cazi];
                xqueryn(i,:) = [obj.cg(1:2,i)' r tclass(i)];
                
                if(inview(i)~=0)
                    % one person is visible
                    
                    % distance in pixel coords
                    d = norm(cf(:,i)-pcf(:,inview(i)));
                    
                    xstar{i} = [obj.cg(1:2,i)' r tclass(i) d sigma(inview(i)) inc sazi cazi];
                    which(i) = 1;
                else
                    % no person is visible
                    xstar{i} = [obj.cg(1:2,i)' r tclass(i)];
                end
            end
            
            %%%%%
            %delete(hcg);
            %delete(hwg);
            %delete(hcf);
            %delete(hwf);
            %%%%%
            
            % pass the input to the GP models to obtain classifiers scores
            ystar = obj.obsModel.sample(which, xstar, fcg(1:2)');
            
            % compute likelihood ratio
            obj.llkd =  obj.obsModel.computeLogLikelihoodDifference(xqueryp, xqueryn, fcg(1:2)', ystar);
            
            % update models
            obj.obsModel.updatePosterior();
        end
    end
end
