classdef AerodynamicTurbulenceMILF8785<AerodynamicTurbulence
    % Turbulence model according to U.S. military specification MIL-F-8785C
    %
    % According to references[1, 2], turbulence can be modelled as a stochastic process
    % defined by velocity spectra. The turbulence field is assumed to be visualized as
    % frozen in time and space (i.e.: time variations are statistically equivalent to
    % distance variations in traversing the turbulence field). This assumption implies
    % that the turbulence-induced responses of the aircraft is result only of the motion
    % of the aircraft relative to the turbulent field
    % i.e. w = Omega * V
    % The turbulence axes orientation in this region is defined as being aligned with
    % the body coordinates.
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
    %    update([])                 - updates the GM turbulence model
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
        w6  %velocity at 6m from ground in m/s
    end
    
    properties
        vgust = zeros(3,1); % aerodynamic turbulence
    end
    
    methods (Sealed)
        function obj = AerodynamicTurbulenceMILF8785(objparams)
            % constructs the object and sets its main fields
            %
            % Example:
            %
            %   obj=AerodynamicTurbulenceMILF8785(objparams)
            %                objparams.dt - timestep of this object
            %                objparams.DT - global simulation timestep
            %                objparams.on - 1 if the object is active
            %                objparams.seed - prng seed, random if 0
            %                objparams.W6 - velocity at 6m from ground in m/s
            %
            obj=obj@AerodynamicTurbulence(objparams);
            obj.w6=objparams.W6;
        end
        
        function v = getLinear(obj,~)
            % returns the linear component of the aerodynamic turbulence.
            %
            % Example:
            %
            %   v = obj.getLinear(state)
            %           state - 13 by 1 vector platform state
            %           v - linear component of the component gust 3 by 1 vector
            %
            if(obj.active==1)
                v = knots2ms(obj.vgust);
            else
                v = zeros(3,1);
            end
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
            %
            v=zeros(3,1);
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
            global state;
            
            V=norm(X(7:9));%m/s airspeed along the flight path, governs the lengthscale
            
            z = m2ft(-X(3)); %height of the platform from ground
            w20 = ms2knots(obj.w6);
            
            sigma_v = 0.1*w20;
            Lv = abs(z);
            
            Lu = Lv/((0.177 + 0.000823*z)^1.2);
            sigma_u = sigma_v/((0.177 + 0.000823*z)^1.2);
            
            sigma = [sigma_u;sigma_v;sigma_v];
            
            if(V>0)
                au=V/Lu;
            else
                au=0;
            end
            obj.vgust = (1-au*obj.dt)*obj.vgust+sqrt(2*au*obj.dt)*sigma.*randn(state.rStream,3,1);
        end
    end
end

