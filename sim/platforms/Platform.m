classdef Platform<handle
    % Abstract class for a generic sensor.
    % This is a simple wrapper, it does not include any code, its only purpouse is to
    % allow for runtime type checking.
    %
    % Platform Methods:
    %    Platform(objparams)      - constructs the object, to be called only from derived
    %                             subclasses.
    %    setX(X)                  - sets the platform state to the value passed
    %  
    
    methods (Abstract)        
        setX(obj,X);
        % sets the platform state to the value passed             
    end   
    
    methods (Access=public)
        function obj = Platform(~)
            
        end        
    end
end