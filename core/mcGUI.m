classdef mcGUI < mcSavableClass

    
    properties
%         config = [];            % Defined in mcSavableClass. All static variables (e.g. valid range) go in config.
        controls = {};
        
        f = [];
        
        updated = 0;
        finished = false;
        
        pw = 300;
        ph = 700; % Make variable...
    end
    
    methods (Static)
        function config = defaultConfig()
            config = mcGUI.exampleConfig();
        end
        function config = exampleConfig()
            %                     Style     String              Variable    TooltipString                               Optional: Limit [min max round] (only for edit)
            config.controls = { { 'title',  'Title:  ',         NaN,        'This section is an example section' },...
                                { 'edit',   'Number!:  '        0,          'Enter a number!',                          [01 234 1]},...
                                { 'edit',   'Number!:  '        0,          'Enter a number!',                          [01 234 0]},...
                                { 'edit',   'Number!:  '        0,          'Enter a number!',                          [-Inf Inf]},...
                                { 'edit',   'Number!:  '        0,          'Enter a number!',                          [0 0]},...
                                { 'push',   'Push this button', 'hello',    'Push to activate a generic config' },...
                                { 'edit',   'Number!:  '        0,          'Enter another number!' } };
        end
    end
    
    methods
        function gui = mcGUI(varin)
            switch nargin
                case 0
                    gui.load();                             % Attempt to load a previous config from configs/computername/classname/config.mat
                    
                    if isempty(gui.config)                  % If the file did not exist or the loading failed...
                        gui.config = gui.defaultConfig();   % ...then use the defaultConfig() as a backup.
                    end
                case 1
                    gui.config = varin;                     % Otherwise use the input as the config.
            end
            
            if strcmpi(class(gui), 'mcGUI')
                gui.buildGUI();
            end
        end
        
        function buildGUI(gui)
            gui.f = mcInstrumentHandler.createFigure(gui, 'saveopen');
            gui.f.Resize =          'off';
            gui.f.CloseRequestFcn = @gui.closeRequestFcn;
            gui.f.Tag =             class(gui);
            gui.f.UserData =        gui;
            
            if isfield(gui.config, 'Position')                  % If the position was saved in the config,...
                gui.f.Position = gui.config.Position;           % ...Then use these position settings.
                gui.f.Position(3) = gui.pw;                     % But force the width to be the expected value (becuase it might mess up the margins and centering otherwise.
            else
                gui.f.Position = [100, 100, gui.pw, gui.ph];    % Otherwise, use the default settings.
            end
            
            bh = 20;    % Button height
            ii = 1.5;   % Initial button
            m = .1;     % Margin
            w = 1 - 2*m;
            
            M = gui.pw*m;
            W = gui.pw*w;
            
            prevControl = '';   % The kind of the previous control. This allows us to put in nice formatting (e.g. larger space before titles, etc)
            
            jj = 1;
            
            for kk = 1:length(gui.config.controls)
                control = gui.config.controls{kk};
                switch control{1}
                    case 'title'
                        if ~isempty(prevControl)
                            ii = ii + 1;            % Add a space after the last line.
                        end
                        
                        uicontrol(  'Parent', gui.f,...
                                    'Style', 'text',... 
                                    'String', control{2},... 
                                    'TooltipString', control{4},... 
                                    'HorizontalAlignment', 'left',...
                                    'FontWeight', 'bold',...
                                    'Position', [M, -ii*bh, W, bh]);     
                        ii = ii + 1;
                    case 'text'
                        if strcmpi(prevControl, 'title')
                            ii = ii + .25;
                        end
                        if strcmpi(prevControl, 'push')
                            ii = ii + 1;
                        end
                        if strcmpi(prevControl, 'edit')
                            ii = ii + 1;
                        end
                        
                        uicontrol(                      'Parent', gui.f,...  
                                                        'Style', 'text',... 
                                                        'String', control{2},... 
                                                        'TooltipString', control{4},... 
                                                        'HorizontalAlignment', 'left',...
                                                        'Position', [M, -ii*bh, W, bh]);
                                                    
                        gui.controls{jj} =   uicontrol( 'Parent', gui.f,...
                                                        'Style', 'edit',... 
                                                        'String', control{3},...
                                                        'Position', [M, -(ii+1)*bh, W, bh],...
                                                        'UserData', kk);    % also save the line that spawned it so the final value can be saved.
                                   
                        gui.controls{jj}.Callback =         @gui.update;
                            
                        jj = jj + 1;
                        ii = ii + 2;
                    case 'edit'
                        if strcmpi(prevControl, 'title')
                            ii = ii + .25;
                        end
                        if strcmpi(prevControl, 'push')
                            ii = ii + 1;
                        end
                        if strcmpi(prevControl, 'text')
                            ii = ii + 1;
                        end
                        
                        uicontrol(                      'Parent', gui.f,...  
                                                        'Style', 'text',... 
                                                        'String', control{2},... 
                                                        'TooltipString', control{4},... 
                                                        'HorizontalAlignment', 'right',...
                                                        'Position', [M, -ii*bh, W/2, bh]);
                                                    
                        gui.controls{jj} =   uicontrol( 'Parent', gui.f,...
                                                        'Style', 'edit',... 
                                                        'String', control{3},...
                                                        'Value', control{3},...     % Also store number as value (used if string change is undesirable).
                                                        'Position', [M + W/2, -ii*bh, W/2, bh],...
                                                        'UserData', kk);    % also save the line that spawned it so the final value can be saved.
                                     
                        if length(control) > 4
                            gui.controls{jj}.TooltipString =    gui.getLimitString(control{5});
                            gui.controls{jj}.Callback =         {@gui.limit control{5}};
                        else
                            gui.controls{jj}.TooltipString =    gui.getLimitString([]);
                            gui.controls{jj}.Callback =         {@gui.limit [-Inf Inf]};
                        end  
                            
                        jj = jj + 1;
                        ii = ii + 1;
                    case 'push'
                        if ~strcmpi(prevControl, 'push')
                            ii = ii + .25;
                        end
                        
                        uicontrol(  'Parent', gui.f,...  
                                    'Style', 'push',... 
                                    'String', control{2},... 
                                    'TooltipString', control{4},... 
                                    'Position', [M, -ii*bh, W, bh],... 
                                    'Callback', {@gui.Callbacks, control{3}});                      
                        ii = ii + 1;
                end
                
                prevControl = control{1};
            end
            
            gui.ph = ii*bh;
            gui.f.Position(4) = gui.ph;
            
            for kk = 1:length(gui.f.Children)
                child = gui.f.Children(kk);
                
                if isprop(child, 'Position')
                    child.Position(2) = child.Position(2) + gui.ph;
                end
            end
            
            gui.f.Visible = 'on';
        end
        
        function limit(gui, src, ~, lim)
            val = str2double(src.String);       % Try to interpret the edit string as a double.
            
            if isnan(val)                       % If we don't understand.. (e.g. '1+1' was input), try to eval() it.
                try
                    val = eval(src.String);     % This would be an example of an exploit, if this was supposed to be a secure application. The user should never be able to execute his own code.
                catch
                    val = src.Value;            % If we still don't understand, revert to the previous value.
                end
            end
            
            % Next, preform our checks on our value.
            if length(lim) == 1 && lim  % If we only should round...
                val = round(val);
            elseif length(lim) > 1      % If we have min/max bounds...
                if val > lim(2)
                    val = lim(2);
                end
                
                if val < lim(1)
                    val = lim(1);
                end
                
                % Note that this will cause val = lim(1) if lim(1) > lim(2) instead of the expected lim(1) < lim(2)
                
                if length(lim) > 2 && lim(3)
                    val = round(val);
                end
            end
            
            src.String =    val;
            src.Value =     val;
            
            gui.update(src, 0);
        end
        function str = getLimitString(~, lim)
            str = 'No requirements.';
            
            if length(lim) == 1
                if lim
                    str = 'Must be an integer.';
                end
            elseif length(lim) > 1
                str = ['Bounded between ' num2str(lim(1)) ' and ' num2str(lim(2)) '.'];
                
                if length(lim) > 2 && lim(3)
                    str = [str ' Must be an integer.'];
                end
            end
        end
        function update(gui, src, ~)
            if ~isnumeric(src)              % This saves the value that the edit box was changed to in the static config. This will allow this value to be saved and recovered.
                if isempty(src.Value)
                    gui.config.controls{src.UserData}{3} =  src.String;
                else
                    gui.config.controls{src.UserData}{3} =  src.Value;
                end
            end
            
            gui.updated = gui.updated + 1;
        end
        
        function closeRequestFcn(gui, ~, ~)
            delete(gui);
        end
        
        function delete(gui)
            gui.save();     % Inherited from mcSavableClass...
            
            delete(gui.f)
        end
        
%         function val = getEditValue(gui, jj)  % Gets the value of the jj'th edit (change this eventually to look for the edit corresponding to a string? After all, this makes editing difficult)
%             val = gui.controls{jj}.Value;
%         end
    end
    
    methods
        function Callbacks(gui, ~, ~, cbName)
            switch cbName
                case 'quit'
                    delete(gui);
                case 'update'
                    gui.update(0,0);
                case 'finish'
                    gui.update(0,0);
                    gui.finished = true;
                case 'hello'
                    disp('Hello World!');
                otherwise
                    if ischar(cbName)
                        disp([class(gui) '.Callbacks(s, e, cbName): No callback of name ' cbName]);
                    else
                        disp([class(gui) '.Callbacks(s, e, cbName): Did not understand cbName; not a string.']);
                    end
            end
        end
    end
end




