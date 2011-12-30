classdef Platform<handle
    % Abstract class for a generic sensor.
    % This is a simple wrapper, it does not include any code, its only purpouse is to
    % allow for runtime type checking.
    %
    % Platform Methods:
    %    Platform(objparams)      - constructs the object, to be called only from derived
    %                             subclasses.
    %
    properties (Access=protected)
        params   % object initial paramters
    end
    
    methods (Sealed,Access=protected)
        function obj=Platform(params)
            obj.params = params;
        end
    end
end