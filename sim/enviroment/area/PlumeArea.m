classdef PlumeArea<Area
    % Defines a simple box shaped area in which is present a plume
    %
    % PlumeArea Methods:
    %    PlumeArea(objparams)           - constructs the object
    %    reset()                        - does nothing
    %    getOriginUTMCoords()           - returns origin
    %    getLimits()                    - returns limits
    %    isGraphicsOn()                 - returns true if there is a graphics objec associate with the area
    %    getSamples(positions)          - returns concentration at positions
    %    getLocations()                 - returns array of locations at which the prediction must be made
    %    getSamplesPerLocation()        - returns the number of samples to be returned for each of the locations
    %
    properties (Access=protected)  
        cepsilon;
        locations;
        referenceSamples;
        numRefLocations;
        numSamplesPerLocation;
        sources;
        numSources;
    end
    
    methods (Sealed,Access=public)
        function obj = PlumeArea(objparams)
            % constructs the object
            %
            % Example:
            %
            %   obj=PlumeArea(objparams)
            %               objparams.limits - x,y,z limits of the area 
            %               objparams.originutmcoords - structure containing the origin in utm coord
            %               objparams.graphics.type - class type for the graphics object 
            %                                         (only needed if the 3D display is active)
            %               objparams.state - handle to the simulator state
            %               objparams.numreflocations - number of reference locations in space used for reward computation
           
            obj=obj@Area(objparams);
            assert(isfield(objparams,'numreflocations'),'plumearea:nonumreflocations',...
                'If using a PlumeArea, the task must define the parameter numreflocations');
            obj.numRefLocations = objparams.numreflocations;            
        end         
        
        function locations = getLocations(obj)
            % returns array of locations at which the prediction
            % must be made
            locations = obj.locations;
        end
        
        function spl = getSamplesPerLocation(obj)
            % return the number of samples to be returned for each of the
            % locations
            spl = obj.numSamplesPerLocation;
        end
        
        function rs = getReferenceSamples(obj)
            % returns a set of samples from the model used by the simulator
            % i.e. correct samples. This is used only for debugging
            rs = obj.referenceSamples;
        end
        
        function sources = getSources(obj)
            % returns the position of the sources
            % this is used only for debugging
            sources = obj.sources;
        end
    end   
    
    methods (Abstract,Access=public)            
        samples = getSamples(obj,positions)
        % returns concentration at the specified positions
    end
    
    methods (Abstract,Access=protected)
        obj=init(obj)
        % perform initialization 
    end
end
