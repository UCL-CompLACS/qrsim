classdef GPSReceiver<Sensor
    % Class for a noiseless generic GPS receiver.
    %
    % GPSReceiver Methods:
    %    GPSReceiver(objparams) - constructs the object
    %    getMeasurement(X)          - computes and returns a noise free GPS estimate given the input
    %                                 noise free NED position
    %    update(X)                  - stores current state
    %    reset()                    - does nothing
    %    setState(X)                - re-initialise the state to a new value
    %
    properties (Access=private)
        X; % last state [px,py,pz,phi,theta,psi,u,v,w]
    end
    
    methods
        function obj = GPSReceiver(objparams)
            % constructs the object
            %
            % Example:
            %
            %   obj=GPSReceiver(objparams)
            %                objparams.on - 0 to have this type of object
            %
            global state;
            
            if(objparams.on)
                assert((state.environment.gpsspacesegment.params.on==1),...
                    'When a GPS receiver is active also a corresponding gpsspacesegment object must be active');                
            end
            
            assert(isfield(state.environment.gpsspacesegment.params,'dt'),...
                    'GPS space segment must always define a dt parameter even when not active');               
            objparams.dt = state.environment.gpsspacesegment.params.dt;
            
            obj = obj@Sensor(objparams);
        end
        
        function estimatedPosNED = getMeasurement(obj,~)
            % returns a noise free GPS estimate given the current noise free position
            %
            % Example:
            %
            %   [px;py;pz;pxdot;pydot] = obj.getMeasurement(X)
            %       X - platform noise free state vector [px,py,pz,phi,theta,psi,u,v,w,p,q,r,thrust]
            %       px,py,pz      [m]     noiseless position (NED coordinates)
            %       pxdot         [m/s]   noiseless x velocity (NED coordinates)
            %       pydot         [m/s]   noiseless y velocity (NED coordinates)
            %
            
            % handy values
            sph = sin(obj.X(4)); cph = cos(obj.X(4));
            sth = sin(obj.X(5)); cth = cos(obj.X(5));
            sps = sin(obj.X(6)); cps = cos(obj.X(6));
            
            dcm = [                (cth * cps),                   (cth * sps),     (-sth);
                (-cph * sps + sph * sth * cps), (cph * cps + sph * sth * sps),(sph * cth);
                (sph * sps + cph * sth * cps),(-sph * cps + cph * sth * sps),(cph * cth)];
            
            % velocity in global frame
            gvel = (dcm')*obj.X(7:9);
            
            estimatedPosNED = [obj.X(1:3);gvel(1:2)];
        end
        
        function obj = reset(obj)
           % does nothing            
        end
        
        function obj = setState(obj,X)
           % re-initialise the state to a new value
           %
           % Example:
           %
           %   obj.setState(X)
           %       X - platform noise free state vector [px,py,pz,phi,theta,psi,u,v,w,p,q,r,thrust]
           %
           obj.X = X;
        end
    end
    
    methods (Access=protected)        
        function obj=update(obj,X)
            % simply stores the state to be used by getMeasurement()
            %
            % Note: this method is called by step() if the time is a multiple
            % of this object dt, therefore it should not be called directly.
            obj.X = X(1:9);
        end
    end
end

