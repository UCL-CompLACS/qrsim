classdef PourTerrain < handle
    % very simple model that implements a grid to store the terrain class
    
    properties 
       p = [0.2 , 0.05]; % 20% clutter, 5% occlusion
    end    
    
    properties (Access=private)
        map;
        prngId;
        simState;
        nr;
        nc;
        limits;
    end
    
    methods (Access=public)
        function obj = PourTerrain(objparams)
            obj.simState = objparams.state;
            
            obj.prngId = obj.simState.numRStreams+1;
            obj.simState.numRStreams = obj.simState.numRStreams + 1;
            obj.limits = objparams.limits;
            obj.nr = ceil(objparams.limits(2)-objparams.limits(1));
            obj.nc = ceil(objparams.limits(4)-objparams.limits(3));  
        end
        
        function map = getMap(obj)
            map = obj.map;
        end
        
        function [nr nc] = getMapSize(obj)
            nr = obj.nr;
            nc = obj.nc;            
        end
        
        function obj = reset(obj)
            % 1mx1m cells  
            rnd = rand(obj.simState.rStreams{obj.prngId},obj.nr*obj.nc*length(obj.p),1);  
            obj.map = pourMap(obj.nr,obj.nc,obj.p,rnd);            
        end
        
        function tclass = getClass(obj,points)
            %if(any(points(1,:)<obj.limits(1))||any(points(2,:)<obj.limits(3))||any(points(1,:)>obj.limits(2))||any(points(2,:)>obj.limits(4)))                
            %    keyboard
            %end
            points(1,points(1,:)<obj.limits(1)) = obj.limits(1)+1e-15;
            points(1,points(1,:)>obj.limits(2)) = obj.limits(2)-1e-15;           
            points(2,points(2,:)<obj.limits(3)) = obj.limits(3)+1e-15;
            points(2,points(2,:)>obj.limits(4)) = obj.limits(4)+1e-15;                         
            tclass = obj.map( ceil(points(1,:)-obj.limits(1))' + size(obj.map,1)*(ceil(points(2,:)-obj.limits(3))'-1));            
        end
    end    
end