classdef GaussianDispersionPlumeAreaForTesting<GaussianDispersionPlumeArea
    % extends GaussianDispersionPlumeArea with function useful for testing
 
    properties
       pos; 
    end
    
    methods (Sealed,Access=public)
        function obj = GaussianDispersionPlumeAreaForTesting(objparams)
            % constructs the object
            obj=obj@GaussianDispersionPlumeArea(objparams);            
        end
        
        function obj = setPos(obj,pos)
            obj.pos = pos;
        end
        
        function c = getSamplesGivenParameters(obj,x0,pos)
            % returns the concentration at the requested locations
            
            Qs = x0(1);
            a = x0(2);
            b = x0(3);
            
            n = size(pos,2);
            c = zeros(1,n);
            
            for i=1:obj.numSources,
                % transform location to source centered wind frame
                p = [obj.C*(pos(1:2,:)-repmat(obj.sources(1:2,i),1,n));...
                    pos(3,:)-obj.sources(3,i);...
                    pos(3,:)+obj.sources(3,i)];
                
                den = (2*a*p(1,:).^b);
                
                ci = (Qs./(pi*obj.u*den)).*...
                    exp(-((p(2,:).^2)./den)).*...
                    (exp(-((p(3,:).^2)./den))+exp(-((p(4,:).^2)./den)));
                
                % the model is not valid for negative x...
                ci(p(1,:)<0)=0;
                c = c+ci;
            end
        end
        
        function e = diff(obj,x0)
            t = obj.getSamples(obj.pos);
            g = obj.getSamplesGivenParameters(x0,obj.pos);
            
            e = sum((t-g).^2);
        end
        
        function x = optimize(obj,x0)            
            x = fminsearch(@obj.diff,x0);
        end
    end
end
