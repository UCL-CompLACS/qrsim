classdef Steppable<handle
    % Abstract base class for any objects that is propagated forward during simulation.
    %
    % The class implements checking and interfaces for for anything that has a state
    % and gets updated over time.
    %
    % Steppable Properties:
    %   TOL                  - tolerance used when comparing float times (Constant)
    %
    % Steppable Methods:
    %   Steppable(objparams) - constructs the object, sets the timestep and the active flag
    %   step(args)           - if active==1, propagates the state of the object forward in time
    %   update(args)*        - updates the object state using args as input (Abstract)
    %   reset()*             - reset the object state (if any)
    %
    %                        *hyperlink broken because the method is abstract
    %
    properties (Constant)
        TOL=1e-6;    % tolerance used when comparing float times (Constant)
    end
    
    properties (Access=protected)
        dt            % timestep of this object
    end
    
    methods (Sealed)
        function obj=Steppable(objparams)
            % constructs and set the timestep of this object
            % The methods uses objparams.dt to set the object timestep (must be a multiple
            % of the simulation timestep) and objparams.on to set if the object is active.
            %
            % Example:
            %
            %   obj=Steppable(objparams)
            %                objparams.dt - timestep of this object
            %                objparams.DT - global simulation timestep
            %                objparams.on - 1 if the object is active
            %
            %
            % Note:
            % this is an abstract class so this contructor is meant to be called by any
            % subclass.
            %
            
            assert(isfield(objparams,'on'),'The task must define the parameter on for the object %s',class(obj));
            
            if(objparams.on)
                assert(isfield(objparams,'dt'),'steppable:nodt','The task must define the parameter dt for the object %s',class(obj));
                assert(isfield(objparams,'DT'),'steppable:nodt','The task must define the parameter DT for the object %s',class(obj));
            else
                assert(isfield(objparams,'dt'),'steppable:nodt',['Although the object %s is not ON, the task must define its parameter dt\n',...
                    'this is needed to define the update rate of the noiseless version of %s'],class(obj),class(obj));
                assert(isfield(objparams,'DT'),'steppable:nodt',['Although the object %s is not ON, the task must define its parameter DT\n',...
                    'this is needed to define the update rate of the noiseless version of %s'],class(obj),class(obj));
            end
            r = rem(objparams.dt,objparams.DT);
            if(((r<obj.TOL)||((objparams.dt-r)<obj.TOL)) && (objparams.dt~=0))
                obj.dt = objparams.dt;
            else
                error('dt must be a multiple of the simulation timestep %fs',objparams.DT);
            end
        end
    end
    
    methods (Sealed)
        function obj=step(obj,args)
            % if active==1 propagates the state of the object forward in time.
            % If DT time has elapsed since the last state update this methods propagates
            % the state forward calling obj.update(args). It does not change the state otherwise.
            %
            % Example:
            %
            %   obj.step(args);
            %       args - passed directly to update, see the update method
            %
            global state;
            
            r = rem(state.t,obj.dt);
            if(((r<obj.TOL)||((obj.dt-r)<obj.TOL)) && (obj.dt~=0))
                %                    fprintf(' stepping\n')
                obj=obj.update(args);
            else
                %                    fprintf(' not a timestep\n')
            end
        end
    end
    
    methods (Abstract,Access=protected)
        obj=update(obj,args)
        % updates the object state using args as input
        %
        % Note 1: this method is subclass specific and must be implemented by any subclass.
        % Note 2: this method is meant to be called by step() and should not be called directly.
        %
        % Example:
        %
        %   obj.update(args);
        %       args - subclass specific
        %
    end
    
    %methods (Abstract,Access=protected)
    %     obj=reset(obj)
    % reset the object state (if any)
    %
    % Note: this method is subclass specific and must be implemented by any subclass.
    %
    % Example:
    %
    %   obj.reset();
    %
    % end
end

