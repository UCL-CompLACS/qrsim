classdef PerlinTerrain < handle
    
    properties (Access=private)
        mm;
        prngId;
        simState;
        limits;
    end
    
    methods (Access=public)
        function obj = PerlinTerrain(objparams)
            obj.simState = objparams.simState;
            obj.limits = objparams.limits;
            
            obj.prngId = obj.simState.numRStreams+1;
            obj.simState.numRStreams = obj.simState.numRStreams + 1;
        end
        
        function obj = reset(obj)
            mm1 = obj.perlin(100);
            mm1(mm1>=0)=1;
            mm1(mm1<0)=2;
            
            mm2 = obj.perlin(100);
            mm2(mm2>=0)=3;
            mm2(mm2<0)=5;
            mm = mm1+mm2;
            
            v= zeros(4,2);
            v(1,1) = sum(sum(mm==4));
            v(1,2) = 4;
            v(2,1) = sum(sum(mm==5));
            v(2,2) = 5;
            v(3,1) = sum(sum(mm==6));
            v(3,2) = 6;
            v(4,1) = sum(sum(mm==7));
            v(4,2) = 7;
            
            
            sort(v,2);
            
            mm(mm==v(1,2))=v(4,2);
            v(4,1)=v(1,1)+v(4,1);
            v(1,:)=[];
            
            mm(mm==v(1,2))=3;
            mm(mm==v(2,2))=2;
            mm(mm==v(3,2))=1;
            
            
            pcolor(mm);
            
        end
        
        function s = perlin(obj,m)
            s = zeros(m);    % output image
            w = m;           % width of current layer
            i = 0;           % iterations
            while (w > 3)
                i = i + 1;
                d = interp2(randn(obj.simState.rStreams{obj.prngId},w), i-1, 'spline');
                if(i>5)
                    s = s + i * d(1:m, 1:m);
                end
                w = w - ceil(w/2 - 1);
            end
        end
        
        function tclass = getClass(obj,points)
            
        end
    end    
end