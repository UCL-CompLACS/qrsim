classdef GaussianPlumeArea<PlumeArea
    % Defines a simple box shaped area in which is present a plume with concentration described by a 3d Gaussian
    %
    % GaussianPlumeArea Methods:
    %    GaussianPlumeArea(objparams)   - constructs the object
    %    reset()                        - does nothing
    %    getOriginUTMCoords()           - returns origin
    %    getLimits()                    - returns limits
    %    isGraphicsOn()                 - returns true if there is a graphics objec associate with the area
    %           
    
    properties (Access=public)
       sigma;
       invSigma;
       detSigma;
       source;
       angle;
       sigmaRange;
       prngId;
    end    
    
    methods (Sealed,Access=public)
        function obj = GaussianPlumeArea(objparams)
            % constructs the object
            %
            % Example:
            %
            %   obj=GaussianPlumeArea(objparams)
            %               objparams.limits - x,y,z limits of the area 
            %               objparams.originutmcoords - structure containing the origin in utm coord
            %               objparams.graphics.type - class type for the graphics object 
            %                                         (only needed if the 3D display is active)
            %               objparams.sourceSigmaRange - min,max values for the width of the Gaussian concentration
            %                                         (with of the concentration along the principal axes is drawn 
            %                                          randomly with uniform probability from the specified range)
            %               objparams.state - handle to the simulator state
            %
            obj=obj@PlumeArea(objparams);
            
            obj.prngId = obj.simState.numRStreams+1;
            obj.simState.numRStreams = obj.simState.numRStreams + 1;
            obj.sigmaRange = objparams.sourceSigmaRange;
            
            if(objparams.graphics.on)
                tmp.limits = objparams.limits;
                tmp.state = objparams.state;
                if(isfield(objparams,'graphics') && isfield(objparams.graphics,'backgroundimage'))
                    tmp.backgroundimage = objparams.graphics.backgroundimage;
                end                
                
                obj.graphics=feval(objparams.graphics.type,tmp);
            end
        end
        
        function obj = reset(obj)
            % redraw a different plume pattern
            obj.init();
            % modify plot
            obj.graphics.update(obj.source,obj.sigma,obj.simState);            
        end
        
        function samples = getSamples(obj,positions)
            % compute the concentration at the requested locations            
            rsource = repmat(obj.source,1,size(positions,2)); 
            samples = (1/((((2*pi)^3)*obj.detSigma)^0.5))*exp(-0.5*dot((positions-rsource),obj.invSigma*(positions-rsource),1));
        end    
    end
    
    methods (Access=protected)
        function obj=init(obj)
            % generate the covariance matrix and the position of the source                       
            
            obj.angle=pi*rand(obj.simState.rStreams{obj.prngId});
            s1 = obj.sigmaRange(1)+rand(obj.simState.rStreams{obj.prngId})*...
                                   (obj.sigmaRange(2)-obj.sigmaRange(1));
            s2 = obj.sigmaRange(1)+rand(obj.simState.rStreams{obj.prngId})*...
                                   (obj.sigmaRange(2)-obj.sigmaRange(1));
            s3 = obj.sigmaRange(1)+rand(obj.simState.rStreams{obj.prngId})*...
                                   (obj.sigmaRange(2)-obj.sigmaRange(1));
            
            s = (angleToDcm(obj.angle,0,0)')*diag([s1,s2,s3]);
            obj.sigma=s*s';
            
            obj.invSigma = inv(obj.sigma);
            obj.detSigma = det(obj.sigma);
            
            obj.source=zeros(3,1);
            obj.source(1)=0.5*(obj.limits(2)+obj.limits(1))+...
                          2*(rand(obj.simState.rStreams{obj.prngId})-0.5)*...
                          0.8*(abs(obj.limits(2)-obj.limits(1))/2);
            obj.source(2)=0.5*(obj.limits(4)+obj.limits(3))+...
                          2*(rand(obj.simState.rStreams{obj.prngId})-0.5)*...
                          0.8*(abs(obj.limits(4)-obj.limits(3))/2);   
            obj.source(3)=0.5*(obj.limits(6)+obj.limits(5))+...
                          2*(rand(obj.simState.rStreams{obj.prngId})-0.5)*...
                          0.8*(abs(obj.limits(6)-obj.limits(5))/2);  
        end
    end    
end
