classdef AerodynamicTurbulence<Steppable
    % Base class for no aerodynamic disturbances
    % (i.e. both linear and rotational contributions are zero)
    %
    % AerodynamicTurbulence Methods:
    %   AerodynamicTurbulence(objparams) - constructs the object
    %   getLinear(state)                 - returns the linear component (always zero)
    %   getRotational(state)             - returns the rotational component   (always zero)
    %   reset()                          - no action
    %   setState()                       - no action
    %
    methods (Sealed,Access=public)
        function obj = AerodynamicTurbulence(objparams)
            % constructs the object and calls the SteppablePRNG constructor
            %
            % Example:
            %
            %   obj=AerodynamicTurbulence(objparams)
            %                objparams.on - 0 to have this type of object
            %
            obj = obj@Steppable(objparams);
        end
    end
    
    methods (Access=public)
        function v = getLinear(~,~)
            % returns the linear component of the disturbance (always zero)
            %
            % Example:
            %
            %   v = obj.getLinear(state);
            %           state - 13 by 1 vector platform state
            %            v - zeros 3 by 1 vector
            %
            v = zeros(3,1);
        end
        
        
        function v = getRotational(~,~)
            % returns the rotational component of the disturbance (always zero)
            %
            % Example:
            %
            %   v = obj.getRotational(state);
            %           state - 13 by 1 vector platform state
            %           v - zeros 3 by 1 vector
            %
            %
            v=zeros(3,1);
        end
        
        function obj = reset(obj)
            % nothing to be done
        end
        
        function obj = setState(obj,~)
            % nothing to be done
            obj.reset();
        end
    end
    
    methods  (Access=protected)
        function obj = update(obj, ~)
            % nothing to be done
            % Note: this method is called by step() if the time is a multiple
            % of this object dt, therefore it should not be called directly.
        end
    end
    
    
    
end

