classdef AnglesHeightPID<handle
    % simple nested loops PID controller that can fly a quadrotor
    % given a target height and a reference heading.
    % The platform axes are considered decoupled.
    %
    % AnglesHeightPID methods:
    %   computeU(obj,X,desAngles,desZ,desPsi) - computes the control signals given the current state, 
    %                                           desired angles, heading and altitude
    %   reset()                               - reset controller
    %
    properties (Access=protected)
        iz;  % altitude controller integrator state
        ez;  % altitude error
        wp;  % current waypoint
        DT;  % control timestep
        sp;  % previous set point
    end
    
    properties (Constant)
        Kv = 0.09;        % xy velocity proportional constant 
        maxtilt = 0.34;   % max pitch/roll angle
        Kya = 6;          % yaw proportional constant
        maxyawrate = 4.4; % max allowed yaw rate
        Kiz = 0.0008;     % altitude integrative constant
        Kpz = 0.03;       % altitude proportional constant     
        Kdz = 0.04;       % altitude derivative constant
        th_hover = 0.59;  % throttle hover offset
    end
    
    methods (Access = public)        
        function obj = AnglesHeightPID(DT)
            %  Creates a AnglesHeightPID object:
            %      
            %  use:
            %    pid = AnglesHeightPID(DT)
            %      DT - control timestep (i.e. inverse of the control rate)
            %
            obj.DT = DT;
            obj.iz = 0;
            obj.ez = 0;
            obj.wp = seros(4,1);
            obj.sp = seros(4,1);
        end
        
        function U = computeU(obj,X,desAngles,desZ,desPsi)
            %
            %  Computes the quadrotor control signals given the current state, 
            %  desired angles, heading and altitude
            %
            %  The desidred pitch and roll angles are directly passed as input
            %  to the platform, altitude and heading are controlled using 2 independent
            %  PIDs.  Limits are in place to not reach dangerous velocities.
            %  The battery voltage is set to 12 volts to not trigger
            %  saturation effects.
            %
            %  use:
            % 
            %  U = pid.computeU(X,desAngles,desZ,desPsi)
            %       X - current platform state this could be either X or eX 
            %       desAngles - desired pitch and roll  [pt;rl]
            %       desZ - desired altitude (negative upwards)
            %       desPsi - desired platform heading (psi)
            %       U  - computed controls [pt;rl;th;ya;vb]
            %                                             
            if(~all(obj.sp==[desAngles;desZ;desPsi]))
                spChange=1;
                obj.sp = [desAngles;desZ;desPsi];
            else
                spChange = 0;
            end
            
            psi = X(6);
           
            ya = obj.limit(obj.Kya * (desPsi - psi),-obj.maxyawrate,obj.maxyawrate);
            
            % vertical controller is a full PID
            ez_ = -(desZ - z);
            
            obj.iz = obj.iz + ez_ *obj.DT;
            if(~spChange)
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
            
            U(1,1) = desAngles(1);
            U(2,1) = desAngles(2);
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
            obj.sp = zeros(4,1);
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
