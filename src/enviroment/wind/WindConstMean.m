classdef WindConstMean<AerodynamicTurbulence
    % Class that simulates a constant wind field.
    % Given the current altitude of the platform the wind share effect is uded to compute
    % the magnitude and direction of the linear component of a constant wind field.
    %
    % WindConstMean Properties:
    %    Z0                         - reference height (constant)  
    %
    % WindConstMean Methods:
    %    WindConstMean(objparams)   - constructs the object an sets its main fields
    %    getLinear(state)           - returns the linear component of the wind field
    %    getRotational(state)       - always returns zero since this model does not have 
    %                                 a rotational wind component
    %    update([])                 - no computation, since the wind field is constant
    %
    properties (Constant)
        Z0 = 0.15; % feet
    end
    
    properties (Access=private)
        w6                %velocity at 6m from ground in m/s
        direction         %mean wind direction
    end
    
    methods (Sealed)
        function obj = WindConstMean(objparams)
            % constructs the object and sets its main fields
            %
            % Example:
            % 
            %   obj=WindConstMean(objparams)
            %                objparams.dt - timestep of this object
            %                objparams.DT - global simulation timestep
            %                objparams.on - 1 if the object is active 
            %                objparams.seed - prng seed, random if 0 
            %                objparams.W6 - velocity at 6m from ground in m/s
            %                objparams.direction - mean wind direction 3 by 1 vector
            %
            obj=obj@AerodynamicTurbulence(objparams);
            obj.w6=objparams.W6;
            obj.direction=objparams.direction;
        end
        
        function v = getLinear(obj,X)
            % returns the linear component of the wind field.
            % Given the current altitude of the platform the wind share effect is uded to
            % compute the magnitude and direction of the linear component of a constant
            % wind field.
            %
            % Example:
            %
            %   v = obj.getLinear(state)  
            %           state - 13 by 1 vector platform state
            %           v - 3 by 1 wind velocity vector in body coordinates
            %
            % Note: if active == 0, a zero vector is returned
            %  
            if(obj.active==1)                
                z = m2ft(-X(3)); %height of the platform from ground
                w20 = ms2knots(obj.w6);
                
                % wind shear
                if(z>0.05)
                    vmean = w20*(log(z/obj.Z0)/log(20/obj.Z0))*obj.direction;
                else
                    vmean = zeros(3,1); 
                end
                
                vmeanbody = angle2dcm(X(6),X(5),X(4))*vmean;
                v = knots2ms(vmeanbody);
            else
                v = zeros(3,1);
            end
        end
        
        function v = getRotational(~,~)
            % returns the rotational component of the wind field.
            % In this model the rotational component is always zero.
            %
            % Example:
            %
            %   v = obj.getRotational(state)  
            %           state - 13 by 1 vector platform state
            %           v - zeros 3 by 1 vector
            %
            %
            v=zeros(3,1);
        end
    end
    
    methods  (Sealed, Access=protected)
        function obj = update(obj, ~)
            % updates the mean wind vector.
            % In this model, the mean wind is constant so no updates are carries out.
            %
            % Note:
            %  this method is called automatically by the step() of the Steppable parent
            %  class and should not be called directly.
            %
        end
    end
end

