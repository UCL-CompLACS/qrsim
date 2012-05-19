classdef VelocityPID
    %  quadrotorPID simple nested loops PID controller that can fly a quadrotor
    %  given a 3D target velocity vector in global coordinates.
    % The platform axes are considered decoupled.
    
    properties (Access=protected)
        DT;  % control timestep
    end
    
    properties (Constant)
        Kv = 0.4;
        Kw = -0.6;
        maxtilt = 0.34;
        th_hover = 0.59;
    end
    
    methods (Access = public)
        
        function obj = VelocityPID(DT)
            obj.DT = DT;
        end
        
        function U = computeU(obj,X,velNED)
            %
            %  Compute the quadtotor control signals given the current state and a target NED velocity
            %
            %  The desidred attitude is enforced by a P controller that tries to achieve
            %  the required linear velocity.
            %  Limits are in place to not reach dangerous velocities.
            %  The battery voltage is set to 12 volts to not trigger saturation effects.
            %  For simplicity heading (yaw) is kept to zero.  
            %
            %  use:
            % 
            %   U = pid.computeU(X,veldNED)
            %       U = [pt,rl,th,ya,vbatt] quadrotor control signals
            %       X = quadrototr state
            %       velNED = desired velocity in NED coordinates
            %           
            
            u = X(7);
            v = X(8);
            w = X(9);
            
            % convert desired velocity to body frame.
            vt = dcm(X)*velNED; 
            
            despxdot = obj.limit( vt(1),-3,3);
            desTheta = obj.Kv*(-(despxdot - u));
            desTheta = obj.limit(desTheta,-obj.maxtilt,obj.maxtilt);
            
            despydot = obj.limit( vt(2),-3,3);
            desPhi = obj.Kv*(despydot - v);
            desPhi = obj.limit(desPhi,-obj.maxtilt,obj.maxtilt);
            
            despzdot = obj.limit( vt(3),-3,3);
            desth = obj.th_hover + obj.Kw*(despzdot - w);
            th = obj.limit(desth,0,1);
            
            ya = 0;            
            
            U(1,1) = desTheta;
            U(2,1) = desPhi;
            U(3,1) = th;
            U(4,1) = ya;
            U(5,1) = 12; % set the voltage to a level that will not trigger saturations
        end
        
    end
    
    methods (Static)
        function v = limit(v, minval, maxval)
            v = max([min([maxval,v]),minval]);
        end
    end
end