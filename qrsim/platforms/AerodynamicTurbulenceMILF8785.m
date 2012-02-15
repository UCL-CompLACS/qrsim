classdef AerodynamicTurbulenceMILF8785<AerodynamicTurbulence
    % Linear Turbulence model according to U.S. military specification MIL-F-8785C
    %
    % According to references[1, 2], turbulence can be modelled as a stochastic process
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
    %    getLinear(state)           - returns the linear component of the turbulence
    %    getRotational(state)       - always returns zero since this model does not have
    %                                 a rotational wind component
    %    update(XandWind)           - updates the GM turbulence model
    %
    %
    % [1] "Military Specification, “Flying Qualities of Piloted Airplanes" Tech. Rep.
    %      U.S. Military Specification MIL-F-8785C.
    % [2] "Creating a Unified Graphical Wind Turbulence Model from Multiple Specifications"
    %      Stacey Gage
    % [3] "Wind Disturbance Estimation and Rejection for Quadrotor Position Control"
    %     Steven L. Waslander, Carlos Wang
    
    properties (Constant)
        Z0 = 0.15; % feet
    end
    
    properties (Access=private)
        w6;                       %velocity at 6m from ground in m/s
        vgust_relwk = zeros(3,1); % aerodynamic turbulence in relative wind coords Knots
        vgust = zeros(3,1);       % aerodynamic turbulence in body coords m/s
        prngIds;                  % ids of the prng stream used by this object
        hOrigin;                  % origin reference altitude
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
            global state;
            
            obj=obj@AerodynamicTurbulence(objparams);
            assert(isfield(objparams,'W6'),'aerodynamicturbulencemilf8785:now6',...
                'the platform config file must define a aerodynamicturbulence.W6 parameter');
            obj.w6=objparams.W6;
            
            obj.hOrigin = -objparams.zOrigin;
            
            obj.prngIds = [1,2,3]+state.numRStreams;
            state.numRStreams = state.numRStreams + 3;
        end
        
        function v = getLinear(obj,~)
            % returns the linear component of the aerodynamic turbulence.
            %
            % Example:
            %
            %   v = obj.getLinear(state)
            %           state - 13 by 1 vector platform state
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
            %   v = obj.getRotational(state)
            %           state - 13 by 1 vector platform state
            %           v - zeros 3 by 1 vector
            %
            v=zeros(3,1);
        end
        
        function obj = reset(obj)
            % nothing to be done
            % TODO
        end
        
        function obj = setState(obj,~)
            % nothing to be done
            % TODO
        end
    end
    
    methods  (Sealed, Access=protected)
        function obj = update(obj, XandWind)
            % updates the GM turbulence model
            %
            % Note:
            %  this method is called automatically by the step() of the Steppable parent
            %  class and should not be called directly.
            %
            global state;
            
            X = XandWind(1:13);
            meanWind = XandWind(14:end); % in body coords
            
            % airspeed along the flight path, governs the lengthscale,
            % we can simply subtract velocity and mean wind since both are
            % in body coordinates
            relativeWind = X(7:9)-meanWind;
            
            V = norm(relativeWind);%m/s
            
            alpha = atan2(relativeWind(3),relativeWind(1)); % angle of attack
            beta = asin(relativeWind(2)/V); % sideslip angle
            
            cb = cos(beta);  sb = sin(beta);
            ca = cos(alpha); sa = sin(alpha);
            Cwb = [ ca*cb   -ca*sb -sa;
                    sb       cb     0 ;
                    sa*cb   -sa*sb  ca];
            
            hft = m2ft(obj.hOrigin-X(3)); % height of the platform from origin altitude
            w20ft = m2ft(obj.w6);         % baseline airspeed ft/s
            Vfts = m2ft(V);
            
            sigma = [1/(0.177+0.000823*hft)^0.4;1/(0.177+0.000823*hft)^0.4;1].*0.1.*w20ft;

            L = [1/(0.177+0.000823*hft)^1.2;1/(0.177+0.000823*hft)^1.2;1]*hft;
                        
            % noise samples
            eta = [randn(state.rStreams{obj.prngIds(1)},1,1);randn(state.rStreams{obj.prngIds(2)},1,1);randn(state.rStreams{obj.prngIds(3)},1,1)];
            
            % turbulence in relative wind coordinates  (i.e. u aligned with wind mean direction)         
            obj.vgust_relwk =  (1-(Vfts*obj.dt)./L).*obj.vgust_relwk+sqrt((2*Vfts*obj.dt)./L).*sigma.*eta;
            
            %turbulence in body coordinates
            obj.vgust = ft2m(Cwb*obj.vgust_relwk);
        end
    end
end

