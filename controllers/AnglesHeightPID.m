classdef AnglesHeightPID<handle
    %  AnglesHeightPID simple nested loops PID controller that can fly a quadrotor
    %  given a target height and a reference heading.
    
    properties (Access=protected)
        iz;  % altitude controller integrator state
        ez;  % altitude error
        wp;  % current waypoint
        DT;  % control timestep
    end
    
    properties (Constant)
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
            obj.wp = [0,0,0,0];
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
            
            psi = X(6);
           
            ya = obj.limit(obj.Kya * (desPsi - psi),-obj.maxyawrate,obj.maxyawrate);
            
            % vertical controller is a full PID
            ez_ = -(desZ - z);
            
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
            
            U(1,1) = desAngles(1);
            U(2,1) = desAngles(2);
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
