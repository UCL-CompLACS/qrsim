classdef AerodynamicTurbulenceMILF8785<AerodynamicTurbulence
    % Linear Turbulence model according to U.S. military specification MIL-F-8785C
    %
    % According to references[1,2,3,4], turbulence can be modelled as a stochastic process
    % defined by velocity spectra. The turbulence field is assumed to be "frozen" in time
    % and space (i.e.: time variations are statistically equivalent to distance variations
    % in traversing the turbulence field). This assumption implies that the turbulence-induced
    % responses of the aircraft is result only of the motion of the aircraft relative to
    % the turbulent field (i.e. w = Omega * V).
    %
    % MILF8785-C specifies both linear and rotational components of the
    % turbulence however this class currently implements only the linear disturbences.
    % The turbulence axes orientation in this region is defined as being aligned with
    % the reletive wind direction.
    %
    %
    % AerodynamicTurbulenceMILF8785 Properties:
    %    Z0                         - reference height (Constant)
    %
    % AerodynamicTurbulenceMILF8785 Methods:
    %    AerodynamicTurbulenceMILF8785(objparams)   - constructs the object an sets its
    %                                                 main fields
    %    getLinear(X)               - returns the linear component of the turbulence
    %    getRotational(X)           - always returns zero since this model does not have
    %                                 a rotational wind component
    %    update(X)                  - updates the GM turbulence model
    %
    %
    % [1] "Military Specification, “Flying Qualities of Piloted Airplanes" Tech. Rep.
    %      U.S. Military Specification MIL-F-8785C.
    % [2] "Creating a Unified Graphical Wind Turbulence Model from Multiple Specifications"
    %      Stacey Gage
    % [3] "Wind Disturbance Estimation and Rejection for Quadrotor Position Control"
    %     Steven L. Waslander, Carlos Wang
    % [4] Jessie C. Yeager, "Implementation and Testing Turbulence Models for the F18-HARV
    %     Simulation"  NASA CR-1998-206937, Lockheed Martin Engineering & Sciences
    %
    properties (Constant)
        Z0 = 0.15; % feet
    end
    
    properties (Access=protected)
        Vof = 0.5;                % velocity offset
        w6;                       %velocity at 6m from ground in m/s
        vgust_windframe;          % aerodynamic turbulence in relative wind coords Knots
        vgust;                    % aerodynamic turbulence in body coords m/s
        prngIds;                  % ids of the prng stream used by this object
        hOrigin;                  % origin reference altitude
        direction;                % main turbulence direction
        X;                        % state
        randDir;                  % one if the turbulence direction is initialised randomly
    end
    
    methods  (Sealed,Access=public)
        function obj = AerodynamicTurbulenceMILF8785(objparams)
            % constructs the object and sets its main fields
            %
            % Example:
            %
            %   obj=AerodynamicTurbulenceMILF8785(objparams)
            %                objparams.dt - timestep of this object
            %                objparams.on - 1 if the object is active
            %                objparams.W6 - velocity at 6m from ground in m/s
            %                objparams.zOrigin - origin reference Z coord
            %                objparams.direction - main turbulence direction
            %
            
            obj=obj@AerodynamicTurbulence(objparams);
            assert(isfield(objparams,'W6'),'aerodynamicturbulencemilf8785:now6',...
                'the platform config file must define a aerodynamicturbulence.W6 parameter');
            obj.w6=objparams.W6;
            
            assert(isfield(objparams,'direction'),'aerodynamicturbulencemilf8785:nodirection',...
                'the platform config file must define a aerodynamicturbulence.direction6 parameter');
            
            if(~isempty(objparams.direction))
                obj.randDir = 0;
                obj.direction = objparams.direction;
            else
                obj.randDir = 1;
                obj.direction = 0;
            end
            
            obj.hOrigin = -objparams.zOrigin;
            
            obj.prngIds = [1,2,3,4]+obj.simState.numRStreams;
            obj.simState.numRStreams = obj.simState.numRStreams + 4;
        end
        
        function v = getLinear(obj,~)
            % returns the linear component of the aerodynamic turbulence.
            %
            % Example:
            %
            %   v = obj.getLinear(X)
            %           X - 13 by 1 vector platform state
            %           v - linear component of the component gust in body coordinates
            %           3 by 1 vector
            %
            v = obj.vgust;
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
            v=zeros(3,1);
        end
        
        function obj = reset(obj)
            % resets the state of the model
            
            if(obj.randDir)
                obj.direction = 2*pi*rand(obj.simState.rStreams{obj.prngIds(4)},1,1);
            end
            
            % airspeed along the flight path, governs the lengthscale,
            Vfts = mToFt(obj.Vof+norm(obj.X(7:9)));
            
            hft = mToFt(obj.hOrigin-obj.X(3)); % height of the platform from origin altitude
            w20ft = mToFt(obj.w6);             % baseline airspeed ft/s
            
            sigma = [1/(0.177+0.000823*hft)^0.4;1/(0.177+0.000823*hft)^0.4;1].*0.1.*w20ft;
            
            L = [1/(0.177+0.000823*hft)^1.2;1/(0.177+0.000823*hft)^1.2;1]*hft;
            
            obj.vgust_windframe = zeros(3,1);
            for i=0:1000
                % noise samples
                eta = [randn(obj.simState.rStreams{obj.prngIds(1)},1,1);
                    randn(obj.simState.rStreams{obj.prngIds(2)},1,1);
                    randn(obj.simState.rStreams{obj.prngIds(3)},1,1)];
                
                % turbulence in relative wind coordinates  (i.e. u aligned with wind mean direction)
                obj.vgust_windframe =  (1-(Vfts*obj.dt)./L).*obj.vgust_windframe+sqrt((2*Vfts*obj.dt)./L).*sigma.*eta;
            end
            
            obj.bootstrapped = obj.bootstrapped +1;
        end
        
        function obj = setState(obj,X)
            % setting the object state
            obj.X = X;
            obj.bootstrapped = 0;
        end
    end
    
    methods  (Sealed, Access=protected)
        function obj = update(obj, X)
            % updates the GM turbulence model
            %
            % Note:
            %  this method is called automatically by the step() of the Steppable parent
            %  class and should not be called directly.
            %
            
            % airspeed along the flight path, governs the lengthscale,
            Vfts = mToFt(obj.Vof+norm(X(7:9)));
            
            hft = mToFt(obj.hOrigin-X(3)); % height of the platform from origin altitude
            w20ft = mToFt(obj.w6);         % baseline airspeed ft/s
            
            sigma = [1/(0.177+0.000823*hft)^0.4;1/(0.177+0.000823*hft)^0.4;1].*0.1.*w20ft;
            
            L = [1/(0.177+0.000823*hft)^1.2;1/(0.177+0.000823*hft)^1.2;1]*hft;
            
            % noise samples
            eta = [randn(obj.simState.rStreams{obj.prngIds(1)},1,1);
                randn(obj.simState.rStreams{obj.prngIds(2)},1,1);
                randn(obj.simState.rStreams{obj.prngIds(3)},1,1)];
            
            % turbulence in relative wind coordinates  (i.e. u aligned with wind mean direction)
            obj.vgust_windframe =  (1-(Vfts*obj.dt)./L).*obj.vgust_windframe+sqrt((2*Vfts*obj.dt)./L).*sigma.*eta;
            
            % by definition the turbulence is aligned with the main turbulence direction,
            % we transform it to body coordinates
            Cte = [cos(obj.direction) sin(obj.direction) 0;
                -sin(obj.direction) cos(obj.direction) 0;
                0                  0 1];
            
            obj.vgust = dcm(X)*Cte*ftToM(-obj.vgust_windframe);
        end
    end
end

