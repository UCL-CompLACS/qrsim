classdef WaypointPID<handle
    %  quadrotorPID simple nested loops PID controller that can fly a quadrotor
    %  given a target waypoint (wp). The platform axes are considered decoupled.
    
    properties (Access=protected)
        iz;  % altitude controller integrator state
        ez;  % altitude error
        wp;  % current waypoint
        DT;  % control timestep
    end
    
    properties (Constant)
        Kxy =0.9;
        Kv = 0.09;
        maxtilt = 0.34;
        Kya = 6;
        maxyawrate = 4.4;
        Kiz = 0.0008;
        Kpz = 0.03;
        Kdz = 0.04;
        th_hover = 0.59;
    end
    
    methods (Access = public)
        
        function obj = WaypointPID(DT)
            obj.DT = DT;
            obj.iz = 0;
            obj.ez = 0;
            obj.wp = [0,0,0,0];
        end
        
        function U = computeU(obj,X,wp)
            %
            %  Compute the quadtotor control signals given the current state and a desired waypoint
            %
            %  The desidred attitude is enforced by a P controller that tries to achieve a
            %  linear velocity proportional to the  distance from the target.
            %  Limits are in place to not reach dangerous velocities.
            %  The battery voltage is set to 12 volts to not trigger
            %  saturation effects
            %
            %  use:
            %
            %
            
            if(~all(obj.wp==wp))
                wpChange=1;
                obj.wp = wp;
            else
                wpChange = 0;
            end
            
            x = X(1);
            y = X(2);
            psi = X(6);
            
            % rotationg the wp to body coordinates
            d = ((wp(1)-x)^2+(wp(2)-y)^2)^0.5;
            a = (atan2((wp(2)-y),(wp(1)-x)) - psi);
            
            bx = d * cos(a);
            by = d * sin(a); 
            
            if(length(X)==13)
                % the input is X 
                z = X(3);                
                u = X(7);
                v = X(8);              
            else    
                % the input is EX            
                z = -X(17);            
                pxdot = X(18);
                pydot = X(19);            
                vel = sqrt(pxdot*pxdot+pydot*pydot);
                u = vel * cos(a);
                v = vel * sin(a);
            end
            
            % simple P controller on velocity with a cap on the max velocity and
            % maxtilt
            desu = obj.limit(obj.Kxy*bx,-5,5);
            desTheta = obj.Kv*(-(desu - u));
            desTheta = obj.limit(desTheta,-obj.maxtilt,obj.maxtilt);
            
            desv = obj.limit(obj.Kxy*by,-5,5);
            desPhi = obj.Kv*(desv - v);
            desPhi = obj.limit(desPhi,-obj.maxtilt,obj.maxtilt);
            
            ya = obj.limit(obj.Kya * (wp(4) - psi),-obj.maxyawrate,obj.maxyawrate);
            
            % vertical controller is a full PID
            ez_ = -(wp(3) - z);
            
            obj.iz = obj.iz + ez_ *obj.DT;
            if(~wpChange)
                de_ = (ez_ - obj.ez)/obj.DT;
            else
                %disp('wp change');
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
        
    end
    
    methods (Static)
        function v = limit(v, minval, maxval)
            v = max([min([maxval,v]),minval]);
        end
    end
end
