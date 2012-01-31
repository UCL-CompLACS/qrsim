classdef Wind<Steppable
    % Class for an inactive wind field.
    %
    % Wind Methods:
    %    Wind(objparams)            - constructs the object an sets its main fields
    %    getLinear(state)           - always returns zero
    %    getRotational(state)       - always returns zero
    %    update([])                 - no computation
    %
    
    methods 
        function obj = Wind(objparams)
            % constructs the object 
            % This object is created when wind is not active
            %
            % Example:
            % 
            %   obj=WindConstMean(objparams)
            %                objparams.on - 0 to have this type of object
            %          
            obj=obj@Steppable(objparams);
                
        end
  
        function v = getLinear(obj,~)
            % returns always zero.
            %
            % Example:
            %
            %   v = obj.getLinear(state)  
            %           state - 13 by 1 vector platform state
            %           v - zeros 3 by 1 vector
            %
            v = zeros(3,1);
        end
        
        function v = getRotational(~,~)
            % returns always zero.
            %
            % Example:
            %
            %   v = obj.getRotational(state)  
            %           state - 13 by 1 vector platform state
            %           v - zeros 3 by 1 vector
            %
            v=zeros(3,1);
        end
    end
    
    methods (Access=protected)
        function obj = update(obj, ~)
            % no updates are carries out.
        end
    end
end

