classdef Platform<handle
    % Abstract class for a generic sensor.
    % This is a simple wrapper, it does not include any code, its only purpouse is to
    % allow for runtime type checking.
    %
    % Platform Methods:
    %    Platform(objparams)      - constructs the object, to be called only from derived
    %                             subclasses.
    %    setState(state)          - sets the platform state to the value passed
    %
    properties
        params   % object initial paramters
    end
    
    methods (Sealed,Access=protected)
        % constructs the object
        %
        % Example:
        %
        %   obj=Platform(objparams)
        %                objparams - object parameters
        %
        % Note:
        % this is an abstract class so this contructor is meant to be
        % called by the subclass
        %
        function obj=Platform(params)
            obj.params = params;
        end
    end
    
    methods (Abstract)        
        setState(state);
        % sets the platform state to the value passed             
    end
end