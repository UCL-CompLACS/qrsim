classdef EnvironmentObject<handle
    % Abstract class for a generic environment object.
    % This is a simple wrapper, it does not include any code, its only purpouse is to
    % allow for runtime type checking.
    %
    % EnvironmentObject Methods:
    %    EnvironmentObject(objparams) -  constructs the object, to be called only from
    %                                    derived subclasses.
    %
    properties
        params   % object initial paramters
    end
    
    methods (Sealed,Access=protected)
        function obj=EnvironmentObject(params)
            % constructs the object
            %
            % Example:
            %
            %   obj=EnvironmentObject(objparams)
            %                objparams - object parameters
            %
            % Note:
            % this is an abstract class so this contructor is meant to be
            % called by the subclass
            %
            obj.params = params;
        end
    end
end