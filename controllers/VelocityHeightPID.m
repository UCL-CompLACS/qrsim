classdef VelocityHeightPID<handle
    %  VelocityHeightPID simple nested loops PID controller that can fly a quadrotor
    %  given a target 2D velocity and a reference height and heading.
    
    properties (Access=protected)
        DT;  % control timestep
        ei;
        ePast;           
        iz;
        ez;
        sp;
    end
    
    properties (Constant)
        Kvp = 0.25;
        Kvi = 0.003; 
        Kvd = 0.05;
        
        Kiz = 0.0008;
        Kpz = 0.03;
        Kdz = 0.04;
        th_hover = 0.59;
        
        maxtilt = 0.34;
        Kya = 6;
        maxyawrate = 4.4; 
        maxv = 3;
    end
    
    methods (Access = public)
        
        function obj = VelocityHeightPID(DT)
            %  Creates a VelocityHeightPID object:
            %
            %  use:
            %    pid = VelocityHeightPID(DT)
            %      DT - control timestep (i.e. inverse of the control rate)
            %
            obj.DT = DT;
            obj.ei = zeros(3,1);
            obj.ePast = zeros(3,1);
            obj.iz = 0;
            obj.ez = 0;
            obj.sp = [0;0;0];
        end
        
        function U = computeU(obj,X,desVelNE,desZ,desPsi)
            %
            %  Computes the quadrotor control signals given the current state,
            %  desired altitude, heading and velocity in global frame (NE  coords)
            %
            %  The desidred 2D velocity is enforced by a P controller that controls
            %  the pitch and roll angles of the platform as necessary.
            %  Altitude and heading are controlled independently.
            %  Limits are in place to not reach dangerous velocities.
            %  The battery voltage is set to 12 volts to not trigger
            %  saturation effects.
            %
            %  use:
            %
            %  U = pid.computeU(X,desVelNE,desZ,desPsi)
            %       X - current platform state this could be either X or eX
            %       desVelNE - desired 2D velocity in NED coordinates  [vx;vy]
            %       desZ - desired altitude (negatitive upwards)
            %       desPsi - desired platform heading (psi)
            %       U  - computed controls [pt;rl;th;ya;vb]
            %       
            
            if(~all(obj.sp==[desVelNE;desZ]))
                spChange=1;
                obj.sp = [desVelNE;desZ];
            else
                spChange = 0;
            end
            
            Cbn = dcm(X);
            
            if(length(X)==13)
                % the input is X 
                u = X(7);
                v = X(8);                
                z = X(3);                                                
            else
                % the input is eX
                uvw = Cbn * [X(18:19);-X(20)];
                u = uvw(1);
                v = uvw(2); 
                z = -X(17);            
            end
            
            % convert desired velocity to body frame.
            vt = Cbn*[desVelNE;0]; 
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
            
            ya = obj.limit(obj.Kya * (desPsi - psi),-obj.maxyawrate,obj.maxyawrate);
            
            % vertical controller is a full PID
            ez_ = -(desZ - z);
            
            obj.iz = obj.iz + ez_ *obj.DT;
            if(~spChange)
                de_ = (ez_ - obj.ez)/obj.DT;
            else
                de_ =  0;
            end
            obj.ez = ez_;
            
            desth = obj.th_hover + obj.Kpz * ez_ + obj.Kiz * obj.iz + de_ * obj.Kdz;
            th = obj.limit(desth,0,1);
            
            % anti windup
            obj.iz = obj.iz - (desth-th)*2;       
            
            U(1,1) = desTheta;
            U(2,1) = desPhi;
            U(3,1) = th;
            U(4,1) = ya;
            U(5,1) = 12; % set the voltage to a level that will not trigger saturations
        end     
        
        function obj = reset(obj)
            obj.ei = zeros(3,1);
            obj.ePast = zeros(3,1);
            obj.iz = 0;
            obj.ez = 0;
            obj.sp = [0;0;0];
        end    
    end
    
    methods (Static)
        function v = limit(v, minval, maxval)
            if(v<minval)
                v = minval;
            elseif (v>maxval)
                v = maxval;
            end
        end
    end
end