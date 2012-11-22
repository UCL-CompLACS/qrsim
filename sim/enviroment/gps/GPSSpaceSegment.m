classdef GPSSpaceSegment < Steppable & EnvironmentObject
    % Generic class for GPS space segments that is not active
    %
    % GPSSpaceSegment Methods:
    %    GPSSpaceSegment(objparams)   - constructor
    %    update([])                   - does nothing
    %    reset()                      - does nothing 
    %
    properties (Constant)
       TBEFOREEND = 1800; % in case of random start time, this is at least 1800 seconds before 
                          % the end of the sp3 file  
    end
    
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
	    obj.bootstrapped = 1;
        end
    end
    
    methods (Access=protected)        
        function obj=update(obj,~)
            % does nothing because this is not an active space segment
            %
            % Note:
            %  this method is called automatically by the step() of the Steppable parent
            %  class and should not be called directly.
            %
        end
    end
   
end
