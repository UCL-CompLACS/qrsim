classdef GPSSpaceSegment < Steppable & EnvironmentObject
    % Genric class for GPS space segments that is not active
    %
    % GPSSpaceSegment Methods:
    %    GPSSpaceSegment(objparams)   - constructor
    %    update([])                   - does nothing
    %    reset()                      - does nothing 
    %
    methods (Sealed,Access=public)        
        function obj=GPSSpaceSegment(objparams)
            % constructs an empty the object.
            % This is used in place of a GPS segment when the object is not
            % active
            %
            % Example:
            %
            %   obj=GPSSpaceSegment(objparams);
            %                objparams.on - 0 to have this type of object
            %
            obj=obj@Steppable(objparams);
            obj=obj@EnvironmentObject(objparams);
        end
    end
    
    methods  (Access=public)   
        function obj = reset(obj)
           % does nothing 
        end
    end
    
    methods (Access=protected)        
        function obj=update(obj,~)
            % does nothing because this ia not active space segment
            %
            % Note:
            %  this method is called automatically by the step() of the Steppable parent
            %  class and should not be called directly.
            %
        end
    end
   
end
