classdef WaypointPID<handle
    % simple nested loops PID controller that can fly a quadrotor
    % given a target waypoint (wp). 
    % The platform axes are considered decoupled.
    %
    % WaypointPID methods:
    %   computeU(obj,X,wp,desPsi)    - computes the control signals given the current state, 
    %                                  desired destibnation and heading
    %   reset()                      - reset controller
    %
    properties (Access=protected)
        iz;  % altitude controller integrator state
        ez;  % altitude error
        wp;  % current waypoint
        DT;  % control timestep
    end
    
    properties (Constant)
        Kxy = 0.9;          % position proportional constant
        Kv = 0.09;          % velocity proportional constant   
        Kiz = 0.0008;       % altitude integrative constant
        Kpz = 0.03;         % altitude proportional constant   
        Kdz = 0.04;         % altitude derivative constant        
        th_hover = 0.59;    % throttle hover offset
        maxtilt = 0.34;     % max pitch/roll angle
        Kya = 6;            % yaw proportional constant
        maxyawrate = 4.4;   % max allowed yaw rate
        maxv = 3;           % max allowed xy velocity
    end
    
    methods (Access = public)
        
        function obj = WaypointPID(DT) 
            %  Creates a WaypointPID object:
            %      
            %  use:
            %    pid = WaypointPID(DT)
            %      DT - control timestep (i.e. inverse of the control rate)
            %
            obj.DT = DT;
            obj.iz = 0;
            obj.ez = 0;
            obj.wp = [0;0;0];
        end
        
        function U = computeU(obj,X,wp,desPsi)
            %
            %  Computes the quadtotor control signals given the current state and a desired waypoint
            %
            %  The desidred attitude is enforced by a P controller that tries to achieve a
            %  linear velocity proportional to the  distance from the target.
            %  Limits are in place to not reach dangerous velocities.
            %  The battery voltage is set to 12 volts to not trigger
            %  saturation effects.
            %
            %  Note:
            %  both noiseless (X) and noisy (eX) states are valid inputs, 
            %  the controller will take care of any needed changes of coordinates.
            %
            %  use:
            %      
            %  U = pid.computeU(X,wp)
            %       X  - current platform state this could be either X or eX       
            %       wp - desired waypoint [px;py;pz;desPsi] 
            %            px - position (North)
            %            py - position (East)
            %            pz - position (Down)
            %            desPsi - desired platform heading (psi)            
            %       U  - computed controls [pt;rl;th;ya;vb]
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
            
            ya = obj.limit(obj.Kya * (desPsi - psi),-obj.maxyawrate,obj.maxyawrate);
            
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
        
        function obj = reset(obj)
            % reset controller
            %
            % use:
            %  pid.reset();
            %
            obj.iz = 0;
            obj.ez = 0;
            obj.wp = [0;0;0];           
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
