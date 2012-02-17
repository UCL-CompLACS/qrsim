classdef WindConstMeanForTesting<WindConstMean
    % Provides WindConstMean with some useful getters
    %
    methods (Sealed,Access=public)
        function obj = WindConstMeanForTesting(objparams)
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
            
            obj=obj@WindConstMean(objparams);
                                                           
        end
        
        function dir = getDirection(obj)
            % reset wind direction if random;
            dir = obj.direction;
        end   
        
        function w6 = getW6(obj)
            % reset wind direction if random;
            w6 = obj.w6;
        end
    end
end

