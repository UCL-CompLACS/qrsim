classdef SteppablePRNG<Steppable
    % Abstract covenience class for any Steppable objects that includes a random number generator.
    % This extends the functionality of Steppable by hiding the number generator and 
    % its initialization.
    %
    % Steppable Methods:
    %   SteppablePRN(objparams) - constructs the object, and initialises the prng
    %
    properties (Access=protected)
        rStream = RandStream('mt19937ar'); %pseudorandom number generator stream
    end
    
    methods (Sealed)
        function obj=SteppablePRNG(objparams)
            % constructs and sets up the pseudorandom number generator
            % The methods uses objparams.seed to seed random stream or to initialise it
            % randomly if objparams.seed = 0.
            % 
            % Note:
            % this is an abstract class so this contructor is meant to be called by any 
            % subclass.
            %
            obj=obj@Steppable(objparams);
            
            if(objparams.seed~=0)
                reset(obj.rStream,objparams.seed);
            end
        end        
    end   
end

