classdef GPSSpaceSegment < Steppable & EnvironmentObject
    % Genric class for GPS space segments that is not active
    %
    % GPSSpaceSegment Methods:
    %    GPSSpaceSegment(objparams)- constructor
    %    update([])                   - does nothing
    %
       
    methods
        
        function obj=GPSSpaceSegment(objparams)
            % constructs an empty the object.
            % This is used in place of a GPS segment when 
            %
            % Example:
            %
            %   obj=GPSSpaceSegment(objparams);
            %                objparams.on - 1 if the object is active
            %
            obj=obj@Steppable(objparams);
            obj=obj@EnvironmentObject(objparams);
        end
    end
    
    methods (Access=protected)
        
        function obj=update(obj,~)
            % does nothing because the space segment is off
        end
    end
    
end
