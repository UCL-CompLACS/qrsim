classdef AerodynamicTurbulence<SteppablePRNG
    % Abstract base class for aerodynamic disturbances.
    %
    % AerodynamicTurbulence Methods:
    %   AerodynamicTurbulence(objparams) - constructs the object and calls the SteppablePRNG 
    %                                      constructor
    %   getLinear(state)*                - returns the linear component of the disturbance 
    %                                      (Abstract)
    %   getRotational(state)*            - returns the rotational component of the 
    %                                      disturbance (Abstract)
    %
    %                                    *hyperlink broken because the method is abstract
    %    
    methods
        function obj = AerodynamicTurbulence(objparams)
            % constructs the object and calls the SteppablePRNG constructor
            %
            % Note:
            % this is an abstract class so this contructor is meant to be called by the
            % subclass.
            %
            obj = obj@SteppablePRNG(objparams);
        end
    end
    
    methods (Abstract)
        v = getLinear(obj,state);
        % returns the linear component of the disturbance 
        % Note: this method is subclass specific and must be implemented by any subclass. 
        %
        % Example:
        %
        %   obj.getLinear(state);
        %       state - subclass specific
        %
        
        w = getRotational(obj,state);
        % returns the rotational component of the disturbance 
        % Note: this method is subclass specific and must be implemented by any subclass. 
        %
        % Example:
        %
        %   obj.getRotational(state);
        %       state - subclass specific
        %
    end
    
end

