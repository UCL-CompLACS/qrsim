classdef PourTerrain < handle
    % very simple model that implements a grid to store the terrain class 
    
    properties (Access=private)
        map; 
        prngId; 
        simState;
        nr;
        nc;
        limits;
        p; % array of percentage of each terrain class, note that 1-sum(p)
           % will be the percentage of the class 0
    end
    
    methods (Access=public)
        function obj = PourTerrain(objparams)            
            assert(isfield(objparams,'p'),'pourterrain:nop',...
                'If using a terrain of type PourTerrain, the config file must define the array p');            
            obj.simState = objparams.state;            
            obj.prngId = obj.simState.numRStreams+1;
            obj.simState.numRStreams = obj.simState.numRStreams + 1;
            obj.limits = objparams.limits;
            obj.nr = ceil(objparams.limits(2)-objparams.limits(1));
            obj.nc = ceil(objparams.limits(4)-objparams.limits(3));             
        end
        
        function map = getMap(obj)
            % return the map, each cell in the matrix is the class of the
            % corresponding 1mx1m ground patch
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