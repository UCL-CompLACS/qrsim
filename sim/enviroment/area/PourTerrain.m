classdef PourTerrain < handle
    % very simple model that implements a grid to store the terrain class
    
    properties 
       nClasses = 2;
    end    
    
    properties (Access=private)
        map;
        prngId;
        simState;
        limits;
    end
    
    methods (Access=public)
        function obj = PourTerrain(objparams)
            obj.simState = objparams.simState;
            obj.limits = objparams.limits;
            
            obj.prngId = obj.simState.numRStreams+1;
            obj.simState.numRStreams = obj.simState.numRStreams + 1;
        end
        
        function obj = reset(obj)
            % 1mx1m cells
            nr = ceil(obj.limits(2)-obj.limits(1));
            nc = ceil(obj.limits(4)-obj.limits(3));    
            rnd = rand(obj.simState.rStreams{obj.prngId},nr*nc*obj.nClasses,1);
            obj.map = pourMap(nr,nc,obj.nClasses,rnd);            
        end
        
        function tclass = getClass(obj,points)
            tclass = obj.map(ceil(points(1,:)')+size(obj.map,1)*(ceil(points(2,:)'-1)));            
        end
    end    
end