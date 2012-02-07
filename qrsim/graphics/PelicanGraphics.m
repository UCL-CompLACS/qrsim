classdef PelicanGraphics<QuadrotorGraphics
    % Class that handles the 3D visualization of a Pelican quadrotor helicopter
    % This implementation is very basic but has the advantage of not
    % depending on any additional toolbox
    %
    % PelicanGraphics Methods:
    %   PelicanGraphics(initX,params)  - constructs the object
    %   update()                         - updates the visualization according to the current state
    %
    
    properties (Access = private)
        % arms
        AL % arm length m
        AT % arm width m
        AW % arm thickness m
        
        % body
        BW % body width m
        BT % body thickness m
        
        % rotors
        R % rotor radius m
        DFT % distance from truss m
        
        gHandle         % graphic handle
        plotTrj         % 1 to enable trajectory plotting
        X               % state
    end
    
    methods (Sealed)
        function obj=PelicanGraphics(objparams,initX)
            % constructs the object
            %
            % Example:
            %   obj =  QuadrotorGraphics(initX,params);
            %          initX - initial state [px;py;pz;phi;theta;psi]
            %                  px,py,pz      [m]   position (NED coordinates)
            %                  phi,theta,psi [rad] attitude in Euler angles ZYX convention
            %          objparams.AL - arm length m
            %          objparams.AT - arm width m
            %          objparams.AW - arm thickness m
            %          objparams.BW - body width m
            %          objparams.BT - body thickness m
            %          objparams.R - rotor radius m
            %          objparams.DFT - distance from truss m
            %          objparams.on - 1 if graphics is active
            %          objparams.trajectory - 1 if plotting of trajectory is active
            
            obj=obj@QuadrotorGraphics(objparams,initX);
            
            assert(isfield(obj,'AL'),'pelicangraphics:nopar',...
                'the platform configuration file need to define the parameter AL');
            assert(isfield(obj,'AT'),'pelicangraphics:nopar',...
                'the platform configuration file need to define the parameter AT');
            assert(isfield(obj,'AW'),'pelicangraphics:nopar',...
                'the platform configuration file need to define the parameter AW');
            assert(isfield(obj,'BW'),'pelicangraphics:nopar',...
                'the platform configuration file need to define the parameter BW');
            assert(isfield(obj,'BT'),'pelicangraphics:nopar',...
                'the platform configuration file need to define the parameter BT');
            assert(isfield(obj,'R'),'pelicangraphics:nopar',...
                'the platform configuration file need to define the parameter R');
            assert(isfield(obj,'DFT'),'pelicangraphics:nopar',...
                'the platform configuration file need to define the parameter DFT');
            assert(isfield(obj,'trajectory'),'pelicangraphics:nopar',...
                'the platform configuration file need to define the parameter trajectory');
            
            % arms
            obj.AL = objparams.AL;  % arm length m
            obj.AT = objparams.AT; % arm width m
            obj.AW = objparams.AW; % arm thickness m
            
            % body
            obj.BW = objparams.BW; % body width m
            obj.BT = objparams.BT; % body thickness m
            
            % rotors
            obj.R = objparams.R; % rotor radius m
            obj.DFT = objparams.DFT; % distance from truss m
            
            % trajectory
            obj.plotTrj = objparams.trajectory;
            
            obj.X=initX(1:6);
            
            obj.initGlobalGraphics();
            obj.createGraphicsHandlers();
        end
        
        function obj = update(obj,X)
            % updates the visualization according to the current state
            %
            % Example:
            %   updateGraphics()
            %
            global state;
            
            obj.X = X(1:6);
            
            set(0,'CurrentFigure',state.display3d.figure)
            % body rotations translation
            C = dcm(obj.X);
            T = [obj.X(1),obj.X(2),obj.X(3)];
            
            TT = repmat(T,size(state.display3d.uavgraphicobject.b1,1),1);
            
            b1 = (state.display3d.uavgraphicobject.b1*C)+TT;
            b2 = (state.display3d.uavgraphicobject.b2*C)+TT;
            b3 = (state.display3d.uavgraphicobject.b3*C)+TT;
            
            % update body
            set(obj.gHandle.b1,'Vertices',b1);
            set(obj.gHandle.b2,'Vertices',b2);
            set(obj.gHandle.b3,'Vertices',b3);
            
            % rotors rotations translation
            TT = repmat(T,size(state.display3d.uavgraphicobject.rotor1,1),1);
            r1 = (state.display3d.uavgraphicobject.rotor1*C)+TT;
            r2 = (state.display3d.uavgraphicobject.rotor2*C)+TT;
            r3 = (state.display3d.uavgraphicobject.rotor3*C)+TT;
            r4 = (state.display3d.uavgraphicobject.rotor4*C)+TT;
            
            % update rotors
            set(obj.gHandle.r1,'XData',r1(:,1));
            set(obj.gHandle.r1,'YData',r1(:,2));
            set(obj.gHandle.r1,'ZData',r1(:,3));
            
            set(obj.gHandle.r2,'XData',r2(:,1));
            set(obj.gHandle.r2,'YData',r2(:,2));
            set(obj.gHandle.r2,'ZData',r2(:,3));
            
            set(obj.gHandle.r3,'XData',r3(:,1));
            set(obj.gHandle.r3,'YData',r3(:,2));
            set(obj.gHandle.r3,'ZData',r3(:,3));
            
            set(obj.gHandle.r4,'XData',r4(:,1));
            set(obj.gHandle.r4,'YData',r4(:,2));
            set(obj.gHandle.r4,'ZData',r4(:,3));
            
            if (obj.plotTrj)
                s = max(0,length(obj.gHandle.trjData.x-100));
                obj.gHandle.trjData.x = [obj.gHandle.trjData.x(s:end) obj.X(1)];
                obj.gHandle.trjData.y = [obj.gHandle.trjData.y(s:end) obj.X(2)];
                obj.gHandle.trjData.z = [obj.gHandle.trjData.z(s:end) obj.X(3)];
                
                obj.gHandle.trjLine = line(obj.gHandle.trjData.x,obj.gHandle.trjData.y,...
                    obj.gHandle.trjData.z,'LineWidth',2,'LineStyle','-');
            end
        end
    end
    
    methods (Sealed,Access=private)
        
        function obj=createGraphicsHandlers(obj)
            % creates the necessary graphics handlers and stores them
            %
            % Example:
            %    obj.createGraphicsHandlers()
            %
            global state;
            
            set(0,'CurrentFigure',state.display3d.figure)
            
            % initial translation and orientation
            C = dcm(obj.X);
            T = [obj.X(1),obj.X(2),obj.X(3)];
            
            TT = repmat(T,size(state.display3d.uavgraphicobject.b1,1),1);
            
            b1 = (state.display3d.uavgraphicobject.b1*C)+TT;
            b2 = (state.display3d.uavgraphicobject.b2*C)+TT;
            b3 = (state.display3d.uavgraphicobject.b3*C)+TT;
            
            obj.gHandle.b1 = patch('Vertices',b1,'Faces',state.display3d.uavgraphicobject.bf);
            obj.gHandle.b2 = patch('Vertices',b2,'Faces',state.display3d.uavgraphicobject.bf);
            obj.gHandle.b3 = patch('Vertices',b3,'Faces',state.display3d.uavgraphicobject.bf);
            
            TT = repmat(T,size(state.display3d.uavgraphicobject.rotor1,1),1);
            r1 = (state.display3d.uavgraphicobject.rotor1*C)+TT;
            r2 = (state.display3d.uavgraphicobject.rotor2*C)+TT;
            r3 = (state.display3d.uavgraphicobject.rotor3*C)+TT;
            r4 = (state.display3d.uavgraphicobject.rotor4*C)+TT;
            
            obj.gHandle.r1 = patch(r1(:,1),r1(:,2),r1(:,3),'r');
            obj.gHandle.r2 = patch(r2(:,1),r2(:,2),r2(:,3),'b');
            obj.gHandle.r3 = patch(r3(:,1),r3(:,2),r3(:,3),'b');
            obj.gHandle.r4 = patch(r4(:,1),r4(:,2),r4(:,3),'b');
            
            obj.gHandle.trjData.x = obj.X(1);
            obj.gHandle.trjData.y = obj.X(2);
            obj.gHandle.trjData.z = obj.X(3);
        end
        
        function obj = initGlobalGraphics(obj)
            % creates the necessary graphics primitives only once for all helicopters
            % Dimension according to the constants AL,AT,AW,BW,BT,R,DFT
            %
            % Example:
            %    obj.initGlobalGraphics()
            %
            global state;
            
            if(~exist('state.display3d.heliGexists','var'))
                %%% body
                al = obj.AL/2;  % half arm length
                at = obj.AT/2; % half arm width
                aw = obj.AW/2; % half arm thickness
                
                cube = [-1, 1, 1;-1, 1,-1;-1,-1,-1;-1,-1, 1; 1, 1, 1; 1, 1,-1; 1,-1,-1;1,-1, 1];
                
                state.display3d.uavgraphicobject.b1 = cube.*repmat([aw,al,at],size(cube,1),1);
                
                state.display3d.uavgraphicobject.b2 = state.display3d.uavgraphicobject.b1*angle2dcm(0,0,pi/2,'XYZ');
                
                bw = obj.BW/2; % half body width
                bt = obj.BT/2; % half body thickness
                
                state.display3d.uavgraphicobject.b3 =  (cube.*repmat([bw,bw,bt],size(cube,1),1))*angle2dcm(0,0,pi/4,'XYZ');
                
                state.display3d.uavgraphicobject.bf = [1 2 3 4; 5 6 7 8; 4 3 7 8; 1 5 6 2; 1 4 8 5; 6 7 3 2];
                
                %%% rotors
                r = 0:pi/8:2*pi;
                sr = size(r,2);
                disc = [sin(r).*obj.R;cos(r).*obj.R;-ones(1,sr).*obj.DFT]';
                
                state.display3d.uavgraphicobject.rotor1 = disc + repmat([al,0,0],sr,1);
                state.display3d.uavgraphicobject.rotor2 = disc + repmat([0,al,0],sr,1);
                state.display3d.uavgraphicobject.rotor3 = disc + repmat([0,-al,0],sr,1);
                state.display3d.uavgraphicobject.rotor4 = disc + repmat([-al,0,0],sr,1);
                state.display3d.uavgraphicobject.waypoint = (disc + repmat([-al,0,0],sr,1))*10;
                
                state.display3d.heliGexists=1;
                
            end
        end
    end
    
end

