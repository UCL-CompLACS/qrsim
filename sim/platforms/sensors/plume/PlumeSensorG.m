classdef PlumeSensorG<PlumeSensor
    % Class for a plume sensor the measurement of which are affected by white noise.
    %
    % PlumeSensorG Methods:
    %    PlumeSensorG(objparams)    - constructs the object
    %    getMeasurement(X)          - returns the noisy plume concentration value at the current location
    %    update(X)                  - stores current state
    %    reset()                    - does nothing
    %    setState(X)                - re-initialise the state to a new value
    %
    properties (Access=protected)
        sPrngId;
        SIGMA;
    end
    
    methods (Access=public)
        function obj = PlumeSensorG(objparams)
            % constructs the object
            %
            % Example:
            %
            %   obj=PlumeSensorG(objparams)
            %                objparams.on - 1 to have this type of object
            %                objparams.SIGMA - the standard deviation of the additive Gaussian noise 
            %
            obj = obj@PlumeSensor(objparams);
            
            assert(isfield(objparams,'SIGMA'),'plumesensorg:nosigma',...
                    'for a PlumeSensorG the noise standard deviation SIGMA must be defined');
            obj.SIGMA = objparams.SIGMA;
            obj.sPrngId = obj.simState.numRStreams+1;
            obj.simState.numRStreams = obj.simState.numRStreams + 1;            
        end
        
        function conc = getMeasurement(obj,~)
            % returns the noisy concentration estimate
            %
            % Example:
            %
            %   conc = obj.getMeasurement(~)
            %       conc  - plume concentration
            %

            conc = obj.estimatedConc;
        end
        
        function obj = reset(obj)
           % does nothing            
        end

    end
    
    methods (Access=protected)        
        function obj=update(obj,X)
            % simply stores the concentration to be used by getMeasurement()
            %
            % Note: this method is called by step() if the time is a multiple
            % of this object dt, therefore it should not be called directly.
                        
            obj.estimatedConc = obj.simState.environment.area.getSamples(X(1:3));
            obj.estimatedConc = obj.estimatedConc + obj.SIGMA*randn(obj.simState.rStreams{obj.sPrngId},1,1);
        end
    end
end

