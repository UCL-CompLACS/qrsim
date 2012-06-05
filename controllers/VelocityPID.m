classdef VelocityPID
    % VelocityPID simple nested loops PID controller that can fly a quadrotor
    % given a 3D target velocity vector in global coordinates (NED).
    % The platform axes are considered decoupled.
    
    properties (Access=protected)
        DT;  % control timestep
    end
    
    properties (Constant)
        Kv = 0.15;
        Kw = -0.2;
        maxtilt = 0.34;
        th_hover = 0.59;
        Kya = 6;
        maxyawrate = 4.4;
    end
    
    methods (Access = public)
        
        function obj = VelocityPID(DT)
            %  Creates a VelocityPID object:
            %      
            %  use:
            %    pid = VelocityPID(DT)
            %      DT - control timestep (i.e. inverse of the control rate)
            %
            obj.DT = DT;
        end
        
        function U = computeU(obj,X,desVelNED,desPsi)
            %  Computes the quadtotor control signals given the current
            %  state and a target NED velocity and heading
            %
            %  The desired attitude is enforced by a P controller that tries to achieve
            %  the required linear velocity. Limits are in place to not reach dangerous velocities.
            %  The battery voltage is set to 12 volts to not trigger saturation effects.
            %  The heading angle is controlled independently.  
            %  Note:
            %  both noiseless (X) and noisy (eX) states are valid inputs, 
            %  the controller will take care of any needed changes of coordinates.
            %  
            %  use:
            % 
            %  U = pid.computeU(X,desVelNED,desPsi)
            %       X - current platform state this could be either X or eX 
            %       desVelNED - desired velocity in NED coordinates  [vx;vy;vz]
            %       desPsi - desired platform heading (psi)
            %       U  - computed controls [pt;rl;th;ya;vb]
            %           
            
            Cbn = dcm(X);
            
            if(length(X)==13)
                % the input is X 
                u = X(7);
                v = X(8);
                w = X(9);
            else
                % the input is eX
                uvw = Cbn * [X(18:19);-X(20)];
                u = uvw(1);
                v = uvw(2);
                w = uvw(3);               
            end
            
            % convert desired velocity to body frame.
            vt = Cbn*desVelNED; 
            psi = X(6);
             
            despxdot = obj.limit( vt(1),-3,3);
            desTheta = obj.Kv*(-(despxdot - u));
            desTheta = obj.limit(desTheta,-obj.maxtilt,obj.maxtilt);
            
            despydot = obj.limit( vt(2),-3,3);
            desPhi = obj.Kv*(despydot - v);
            desPhi = obj.limit(desPhi,-obj.maxtilt,obj.maxtilt);
            
            despzdot = obj.limit( vt(3),-3,3);
            desth = obj.th_hover + obj.Kw*(despzdot - w);
            th = obj.limit(desth,0,1);
            
            ya = obj.limit(obj.Kya * (desPsi - psi),-obj.maxyawrate,obj.maxyawrate);            
            
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