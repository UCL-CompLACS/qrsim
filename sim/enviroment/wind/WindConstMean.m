classdef WindConstMean<Wind
    % Class that simulates a constant wind field.
    % Given the current altitude of the platform the wind shear effect is used to compute
    % the magnitude and direction of the linear component of a constant wind field.
    % The running assumprion is that the mean wind varies on a time scale somewhat larger
    % than the scale of vehicle flight time.
    %
    % WindConstMean Properties:
    %    Z0                         - reference height (constant)
    %
    % WindConstMean Methods:
    %    WindConstMean(objparams)   - constructs the object an sets its fields
    %    getLinear(X)               - returns the linear component of the wind field
    %    getRotational(X)           - always returns zero since this model does not have
    %                                 a rotational wind component
    %    update([])                 - no computation, since the wind field is constant
    %
    properties (Constant)
        Z0 = 0.15; % feet
    end
    
    properties (Access=protected)
        direction;         % mean wind direction rad clockwise from north
        w6;                % velocity at 6m from ground in m/s
        hOrigin;           % origin reference altitude  
        prngId;            % id of the prng stream used by this object
        randDir;           % 1 if the wind direction is generated randomly
    end
    
    methods (Sealed,Access=public)
        function obj = WindConstMean(objparams)
            % constructs the object and sets its main fields
            %
            % Example:
            %
            %   obj=WindConstMean(objparams)
            %                objparams.on - 1 if the object is active
            %                objparams.W6 - velocity at 6m from ground in m/s
            %                objparams.direction - mean wind direction rad clockwise from north
            %                objparams.zOrigin - origin reference Z coord
            %
            
            objparams.dt = 3600*objparams.DT; % since this wind is constant
            
            obj=obj@Wind(objparams);
                                                            
            assert(isfield(objparams,'W6'),'windconstmean:now6','the task must define wind.W6');            
            obj.w6 = objparams.W6;
                                    
            obj.hOrigin = -objparams.zOrigin;
            
            assert(isfield(objparams,'direction'),'windconstmean:nodirection','the task must define wind.direction');  
           
            if(~isempty(objparams.direction))
                obj.randDir = 0;
                obj.direction = objparams.direction;
            else
                obj.randDir = 1;
                obj.direction = 0;
            end
            obj.simState.numRStreams = obj.simState.numRStreams+1;
            obj.prngId = obj.simState.numRStreams;

	    obj.bootstrapped = 0; 
        end
        
        function obj = reset(obj)
            % reset wind direction if random;     
            if(obj.randDir)
                obj.direction = 2*pi*rand(obj.simState.rStreams{obj.prngId},1,1);
            end
            obj.bootstrapped = 1;
        end
        
        function v = getLinear(obj,X)
            % returns the linear component of the wind field.
            % Given the current altitude of the platform the wind share effect is used to
            % compute the magnitude and direction of the linear component of a constant
            % wind field.
            %
            % Example:
            %
            %   v = obj.getLinear(X)
            %           X - 13 by 1 vector platform state
            %           v - 3 by 1 wind velocity vector in body coordinates
            %
            
            z = mToFt(obj.hOrigin-X(3)); %height of the platform from ground
            w20 = mToFt(obj.w6);
            
            % wind shear
            if(z>0.05)
                vmean = w20*(log(z/obj.Z0)/log(20/obj.Z0)).*[-cos(obj.direction);-sin(obj.direction);0];
            else
                vmean = zeros(3,1);
            end
            
            vmeanbody = dcm(X)*vmean;
            v = ftToM(vmeanbody);
        end
        
        function v = getRotational(~,~)
            % returns the rotational component of the wind field.
            % In this model the rotational component is always zero.
            %
            % Example:
            %
            %   v = obj.getRotational(X)
            %           X - 13 by 1 vector platform state
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

