function f = mcAxisListener(varin)
% mcAxisListener creates a GUI that regularly updates the position of any
% number of axes, specified by the cell array axes_.
%
%   f =  mcAxisListener()                   % Makes listener panel in new figure that listens to all registered axes.
% %   f =  mcAxisListener(config)             % Disabled.
% %   f =  mcAxisListener('config.mat')       % Disabled.
%   f =  mcAxisListener(axes_)              % Makes listener panel in new figure that listens to the contents of axes_.
%   f1 = mcAxisListener(axes_, f1, pos)     % Makes listener panel in figure f1, with Position pos.
%
% Status: Mostly documented. Consider moving into class form and giving loadable config.

    fw = 300;               % Figure width
    fh = 500;               % Figure height

%     pp = 5;                 % Panel padding
%     pw = fw - 40;           % Panel width
%     ph = 200;               % Panel height

    bh = 20;                % Button Height
            
    switch nargin
        case {0, 1}
            if nargin == 0
                warning('No axes provided to listen to... Listening to all of them.');
                [axes_, ~, ~] = mcInstrumentHandler.getAxes();
                axes_ = axes_(2:end);   % We don't want to listen to time.
    %             error('Axes to listen to must be provided.');
            else
                axes_ = varin;
            end
            
            f = mcInstrumentHandler.createFigure('mcAxisListener', 'none');
            
            f.Resize =      'off';
            f.Visible =     'off';
%             f.MenuBar =     'none';
            f.ToolBar =     'none';
            
            pos =           [0, 0, fw, fh];
        case 3
            axes_ =         varin{1};
            f =             varin{2};
            pos =           varin{3};
        otherwise
            error('mcAxisListener requires 1 or 3 arguments.');
    end
    
    l = length(axes_);
    
    if nargin <= 1                                  % If no figure was given to put the listener panel in...
        pos(4) = bh*(l+1);
        f.Position =    [[100 100] pos(3:4)];       % ...then appropriately adjust the size of the figure to fit the axes.
    end
    
    bh = pos(4)/(l+1);                              % Otherwise, equally space the axes in the space given.
    
    p = uipanel('Parent', f, 'Position', pos);      % Make the panel that the axes uicontrols will live in.
    
    ii = 1;
    
    for axis_ = axes_                                                                       % For each axis in the given list...
        uicontrol(  'Parent', p,...                                                         % ...label the axis,...
                    'Style', 'text',...
                    'String', [axis_{1}.nameUnits() ': '],...
                    'Position', [0, pos(4) - (ii+.5)*bh, pos(3)/2, bh],...
                    'HorizontalAlignment', 'right',...
                    'tooltipString', axis_{1}.name());
        edit = uicontrol(   'Parent', p,...                                                 % ...make an (inactive) edit box to display the position,...
                            'Style', 'edit',...
                            'String', num2str(axis_{1}.getX(), '%.02f'),...
                            'Position', [pos(3)/2, pos(4) - (ii+.5)*bh, pos(3)/4, bh],...
                            'Enable', 'inactive');
                        
        prop = axis_{1}.findprop('x');                                                     % ...and assign a property listener to the axis to watch for position updates.
        edit.UserData = event.proplistener(axis_{1}, prop, 'PostSet', @(s,e)(axisChanged_Callback(s, e, edit)));
        
        ii = ii + 1;
    end
    
    f.Visible =     'on';
end

function axisChanged_Callback(~, event, edit)
    if isvalid(edit)                                                    % If the edit uicontrol has not been deleted yet,...
        edit.String = num2str(event.AffectedObject.getX(), '%.02f');    % ...then set the edit uicontrol string to be the position of the axis.
    end
end




