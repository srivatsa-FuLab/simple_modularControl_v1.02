function mcDialog(varargin)
% mcDialog creates a dialog box, telling the user about something.
%
% Syntax:
%   - mcDialog(dialog)                      % dialog is the text shown in the box.
%   - mcDialog(dialog, title)               % title is the title of the box.
%   - mcDialog(dialog, title, verbose)      % verbose is for long messages and shows in a multiline box.
%
% Status: Finished.

    w = 300;
    p = 5;
    bh = 20;
    th = 60;
    vh = 200;

    % Make a figure, textbox, and OK button.
    f = figure('Position', [0 0 w 3*p+bh+th], 'NumberTitle', 'off', 'Menubar', 'none', 'Toolbar', 'none', 'Resize', 'off', 'Visible', 'off', 'CloseRequestFcn', 'uiresume; delete(gcbf);');
    t = uicontrol(f, 'Position', [4*p 2*p+bh w-5*p th], 'Style', 'text', 'HorizontalAlign', 'left');
    uicontrol(f, 'Position', [(w-100)/2 p 100 bh], 'Style', 'push', 'String', 'OK', 'Callback', 'uiresume; delete(gcbf);');
    
    switch nargin
        case 0
            f.Name =    'mcDialog';
            t.String =  'Default dialog message...';
        case 1
            f.Name =    'mcDialog';
            t.String =  varargin;
        case 2
            f.Name =    varargin{2};
            t.String =  varargin{1};
        case 3
            f.Name =    varargin{2};
            t.String =  varargin{1};
            
            f.Position = [0 0 w 4*p+bh+th+vh];
            t.Position = [4*p 3*p+bh+vh w-5*p th];
            
            % Make a scrolling textbox if a verbose string is specified.
            uicontrol(f, 'Position', [p 2*p+bh w-2*p vh], 'Style', 'edit', 'HorizontalAlign', 'left', 'Max', Inf, 'Min', 1, 'String', varargin{3});
        otherwise
            error(['mcDialog(varin): ' num2str(nargin) ' is not a valid number of inputs.'])
    end
    
    movegui(f, 'center')
    f.Visible = 'on';
    
    % Then pause all MATLAB excecution until uiresume is called by either closing the window or pressing OK.
    uiwait;
end




