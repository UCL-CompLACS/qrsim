classdef VelocityHeightPID<handle
    %  VelocityHeightPID simple nested loops PID controller that can fly a quadrotor
    %  given a target 2D velocity and a reference height and heading.
    
    properties (Access=protected)
        iz;  % altitude controller integrator state
        ez;  % altitude error
        wp;  % current waypoint
        DT;  % control timestep
        lastDesZ;  % last "waypoint"
    end
    
    properties (Constant)
        Kv = 0.15;
        maxLim = [0.34;0.34;4.4]; %pitch, roll, yaw rate
        Kya = 6;
        maxtilt = 0.34;
        maxyawrate = 4.4;
        Kiz = 0.0008;
        Kpz = 0.03;
        Kdz = 0.04;
        th_hover = 0.59;
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
            obj.iz = 0;
            obj.ez = 0;
            obj.wp = [0,0,0,0];
            obj.lastDesZ = 0;
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
            
            if(~(obj.lastDesZ==desZ))
                zChange=1;
                obj.lastDesZ = desZ;
            else
                zChange = 0;
            end
            
            Cbn = dcm(X);
            
            if(length(X)==13)
                uvp = [X(7:8);X(6)];
                %u = X(7);
                %v = X(8);
                z = X(3);
            else
                uvw = Cbn * X(18:20);
                %u = uvw(1);
                %v = uvw(2);
                uvp = [uvw(1:2);X(6)];
                z = -X(17);
            end
            
            % convert desired velocity to body frame.
            vt = Cbn*[desVelNE;0];
            desuvp=zeros(3,1);
            for i=1:2
                if(abs(vt(i))<obj.maxv)
                    desuvp(i) = vt(i);
                else
                    desuvp(i) = sign(vt(i))*obj.maxv;
                end
            end
            desuvp(3)=desPsi;
            
            %psi = X(6);
            
            % simple P controller on velocity with a cap on the max velocity and
            % maxtilt
            %desTheta = obj.Kv*(-(vt(1) - u));            
            %desTheta = obj.limit(desTheta,-obj.maxtilt,obj.maxtilt);            
            %desPhi = obj.Kv*(vt(2) - v);
            %desPhi = obj.limit(desPhi,-obj.maxtilt,obj.maxtilt);
            %ya = obj.limit(obj.Kya * (desPsi - psi),-obj.maxyawrate,obj.maxyawrate);  
            
            desTPY = [-obj.Kv;obj.Kv;obj.Kya].*(desuvp-uvp);
                       
            for i=1:3
                if(abs(desTPY(i))>obj.maxLim(i))
                    desTPY(i) = sign(desTPY(i))*obj.maxLim(i);
                end
            end            
            
            % vertical controller is a full PID
            ez_ = -(desZ - z);
            
            obj.iz = obj.iz + ez_ *obj.DT;
            if(~zChange)
                de_ = (ez_ - obj.ez)/obj.DT;
            else
                %disp('z change');
                de_ =  0;
            end
            obj.ez = ez_;
            
            desth = obj.th_hover + obj.Kpz * ez_ + obj.Kiz * obj.iz + de_ * obj.Kdz;
            if(desth<0)
               th = 0;
            elseif(desth>1)
               th = 1;
            else
               th = desth; 
            end
            
            % anti windup
            obj.iz = obj.iz - (desth-th)*2;
            
            U(1:2,1) = desTPY(1:2);
            U(3,1) = th;
            U(4,1) = desTPY(3);
            U(5,1) = 12; % set the voltage to a level that will not trigger saturations
        end
        
    end
end
