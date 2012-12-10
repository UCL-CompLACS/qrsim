classdef VelocityPID<handle
    % simple nested loops PID controller that can fly a quadrotor
    % given a 3D target velocity vector in global coordinates (NED).
    % The platform axes are considered decoupled.
    %
    % VelocityPID methods:
    %   computeU(obj,X,desVelNED,desPsi) - computes the control signals given the current state, 
    %                                      desired velocity, heading and altitude
    %   reset()                          - reset controller
    %
    properties (Access=protected)
        DT;    % control timestep
        ei;    % integrator state
        ePast; % past error state  
        sp;    % past set point  
    end
    
    properties (Constant)
        Kvp = 0.25;         % xy velocity proportional constant 
        Kvi = 0.003;        % xy velocity integrative constant 
        Kvd = 0.05;         % xy velocity derivative constant
        Kwp = -0.2;         % z velocity proportional constant 
        Kwi = -0.002;       % z velocity integrative constant 
        Kwd = -0.0;         % z velocity derivative constant
        th_hover = 0.59;    % throttle hover offset
        maxtilt = 0.34;     % max pitch/roll angle
        Kya = 6;            % yaw proportional constant
        maxyawrate = 4.4;   % max allowed yaw rate
        maxv = 3;           % max allowed xy velocity
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
            obj.ei = zeros(3,1);
            obj.ePast = zeros(3,1);
            obj.sp = zeros(3,1);
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
            
            if(~all(obj.sp==desVelNED))
                spChange=1;
                obj.sp = desVelNED;
            else
                spChange = 0;
            end
            
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
            
            despxdot = obj.limit( vt(1),-obj.maxv,obj.maxv);
            e = (-(despxdot - u));            
            if(~spChange)
                de = (e-obj.ePast(1))/obj.DT;
            else
                de =  0;
            end
            desTheta = obj.Kvp*e+obj.Kvi*obj.ei(1)+obj.Kvd*de;
            obj.ei(1) = obj.ei(1)+e;
            obj.ePast(1) = e;
            desTheta = obj.limit(desTheta,-obj.maxtilt,obj.maxtilt);
            
            despydot = obj.limit( vt(2),-obj.maxv,obj.maxv);
            e = (despydot - v);            
            if(~spChange)
                de = (e-obj.ePast(2))/obj.DT;            
            else
                de =  0;
            end
            desPhi = obj.Kvp*e+obj.Kvi*obj.ei(2)+obj.Kvd*de;
            obj.ei(2) = obj.ei(2)+e;
            obj.ePast(2) = e;
            desPhi = obj.limit(desPhi,-obj.maxtilt,obj.maxtilt);
                        
            despzdot = obj.limit( vt(3),-obj.maxv,obj.maxv);
            e = (despzdot - w);            
            if(~spChange)
                de = (e-obj.ePast(3))/obj.DT;            
            else
                de =  0;
            end
            desth = obj.th_hover + obj.Kwp*e+obj.Kwi*obj.ei(3)+obj.Kwd*de;
            obj.ei(3) = obj.ei(3)+e;
            obj.ePast(3) = e;
            th = obj.limit(desth,0,1);
            
            ya = obj.limit(obj.Kya * (desPsi - psi),-obj.maxyawrate,obj.maxyawrate);            
            
            U(1,1) = desTheta;
            U(2,1) = desPhi;
            U(3,1) = th;
            U(4,1) = ya;
            U(5,1) = 12; % set the voltage to a level that will not trigger saturations
        end     
        
        function obj = reset(obj)
            % reset controller
            %
            % use:
            %  pid.reset();
            %
            obj.ei = zeros(3,1);
            obj.ePast = zeros(3,1);
            obj.sp = zeros(3,1);
        end    
    end
    
    methods (Static)
        function v = limit(v, minval, maxval)
            % constrain value between minval and maxval
            if(v<minval)
                v = minval;
            elseif (v>maxval)
                v = maxval;
            end
        end
    end
end