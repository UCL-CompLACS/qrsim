classdef Wind<Steppable
    % Class for an inactive wind field.
    %
    % Wind Methods:
    %    Wind(objparams)            - constructs the object an sets its main fields
    %    getLinear(state)           - always returns zero
    %    getRotational(state)       - always returns zero
    %    update([])                 - no computation
    %
    properties
        w6                %velocity at 6m from ground in m/s
    end
    
    methods 
        function obj = Wind(objparams)
            % constructs the object 
            % This object is created when wind is not active
            %
            % Example:
            % 
            %   obj=WindConstMean(objparams)
            %                objparams.on - 0 to have this type of object
            %                objparams.W6 - velocity at 6m from ground in m/s
            %          
                        
            objparams.dt = intmax*objparams.DT; % since this wind is constant
            
            obj=obj@Steppable(objparams);                
                                    
            assert(isfield(objparams,'W6'),'wind:now6','the task must define wind.W6');            
            obj.w6=objparams.W6;
        end
  
        function v = getLinear(~,~)
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
            %
            % Note:
            %  this method is called automatically by the step() of the Steppable parent
            %  class and should not be called directly.
            %
        end
    end
end

