classdef GPSReceiver<Sensor
    % Abstract class for a generic GPS receiver.
    % This is a simple wrapper, it does not include any code, its only purpouse is to
    % allow for runtime type checking.
    %
    % GPSReceiver Methods:
    %    GPSReceiver(objparams) - constructs the object
    %
    methods
        function obj = GPSReceiver(objparams)
            % constructs the object
            %
            % Example:
            %
            %   obj=GPSReceiver(objparams)
            %                objparams.on - 1 if the object is active
            %
            % Note:
            % this is an abstract class so this contructor is meant to be called by any
            % subclass.
            %
            global state;
            
            if(objparams.on)
                assert(state.environment.gpsspacesegment.on,...
                    'When a GPS receiver is active also a gpsspacesegment object must be active');
                objparams.dt = state.environment.gpsspacesegment.params.dt;
                objparams.tnsv  = length(state.environment.gpsspacesegment.params.svs);
                objparams.originutmcoords = state.environment.area.params.originutmcoords;
            end
            obj = obj@Sensor(objparams);
        end
    end
end

