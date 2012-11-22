classdef Wind<Steppable & EnvironmentObject
    % Class for an inactive wind field.
    %
    % Wind Methods:
    %    Wind(objparams)            - constructs the object an sets its main fields
    %    getLinear(X)               - always returns zero
    %    getRotational(X)           - always returns zero
    %    update([])                 - no computation
    %    reset()                    - no action
    %
    
    methods (Sealed,Access=public)
        function obj = Wind(objparams)
            % constructs the object
            % This object is created when wind is not active
            %
            % Example:
            %
            %   obj=WindConstMean(objparams)
            %                objparams.on - 0 to have this type of object
            %                objparams.state - handle to the simulator state
            %                objparams.W6 - velocity at 6m from ground in m/s
                        
            objparams.dt = 3600*objparams.DT; % since this wind is constant
            
            obj=obj@Steppable(objparams);
            obj=obj@EnvironmentObject(objparams);
	
     	    obj.bootstrapped = 0;
        end
    end
    
    methods (Access=public)
        function v = getLinear(~,~)
            % returns always zero.
            %
            % Example:
            %
            %   v = obj.getLinear(X)
            %           X - 13 by 1 vector platform state
            %           v - zeros 3 by 1 vector
            %
            v = zeros(3,1);
        end
        
        function v = getRotational(~,~)
            % returns always zero.
            %
            % Example:
            %
            %   v = obj.getRotational(X)
            %           X - 13 by 1 vector platform state
            %           v - zeros 3 by 1 vector
            %
            v=zeros(3,1);
        end
        
        function obj = reset(obj)
            obj.bootstrapped = 1;
        end
    end
    
    methods (Access=protected)
        function obj = update(obj, ~)
            % no updates are carries out since this object is static.
            %
            % Note:
            %  this method is called automatically by the step() of the Steppable parent
            %  class and should not be called directly.
            %
        end
    end
end

