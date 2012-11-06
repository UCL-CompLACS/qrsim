function fcw(fig, butt)
%FCW  Figure Control Widget: Manipulate figures with key and button presses
%
%   fcw([fig], [buttons])
%
% Allows the user to rotate, pan and zoom a figure using key presses and
% mouse gestures. Additionally, press q to quit the widget, r to reset the
% axes and escape to close the figure. This function is non-blocking, but
% fixes axes aspect ratios.
%
% IN:
%   fig - Handle of the figure to be manipulated (default: gcf).
%   buttons - 3x1 cell array indicating the function to associate with
%             each mouse button (left to right). Functions can be any of:
%                'rot' - Rotate about x and y axes of viewers coordinate
%                        frame
%                'rotz' - Rotate about z axis of viewers coordinate frame
%                'zoom' - Zoom
%                'pan' - Pan
%                '' - Don't use that button
%             Default: {'rot', 'zoom', 'pan'}).

% (C) Copyright Oliver Woodford 2006-2012

% Much of the code here comes from Torsten Vogel's view3d function, which
% was in turn inspired by rotate3d from The MathWorks, Inc.

% Thanks to Sam Johnson for some bug fixes and good feature requests.

% Parse input arguments
buttons = {'rot', 'zoom', 'pan'};
switch nargin
    case 0
        fig = gcf;
    case 1
        if ~ishandle(fig)
            buttons = fig;
            fig = gcf;
        end
    otherwise
        buttons = butt;
end
% Clear any visualization modes we might be in
pan(fig, 'off');
zoom(fig, 'off');
rotate3d(fig, 'off');
% Save the current views
for h = findobj(fig, 'Type', 'axes', '-depth', 1)'
    V = camview(h);
    camview(h, V);
    set(h, 'UserData', V);
end
% Initialize the callbacks
set(fig, 'WindowButtonDownFcn', {@mousedown, buttons}, ...
         'WindowButtonUpFcn', @mouseup, ...
         'KeyPressFcn', @keypress, ...
         'BusyAction', 'cancel');
return

function keypress(src, eventData)
fig = ancestor(src, 'figure');
cax = get(fig, 'CurrentAxes');
if isempty(cax)
    return;
end
step = 1;
if ismember('shift', eventData.Modifier)
    step = 2;
end
if ismember('control', eventData.Modifier)
    step = step * 4;
end
% Which keys do what
switch eventData.Key
    case {'v', 'leftarrow'}
        fcw_pan([], [step 0], cax);
    case {'g', 'rightarrow'}
        fcw_pan([], [-step 0], cax);
    case {'b', 'downarrow'}
        fcw_pan([], [0 step], cax);
    case {'h', 'uparrow'}
        fcw_pan([], [0 -step], cax);
    case {'n', 'x'}
        fcw_rotz([], [0 step], cax);
    case {'j', 's'}
        fcw_rotz([], [0 -step], cax);
    case {'m', 'z'}
        fcw_zoom([], [0 -step], cax);
    case {'k', 'a'}
        fcw_zoom([], [0 step], cax);
    case 'r'
        % Reset all the axes
        for h = findobj(fig, 'Type', 'axes', '-depth', 1)'
            camview(h, get(h, 'UserData'));
        end
    case 'q'
        % Quit the widget
        set(fig, 'WindowButtonDownFcn', [], 'WindowButtonUpFcn', @mouseup, 'KeyPressFcn', @keypress);
    case 'escape'
        close(fig);
end
return

function mousedown(src, eventData, buttons)
% Get the button pressed
fig = ancestor(src, 'figure');
cax = get(fig, 'CurrentAxes');
if isempty(cax)
    return;
end
switch get(fig, 'SelectionType')
    case 'extend' % Middle button
        button = buttons{2};
    case 'alt' % Right hand button
        button = buttons{3};
    case 'open' % Double click
        camview(cax, get(cax, 'UserData'));
        button = '';
    otherwise
        button = buttons{1};
end
% Set the cursor
switch button
    case 'zoom'
        shape=[ 2   2   2   2   2   2   2   2   2   2 NaN NaN NaN NaN NaN NaN  ;
                2   1   1   1   1   1   1   1   1   2 NaN NaN NaN NaN NaN NaN  ;
                2   1   2   2   2   2   2   2   2   2 NaN NaN NaN NaN NaN NaN  ;
                2   1   2   1   1   1   1   1   1   2 NaN NaN NaN NaN NaN NaN  ;
                2   1   2   1   1   1   1   1   2 NaN NaN NaN NaN NaN NaN NaN  ;
                2   1   2   1   1   1   1   2 NaN NaN NaN NaN NaN NaN NaN NaN  ;
                2   1   2   1   1   1   1   1   2 NaN NaN NaN   2   2   2   2  ;
                2   1   2   1   1   2   1   1   1   2 NaN   2   1   2   1   2  ;
                2   1   2   1   2 NaN   2   1   1   1   2   1   1   2   1   2  ;
                2   2   2   2 NaN NaN NaN   2   1   1   1   1   1   2   1   2  ;
                NaN NaN NaN NaN NaN NaN NaN NaN   2   1   1   1   1   2   1   2  ;
                NaN NaN NaN NaN NaN NaN NaN   2   1   1   1   1   1   2   1   2  ;
                NaN NaN NaN NaN NaN NaN   2   1   1   1   1   1   1   2   1   2  ;
                NaN NaN NaN NaN NaN NaN   2   2   2   2   2   2   2   2   1   2  ;
                NaN NaN NaN NaN NaN NaN   2   1   1   1   1   1   1   1   1   2  ;
                NaN NaN NaN NaN NaN NaN   2   2   2   2   2   2   2   2   2   2  ];
        method = @fcw_zoom;
    case 'pan'
        shape=[ NaN NaN NaN NaN NaN NaN NaN   2   2 NaN NaN NaN NaN NaN NaN NaN ;
                NaN NaN NaN NaN NaN NaN   2   1   1   2 NaN NaN NaN NaN NaN NaN ;
                NaN NaN NaN NaN NaN   2   1   1   1   1   2 NaN NaN NaN NaN NaN ;
                NaN NaN NaN NaN NaN   1   1   1   1   1   1 NaN NaN NaN NaN NaN ;
                NaN NaN NaN NaN NaN NaN   2   1   1   2 NaN NaN NaN NaN NaN NaN ;
                NaN NaN   2   1 NaN NaN   2   1   1   2 NaN NaN   1   2 NaN NaN ;
                NaN   2   1   1   2   2   2   1   1   2   2   2   1   1   2 NaN ;
                2   1   1   1   1   1   1   1   1   1   1   1   1   1   1   2 ;
                2   1   1   1   1   1   1   1   1   1   1   1   1   1   1   2 ;
                NaN   2   1   1   2   2   2   1   1   2   2   2   1   1   2 NaN ;
                NaN NaN   2   1 NaN NaN   2   1   1   2 NaN NaN   1   2 NaN NaN ;
                NaN NaN NaN NaN NaN NaN   2   1   1   2 NaN NaN NaN NaN NaN NaN ;
                NaN NaN NaN NaN NaN   1   1   1   1   1   1 NaN NaN NaN NaN NaN ;
                NaN NaN NaN NaN NaN   2   1   1   1   1   2 NaN NaN NaN NaN NaN ;
                NaN NaN NaN NaN NaN NaN   2   1   1   2 NaN NaN NaN NaN NaN NaN ;
                NaN NaN NaN NaN NaN NaN NaN   2   2 NaN NaN NaN NaN NaN NaN NaN ];
        method = @fcw_pan;
    case {'rotz', 'rot'}
        % Rotate
        shape=[ NaN NaN NaN   2   2   2   2   2 NaN   2   2 NaN NaN NaN NaN NaN ;
                NaN NaN NaN   1   1   1   1   1   2   1   1   2 NaN NaN NaN NaN ;
                NaN NaN NaN   2   1   1   1   1   2   1   1   1   2 NaN NaN NaN ;
                NaN NaN   2   1   1   1   1   1   2   2   1   1   1   2 NaN NaN ;
                NaN   2   1   1   1   2   1   1   2 NaN NaN   2   1   1   2 NaN ;
                NaN   2   1   1   2 NaN   2   1   2 NaN NaN   2   1   1   2 NaN ;
                2   1   1   2 NaN NaN NaN NaN NaN NaN NaN NaN   2   1   1   2 ;
                2   1   1   2 NaN NaN NaN NaN NaN NaN NaN NaN   2   1   1   2 ;
                2   1   1   2 NaN NaN NaN NaN NaN NaN NaN NaN   2   1   1   2 ;
                2   1   1   2 NaN NaN NaN NaN NaN NaN NaN NaN   2   1   1   2 ;
                NaN   2   1   1   2 NaN NaN   2   1   2 NaN   2   1   1   2 NaN ;
                NaN   2   1   1   2 NaN NaN   2   1   1   2   1   1   1   2 NaN ;
                NaN NaN   2   1   1   1   2   2   1   1   1   1   1   2 NaN NaN ;
                NaN NaN NaN   2   1   1   1   2   1   1   1   1   2 NaN NaN NaN ;
                NaN NaN NaN NaN   2   1   1   2   1   1   1   1   1 NaN NaN NaN ;
                NaN NaN NaN NaN NaN   2   2 NaN   2   2   2   2   2 NaN NaN NaN ];
        if strcmp(button, 'rotz')
            method = @fcw_rotz;
        else
            method = @fcw_rot;
        end
    otherwise
        return
end
% Record where the pointer is
global FCW_POS
FCW_POS = get(0, 'PointerLocation');
% Set the cursor and callback
set(ancestor(src, 'figure'), 'Pointer', 'custom', 'pointershapecdata', shape, 'WindowButtonMotionFcn', {method, cax});
return

function mouseup(src, eventData)
% Clear the cursor and callback
set(ancestor(src, 'figure'), 'WindowButtonMotionFcn', '', 'Pointer', 'arrow');
return

function d = check_vals(s, d)
% Check the inputs to the manipulation methods are valid
global FCW_POS
if ~isempty(s)
    % Return the mouse pointers displacement
    new_pt = get(0, 'PointerLocation');
    d = FCW_POS - new_pt;
    FCW_POS = new_pt;
end
return

% Figure manipulation functions
function fcw_rot(s, d, cax)
d = check_vals(s, d);
% Rotate XY
camorbit(cax, d(1), d(2), 'camera', [0 0 1]);
return

function fcw_rotz(s, d, cax)
d = check_vals(s, d);
% Rotate Z
camroll(cax, d(2));
return

function fcw_zoom(s, d, cax)
d = check_vals(s, d);
% Zoom
d = (1 - 0.01 * sign(d(2))) ^ abs(d(2));
camzoom(cax, d);
return

function fcw_pan(s, d, cax)
d = check_vals(s, d);
% Pan
camdolly(cax, d(1), d(2), 0, 'movetarget', 'pixels');
return
