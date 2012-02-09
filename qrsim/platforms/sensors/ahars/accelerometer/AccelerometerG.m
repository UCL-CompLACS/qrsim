classdef AccelerometerG<Accelerometer
    % Simple accelerometer noise model.
    % The following assumptions are made:
    % - the noise is modelled as additive white Gaussian 
    % - the accelerometer refrence frame concides wih the body reference frame
    % - no time delays 
    %
    % AccelerometerG Properties:
    %   SIGMA                            - noise standard deviation
    %
    % AccelerometerG Methods:
    %   AccelerometerG(objparams)        - constructs the object
    %   getMeasurement(a)                - returns a noisy acceleration measurement
    %   update(a)                        - updates the accelerometer sensor noise state
    %   reset()                          - reinitialize noise terms
    %   setState(a)                      - sets the current acceleration and resets
    %  
    properties (Access = private)
        SIGMA;                           % noise standard deviation
        n = zeros(3,1);                  % noise sample at current timestep
        prngId;                          %id of the prng stream used by the noise model
    end
    
    methods (Sealed,Access=public)
        function obj = AccelerometerG(objparams)
            % constructs the object
            %
            % Example:
            %
            %   obj=AccelerometerG(objparams)
            %                objparams.dt - timestep of this object
            %                objparams.on - 1 if the object is active
            %                objparams.SIGMA - noise standard deviation
            %
            global state;
            obj = obj@Accelerometer(objparams);
            state.numRStreams = state.numRStreams +1;
            obj.prngId = state.numRStreams;
            
            assert(isfield(objparams,'SIGMA'),'accelerometerg:sigma',...
                'the platform configuration must define accelerometer.SIGMA');
            obj.SIGMA = objparams.SIGMA;
        end
        
        function measurementAcceleration = getMeasurement(obj,~)
            % returns a noisy acceleration measurement
            %
            % Example:
            %   ma = obj.getMeasurement(a)
            %       ma - 3 by 1 vector of noise free acceleration in body frame [ax;ay;az] m/s^2
            %       a  - 3 by 1 vector of "noisy" acceleration in body frame [~ax;~ay;~az] m/s^2
            %
            measurementAcceleration = obj.measurementAcceleration;
        end        
                
        function obj=reset(obj)
            % does nothing  
            % since the noise model does not have state variables
        end
        
        function obj = setState(obj,a)
            % sets the current acceleration and resets
            obj.measurementAcceleration = a;
            obj.reset();
        end
    end
    
    methods (Sealed,Access=protected)
        function obj=update(obj,a)
            % updates the accelerometer noise state
            % Note: this method is called by step() if the time is a multiple
            % of this object dt, therefore it should not be called directly.
            global state;
            obj.n = obj.SIGMA.*randn(state.rStreams{obj.prngId},3,1);
            obj.measurementAcceleration = obj.n + a(1:3);
        end
        
    end
    
end

