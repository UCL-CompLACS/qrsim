classdef GPSReceiver<Sensor
    % Class for a noiseless generic GPS receiver.
    %
    % GPSReceiver Methods:
    %    GPSReceiver(objparams)     - constructs the object
    %    getMeasurement(X)          - returns the noiseless NED position and velocities
    %    update(X)                  - stores current state
    %    reset()                    - does nothing
    %    setState(X)                - re-initialise the state to a new value
    %
    properties (Access=protected)
        estimatedPosVelNED;   % estimated pose
    end
    
    methods (Access=public)
        function obj = GPSReceiver(objparams)
            % constructs the object
            %
            % Example:
            %
            %   obj=GPSReceiver(objparams)
            %                objparams.on - 0 to have this type of object
            %
            
            if(objparams.on)
                assert(~strcmp(class(objparams.state.environment.gpsspacesegment),'GPSSPaceSegment'),...
                    'When a GPS receiver is active also a corresponding gpsspacesegment object must be active');                
            end
            
            objparams.dt = objparams.state.environment.gpsspacesegment.getDt();
            
            obj = obj@Sensor(objparams);
        end
        
        function posVelNED = getMeasurement(obj,~)
            % returns the noiseless NED position and velocities
            %
            % Example:
            %
            %   [px;py;pz;pxdot;pydot] = obj.getMeasurement(X)
            %       X - platform noise free state vector [px,py,pz,phi,theta,psi,u,v,w,p,q,r,thrust]
            %       px,py,pz      [m]     noiseless position (NED coordinates)
            %       pxdot         [m/s]   noiseless x velocity (NED coordinates)
            %       pydot         [m/s]   noiseless y velocity (NED coordinates)
            %

            posVelNED = obj.estimatedPosVelNED;
        end
        
        function obj = reset(obj)
            % reset model
	        obj.bootstrapped = obj.bootstrapped +1;
        end
                
        function obj=setState(obj,X)
            % set new state from platform state
            obj.update(X);
            obj.bootstrapped = 0;
        end
    end
    
    methods (Access=protected)    
        function obj=update(obj,X)
            % simply stores the state to be used by getMeasurement()
            %
            % Note: this method is called by step() if the time is a multiple
            % of this object dt, therefore it should not be called directly.
                        
            % velocity in global frame
            gvel = (dcm(X)')*X(7:9);
            obj.estimatedPosVelNED = [X(1:3);gvel(1:2)];
        end
    end
end

