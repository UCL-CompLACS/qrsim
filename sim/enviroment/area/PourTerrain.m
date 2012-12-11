classdef PourTerrain < handle
    % very simple class that implements a grid in which each cell stores the terrain class 
    %
    % PourTerrain methods:
    %   reset()            - generates a new map
    %   getMap()           - returns the map, each cell in the matrix is the class of the corresponding 1mx1m ground patch
    %   getMapSize()       - returns the map size
    %   getClass(points)   - returns the terrain class at each point 
            
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
            % constructs the object
            %
            % Example:
            %
            %   obj=PourTerrain(objparams)
            %               objparams.classpercentages - array of percentages for each of the classes of terrain
            %          
            
            assert(isfield(objparams,'classpercentages'),'pourterrain:noclasspercentages',...
                'If using a terrain of type PourTerrain, the config file must define the array classpercentages'); 

            assert(sum(objparams.classpercentages)<1,'pourterrain:badclasspercentages',...
                'the sum of the terrain classpercentages parameters must be <1 since they are probabilities');
            
            obj.p=objparams.classpercentages;
            obj.simState = objparams.state;            
            obj.prngId = obj.simState.numRStreams+1;
            obj.simState.numRStreams = obj.simState.numRStreams + 1;
            obj.limits = objparams.limits;
            obj.nr = ceil(objparams.limits(2)-objparams.limits(1));
            obj.nc = ceil(objparams.limits(4)-objparams.limits(3));             
        end
        
        function map = getMap(obj)
            % returns the map, each cell in the matrix is the class of the
            % corresponding 1mx1m ground patch
            map = obj.map;
        end
        
        function [nr nc] = getMapSize(obj)
            % returns the map size
            nr = obj.nr;
            nc = obj.nc;            
        end
        
        function obj = reset(obj)
            % generates a new map
            % 1mx1m cells  
            rnd = rand(obj.simState.rStreams{obj.prngId},obj.nr*obj.nc*length(obj.p),1);  
            obj.map = pourMap(obj.nr,obj.nc,obj.p,rnd);            
        end
        
        function tclass = getClass(obj,points)
            % returns the terrain class at each point 
            
            points(1,points(1,:)<obj.limits(1)) = obj.limits(1)+1e-15;
            points(1,points(1,:)>obj.limits(2)) = obj.limits(2)-1e-15;           
            points(2,points(2,:)<obj.limits(3)) = obj.limits(3)+1e-15;
            points(2,points(2,:)>obj.limits(4)) = obj.limits(4)-1e-15;                         
            tclass = obj.map( ceil(points(1,:)-obj.limits(1))' + size(obj.map,1)*(ceil(points(2,:)-obj.limits(3))'-1));            
        end
    end    
end