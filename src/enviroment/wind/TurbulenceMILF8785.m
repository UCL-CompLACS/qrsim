classdef TurbulenceMILF8785<Wind
    %TURBULENCEMILF8785
    % turbulence model according to U.S. military specification MIL-F-8785C
    
    % most of the following is taken from
    % [1] "Military Specification, “Flying Qualities of Piloted Airplanes" Tech. Rep. 
    %      U.S. Military Specification MIL-F-8785C.
    % [2] "Creating a Unified Graphical Wind Turbulence Model from Multiple Specifications" 
    %      Stacey Gage
    % [3] "Wind Disturbance Estimation and Rejection for Quadrotor Position Control" 
    %     Steven L. Waslander, Carlos Wang
    %
    % According to the military references[1, 2], turbulence is a
    % stochastic process defined by velocity spectra. The turbulence
    % field is assumed to be visualized as frozen in time and space
    % (i.e.: time variations are statistically equivalent to distance
    % variations in traversing the turbulence field). This assumption
    % implies the turbulence-induced responses of the aircraft result
    % only from the motion of the aircraft relative to the turbulent
    % field
    % i.e. w = Omega * V
    % The turbulence axes orientation in this region is defined as being
    % aligned with the body coordinates.
    
    
    properties (Constant)
        Z0 = 0.15; % feet
    end
    
    properties (Access=private)   
        w6
        meandirection
    end
    
    properties
       vgust = zeros(3,1);
       vmean = zeros(3,1); 
    end
    
    methods  (Sealed, Access=protected)      
        function obj = update(obj, X)
            % note that this is only called through step(obj, X)
            % when the time is a multiple of the timestep
                       
            % instantaneous Airspeed along the flight path
            % this governs the lengthscale
            V=norm(X(7:9));%m/s
                     
            z = m2ft(-X(3)); %height of the platform from ground
            w20 = ms2knots(obj.w6);                       
            
            % wind shear
            obj.vmean = w20*(log(z/obj.Z0)/log(20/obj.Z0))*obj.meandirection;

            sigma_v = 0.1*w20;
            Lv = abs(z);
            
            Lu = Lv/((0.177 + 0.000823*z)^1.2);
            sigma_u = sigma_v/((0.177 + 0.000823*z)^1.2);
            
            sigma = [sigma_u;sigma_v;sigma_v];
            au=V/Lu;            
           
            obj.vgust = (1-au*obj.dt)*obj.vgust+sqrt(2*au*obj.dt)*sigma.*randn(3,1);
             
        end
    end
    
    methods (Sealed)
        function obj = TurbulenceMILF8785(objparams)
            obj=obj@Wind(objparams);
            obj.w6=objparams.W6;
            obj.meandirection=objparams.meandirection;
        end
        
        function [v t] = getLinear(obj,X)            
            if(obj.active==1)
                vmeanb = angle2dcm(X(6),X(5),X(4))*obj.vmean;            
                v = knots2ms(vmeanb);
                t = knots2ms(obj.vgust);
            else
                v = zeros(3,1);
                t = zeros(3,1);
            end    
        end
        
        function v = getRotational(~,~)
            v=zeros(3,1); 
        end    
    end
    
end

