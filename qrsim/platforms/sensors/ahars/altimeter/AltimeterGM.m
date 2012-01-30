classdef AltimeterGM<Altimeter
    % Simple accelerometer noise model.
    % The following assumptions are made:
    % - the noise is modelled as an additive Gauss-Markov process.
    % - the accelerometer refrence frame concides wih the body reference frame
    % - no time delays
    %
    % AltimeterGM Properties:
    %   TAU                       - noise time constant
    %   SIGMA                      - noise standard deviation
    %
    % AltimeterGM Methods:
    %   AltimeterGM(objparams)     - constructs the object
    %   getMeasurement(X)          - returns a noisy altitude measurement
    %   update(X)                  - updates the altimeter noisy altitude measurement
    %
    
    properties (Access = private)
        TAU                       % noise time constant
        SIGMA                      % noise standard deviation
        estimatedAltitude = zeros(1,1); % measurement at last valid timestep
        pastEstimatedAltitude = zeros(1,1); % measurement at past valid timestep
        n = zeros(1,1);            % measurement at last valid timestep
    end
    
    methods (Sealed)
        function obj = AltimeterGM(objparams)
            % constructs the object
            %
            % Example:
            %
            %   obj=AltimeterGM(objparams)
            %                objparams.dt - timestep of this object
            %                objparams.on - 1 if the object is active
            %                objparams.BETA - noise time constant
            %                objparams.SIGMA - noise standard deviation
            %
            obj = obj@Altimeter(objparams);
            obj.TAU = objparams.TAU;
            obj.SIGMA = objparams.SIGMA;
        end
        
        function estimatedAltitude = getMeasurement(obj,X)
            % returns a noisy altitude measurement
            %
            % Example:
            %   [~h,~hdot] = obj.getMeasurement(X)
            %        X - platform noise free state vector [px,py,pz,phi,theta,psi,u,v,w,p,q,r,thrust]
            %        ~h - scalar "noisy" altitude in global frame m
            %        ~hdot - scalar "noisy" altitude rate in global frame m
            %
            % Note: if active == 0, no noise is added, in other words:
            % ~h = -X(3)
            %
            %fprintf('get measurement AltimeterGM active=%d\n',obj.active);
            if(obj.active==1)%noisy
                estimatedAltitude = [obj.estimatedAltitude;...
                                     (obj.estimatedAltitude-obj.pastEstimatedAltitude)/obj.dt];
            else             %noiseless
                % handy values
                sph = sin(X(4)); cph = cos(X(4));
                sth = sin(X(5)); cth = cos(X(5));
                sps = sin(X(6)); cps = cos(X(6));
                
                dcm = [                (cth * cps),                   (cth * sps),      (-sth);
                    (-cph * sps + sph * sth * cps), (cph * cps + sph * sth * sps), (sph * cth);
                     (sph * sps + cph * sth * cps),(-sph * cps + cph * sth * sps), (cph * cth)];
                
                % velocity in global frame
                gvel = (dcm')*X(7:9);
                
                estimatedAltitude = [-X(3);-gvel(3)];
            end
        end
    end
    
    methods (Sealed,Access=protected)
        function obj=update(obj,X)
            % updates the altimeter noise state
            % Note: this method is called by step() if the time is a multiple
            % of this object dt, therefore it should not be called directly.
            global state;
            %disp('stepping AltimeterGM');
            %obj.n = (1-(obj.dt./obj.TAU)).*obj.n + obj.SIGMA.*randn(state.rStream,1,1);
            obj.n = obj.n.*exp(-obj.TAU*obj.dt) + obj.SIGMA.*randn(state.rStream,1,1);
            if(obj.pastEstimatedAltitude~=0)
               obj.pastEstimatedAltitude = obj.estimatedAltitude;
               obj.estimatedAltitude = obj.n - X(3);  %altitude not Z
            else 
               % stops silly velocities at the first timestep 
               obj.pastEstimatedAltitude = - X(3);  %altitude not Z 
               obj.estimatedAltitude = obj.n - X(3);  %altitude not Z
            end    
        end
        
    end
    
end

