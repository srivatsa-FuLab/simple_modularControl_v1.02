classdef mcInstrumentHandler < handle
% mcInstrumentHandler, as its name suggests, handles all the instruments to make sure that none of 
% them are open at the same time. The mcInstrumentHandler itself is a Static class (i.e. only one 
% instance) and only one copy of its variable 'params' will be stored via exploitation of persistant.
%
% Syntax:
%
% (Private)
%   params = mcInstrumentHandler.Params()           % Returns the persistant params.
%   params = mcInstrumentHandler.Params(newparams)  % Sets the persistant params to newparams; again returns params.
%
% (Public)
%   tf = mcInstrumentHandler.open()                 % If params has not been initiated, then initiate params... ...with default values (will search for [params.hostname].mat). Returns whether mcInstrumentHandler was open before calling this.
%
% % (Not currently enabled)
% % tf = mcInstrumentHandler.open(config)           %                                                           ...with the contents of config (instruments, etc are overwritten).
% % tf = mcInstrumentHandler.open('config.mat')     %                                                           ...with the contents of config.mat (instruments, etc are overwritten).
%
%   params = mcInstrumentHandler.getParams()                % Returns the structure params.
%   instruments = mcInstrumentHandler.getInstruments()      % Returns the cell array params.instruments.
%   [axes_, names, states] = mcInstrumentHandler.getAxes()  % Returns a matrix axes_ containing the mcAxis oject for every axis, a cell array names containing the mcAxis.nameShort() for every axis, and a matrix states containing the mcAxis.x of every axis.
%   [inputs, names] = mcInstrumentHandler.getInputs()       % Returns a matrix inputs containing the mcAxis oject for every axis and a cell array names containing the mcInput.nameShort() for every axis.
%
%   obj2 = mcInstrumentHandler.register(obj)        % If obj already exists in params.instruments as obj2 (perhaps in another form or under a different name), then return obj2. Otherwise, add obj to params.instruments and return obj.
%
% Status: Mostly finished, but needs commenting and reorganization.

    properties
        % No properties.
    end

    % Private methods
    methods (Static, Access=private)
        function val = params(newval)
            persistent params;      % Apparently, this persistent workaround is the best way to get one instance of a variable for an entire class.
            if nargin > 0           % If we are setting params
                params = newval;
            end
            val = params;
        end
    end

    % Public methods
    methods (Static)
        function ver = version()    % Gives the version of modularControl. Will set to [1 0] upon first stable release.
            ver = [0 127];           % Commit number.
        end
        function tf = open()
            tf = true;
            
            params = mcInstrumentHandler.params();      % This line gets the class-wide variable stored in the above private method. This would be called a 
            
            if ~isfield(params, 'open')                 % If this is the first time modularControl has been opened on this instance of matlab (or mcInstrumentHandler has been edited).
                
                % Ridiculous introduction.
                disp('----------------------------------------------------------')
                disp(' ')
                disp('          ===================================')
                disp('           ||    Simple modularControl    ||')
                disp('          ===================================')
                disp(' ')
                disp('v1.02')
                disp('Modified 07-Feb-2021')
                disp('Repo: https://github.com/optospinlab/simple_modularControl')
                disp(' ')
                disp('Quote of the day:')
                disp('=================')
                quotes = {  'When in doubt, automate! :)',...
                            'Beware of the gremlins.',...
                            'Pain is a conserved quantity. Concentrate the pain now for a pain-free day!',...
                            'That doesn''t look like anything to me...',...
                            'Not only is the Universe stranger than we think, it is stranger than we can think...',...
                            'Engineers like to solve problems. If there are no problems handily available, they will create their own problems...',...
                            'Normal people believe that if it ain’t broke, don’t fix it. Engineers believe that if it ain’t broke, it doesn’t have enough features yet :)',...
                            'The trick to having good ideas is not to sit around in glorious isolation and try to think big thoughts. The trick is to get more parts on the table...',...
                            'The most important thing is to keep the most important thing the most important thing...',...
                            'No one wants to learn by mistakes, but we cannot learn enough from successes to go beyond the state of the art...',...
                            'The goal of science and engineering is to build better mousetraps. The goal of nature is to build better mice...',...
                            'Never go to bed mad. Stay up and fight...',...
                            'If a book about failures doesn''t sell, is it a success?', ...
                            'You should eat a waffle! You can''t be sad if you eat a waffle!',...
                            'When life gives you lemons, chunk it right back...',...
                            'Life is full of surprises, but never when you need one...',...
                            'There''s never enough time to do all the nothing you want...',...
                            'All you need is love. But a little chocolate now and then doesn''t hurt...',...
                            'Two wrongs don''t make a right, but they make a good excuse...',...
                            'Fantasy is a necessary ingredient in living, it''s a way of looking at life through the wrong end of a telescope...'};
                        
                rng('shuffle');
                q = randi(length(quotes));
                
                disp(wraptext(quotes{q},55))  % An amusing Easter egg...
                disp(' ')
                disp('----------------------------------------------------------')
                disp(' ')
                disp('Loading instruments:')
                
                % Reset everything (should I also clear all and close all?)
                delete(instrfind)
                if ~ismac       % Change eventually...
                    daqreset
                end
                
                % This is neccessary for spooky undocumented java stuff.
                if ~usejava('swing')
                    error('mcInstrumentHandler: Java Swing import failed. Not sure what to do if this happens.');
                end
                
                % Set some vars
                params.open =                       true;
                
                params.instruments =                {};         % Stores the mcAxes and mcInputs (separate these for simplicity?)
                params.shouldEmulate =              ismac;      % Whether or not the axes and inputs should initialize in emulation. Makes this more accessable in the future?
                
                if ismac
                    disp('mcInstrumentHandler.open(): Warning! Macs default to emulation mode. Change the code to remove this...')
                end
                
                params.saveFolderManual =              '';         % Empty string, to be loaded from .mat or chosen by GUI. Described in detail below.
                params.saveFolderBackground =          '';
                
                params.globalWindowKeyPressFcn =    [];
                params.figures =                    {};
                params.registeredInstruments =      [];
                
                params.warningLight =               [];         % (Future...) Stores the axis that controls a light to warn when data is being taken.
                params.defaultVideo =               [];         % 
                
                tf = false;                                         % Return whether the mcInstrumentHandler was open...
                
                % Figure out what system we are on (e.g. diamond room computer, etc.)
                [~, params.hostname] = system('hostname');          % A quick way to identify which system we are on.

                params.hostname(params.hostname < 32 | params.hostname >= 127) = '';    % Make sure only sensible characters are used (e.g. no \0)

                params.hostname = strrep(params.hostname, '.', '_');    % Not sure if this is the best way to do this...
                params.hostname = strrep(params.hostname, ':', '_');
                
                if ismac
                    disp(['Note: Finding a consistant computer name for a mac has proven difficult. Configs will be saved under the name of "macOS", instead of the probably-inconsistant "' params.hostname '", which is your current hostname.'])
                    params.hostname = 'macOS';
                end

                % Find the modularControl folder (neccessary for saving configs).
                params.mcFolder = pwd;      % First, guess that our current directory is the modularControl folder
                
                if ~strcmp(params.mcFolder(end-13:end), 'modularControl')   % Next, guess that it is a subfolder...
                    if exist([params.mcFolder filesep 'modularControl'], 'dir')
                        params.mcFolder = [params.mcFolder filesep 'modularControl'];
                    end
                end
                
                while ~ischar(params.mcFolder) || ~strcmp(params.mcFolder(end-13:end), 'modularControl')        % Get the current directory
                    mcDialog('For everything to function properly, mcInstrumentHandler must know where the modularControl folder is. Press OK to select that folder.', 'Need modularControl folder');
                    
                    params.mcFolder = uigetdir(params.mcFolder, 'Please choose the modularControl folder.');
                end
                
                mcInstrumentHandler.params(params);                 % Load persistant params with this so that we don't risk infinite recursion when we try to add the time axis (see below).
                
                params.instruments = {mcAxis(mcAxis.timeConfig())}; % Initialize with only time (which is special)
                
                mcInstrumentHandler.params(params);                 % Finally, load persistant params with this.
                
                folder = mcInstrumentHandler.getConfigFolder();
                if ~exist(folder, 'file')
                    mkdir(folder);
                end
                
                mcInstrumentHandler.loadParams();
                
                if isempty(params.saveFolderManual)
                    mcInstrumentHandler.promptSaveFolder(false);
                end
                if isempty(params.saveFolderBackground)
                    mcInstrumentHandler.promptSaveFolder(true);
                end
            end
        end
        function tf = isOpen()
            params = mcInstrumentHandler.params();
            
            tf = isfield(params, 'open');
        end
        
        function str = getConfigFolder()
            mcInstrumentHandler.open();
            params = mcInstrumentHandler.params();
            str = [params.mcFolder filesep 'configs' filesep params.hostname filesep];
        end
        
        function saveParams()
            mcInstrumentHandler.open();
            params2 = mcInstrumentHandler.params();
            
            params.saveFolderManual =      params2.saveFolderManual;           % only save saveFolderManual and saveFolderBackground...
            params.saveFolderBackground =  params2.saveFolderBackground;
            
            save([mcInstrumentHandler.getConfigFolder() 'params.mat'], 'params');
        end
        function loadParams()
            mcInstrumentHandler.open();
            params = mcInstrumentHandler.params();
            
            fname = [mcInstrumentHandler.getConfigFolder() 'params.mat'];
            
            if exist(fname, 'file')
                p = load(fname);
                
                if isfield(p, 'params')
                    if isfield(p.params, 'saveFolderManual')
                        params.saveFolderManual =      p.params.saveFolderManual;       % only load saveFolderManual and saveFolderBackground...
                    end
                    if isfield(p.params, 'saveFolderBackground')
                        params.saveFolderBackground =  p.params.saveFolderBackground;
                    end
                end
            end
            
            mcInstrumentHandler.params(params);
        end
        function promptSaveFolder(isBackground)
            mcInstrumentHandler.open();
            params = mcInstrumentHandler.params();
            
            if isBackground
                while all(params.saveFolderBackground == 0)
                    mcDialog('Every mcData scan saves its data in the background once the scan has finished. Press OK to select which folder this background data should be saved in.', 'Need background saving folder');

                    params.saveFolderBackground =  uigetdir(params.mcFolder, 'Please choose the background saving folder.');
                end
            else
                while all(params.saveFolderManual == 0)
                    mcDialog('When the user manually chooses to save data, they are prompted with a folder selection UI. Press OK to select the folder that the folder selection UI should start in.', 'Need manual saving folder');

                    params.saveFolderManual =  uigetdir(params.mcFolder, 'Please choose the manual saving folder.');
                end
            end
            
%             if ~isempty(params.saveFolderManual) && ~exist(params.saveFolderManual, 'dir')
%                 mkdir(params.saveFolderManual);
%             end
%             if ~isempty(params.saveFolderBackground) && ~exist(params.saveFolderBackground, 'dir')
%                 mkdir(params.saveFolderBackground);
%             end
            
            mcInstrumentHandler.params(params);
            
            mcInstrumentHandler.saveParams()
        end
        
        function setSaveFolder(isBackground, str)
            mcInstrumentHandler.open();
            params = mcInstrumentHandler.params();
            
            if ~exist(str, 'file')
                mkdir(str);
            end
            
            if isBackground
                params.saveFolderBackground = str;
            else
                params.saveFolderManual = str;
            end
            
            mcInstrumentHandler.params(params);
            mcInstrumentHandler.saveParams();
        end
        function str = getSaveFolder(isBackground)
            mcInstrumentHandler.open();
            params = mcInstrumentHandler.params();
            
            if isBackground
                str = params.saveFolderBackground;
            else
                str = params.saveFolderManual;
            end
        end
        function [str, stamp] = timestamp(varin)
            if ischar(varin)                                % If varin is a string, folder = '<manualsaveFolder>\<string>\<yyyy_mm_dd>'
                folder = [mcInstrumentHandler.getSaveFolder(0) filesep varin filesep datestr(now,'yyyy_mm_dd')];
            elseif isnumeric(varin) || islogical(varin)     % If varin is a number or t/f, folder = '<manualsaveFolder>\<yyyy_mm_dd>' or '<backgroundsaveFolder>\<yyyy_mm_dd>' depending upon whether varin evaluates as true or false
                folder = [mcInstrumentHandler.getSaveFolder(varin) filesep datestr(now,'yyyy_mm_dd')];
            else
                error('mcInstrumentHandler: timestamp varin not understood');
            end
            
            if ~exist(folder, 'dir')                       % Make this directory if it does not already exist.
                mkdir(folder);
            end
            
            stamp = datestr(now,'HH_MM_SS_FFF');
            
            str = [folder filesep stamp];   % Then return the string '<folder>\HH_MM_SS_FFF' (i.e. the file is saved as the time inside the date folder)
        end
        
        % GETTING FUNCTIONS
        function params = getParams()
            mcInstrumentHandler.open();
            params = mcInstrumentHandler.params();
        end
        function instruments = getInstruments()
            mcInstrumentHandler.open();
            params = mcInstrumentHandler.params();
            instruments = params.instruments;
        end
        function [axes_, names, configs, states] = getAxes()
            mcInstrumentHandler.open();
            params = mcInstrumentHandler.params();
            
            axes_ =     {};     % Initialize empty lists.
            names =     {};
            configs =   {};
            states =    [];
            
            ii = 1;
            
            for instrument = params.instruments
                if isa(instrument{1}, 'mcAxis') && isvalid(instrument{1})   % If an instrument is an axis...
                    axes_{ii} =     instrument{1};                          % ...Then append its information.
                    names{ii} =     instrument{1}.nameShort();
                    configs{ii} =   instrument{1}.config;
                    states(ii) =    instrument{1}.getX();
                    ii = ii + 1;
                end
            end
        end
        function [inputs, names] = getInputs()
            mcInstrumentHandler.open();
            params = mcInstrumentHandler.params();
            
            inputs =    {};     % Initialize empty lists.
            names =     {};
            ii = 1;
            
            for instrument = params.instruments
                if isa(instrument{1}, 'mcInput') && isvalid(instrument{1})  % If an instrument is a axis...
                    inputs{ii} = instrument{1};                             % ...Then append its information.
                    names{ii} = instrument{1}.nameShort();
                    ii = ii + 1;
                end
            end
        end
        
        % INSTRUMENT REGISTRATION
        function obj2 = register(obj)
            mcInstrumentHandler.open();
            
            obj2 = obj;
            
            params = mcInstrumentHandler.params();
            
            ii = 1;
            
            while ii <= length(params.instruments)
                if isvalid(params.instruments{ii})
                    if (isa(params.instruments{ii}, 'mcAxis') && isa(obj, 'mcAxis')) || (isa(params.instruments{ii}, 'mcInput') && isa(obj, 'mcInput'))
                        if params.instruments{ii} == obj
                            obj2 = params.instruments{ii};
    %                         warning(['The attempted addition "' obj.name() '" is identical to the already-registered "' obj2.name() '." We will use the latter.']); % ' the latter will not be registered, and the former will be used instead.']);
                            return;
                        end
                    end
                else
                    params.instruments(ii) = [];
                    ii = ii - 1;
                end
                
                ii = ii + 1;
            end
            
            params.instruments{end + 1} = obj2;
            
            if isa(obj2, 'mcAxis') && ~strcmpi(obj2.config.kind.kind, 'manual')
                obj2.read();
                obj2.goto(obj2.getX());
            end
            
            mcInstrumentHandler.params(params);
        end 
        
        % UICONTROL REGISTRATION (Unfinished feature!)
        function registerControl(control, controlledInstruments)    % In: uicontrol and cell array of controlled instruments.
            mcInstrumentHandler.open();
            
            params = mcInstrumentHandler.params();
            
            if ~isa(control, 'matlab.ui.control.UIControl')
                error('mcInstrumentHandler.registerControl(control, controlledInstruments): Expected a UIControl as first input...');
            end
            
            if isempty(params.registeredInstruments)
                params.registeredInstruments = containers.Map('UniformValues', false);
            end
            
            for instrument = controlledInstruments
                str = instrument{1}.name();
                
                if params.registeredInstruments.isKey(str)
                    params.registeredInstruments(str) = [params.registeredInstruments(str) {control}];
                else
                    params.registeredInstruments(str) = {control};
                end
            end
            
            mcInstrumentHandler.params(params);
        end
        function setRegisteredControls(instrument, state)
            mcInstrumentHandler.open();
            
            params = mcInstrumentHandler.params();
            
            if ~ischar(state)       % Convert a boolean state to 'on'/'off'...
                if state
                    state = 'on';
                else
                    state = 'off';
                end
            end
            
            if isempty(params.registeredInstruments)
                % No controls to disable...
            else
                str = instrument{1}.name();
                
                if params.registeredInstruments.isKey(str)
                    for control = params.registeredInstruments(str)
                        control{1}.Enable = state;
                    end
                else
                    % No controls to disable...
                end
            end
        end
        
        % CLEAR PARAMS
        function clearAll() % Resets params; Usage not recommended.
            mcInstrumentHandler.open();
            params = mcInstrumentHandler.params();
            
            for instrument = params.instruments
                if isa(instrument{1}, 'mcAxis')% && isa(obj, 'mcAxis')) || (isa(instrument{1}, 'mcInput') && isa(obj, 'mcInput'))
                    instrument{1}.close();
                end
            end
            
            mcInstrumentHandler.params([]);
        end
        
        % KEYPRESSFCN
        function setGlobalWindowKeyPressFcn(fcn)
            mcInstrumentHandler.open();
            
%             mcInstrumentHandler.removeDeadFigures();
            params = mcInstrumentHandler.params();
            params.globalWindowKeyPressFcn = fcn;
            
            for fig = params.figures
                if isvalid(fig{1})
%                 fig.WindowKeyPressFcn = fcn;
                    fig{1}.WindowKeyPressFcn = fcn;
                end
            end
                
            mcInstrumentHandler.params(params);
        end
        function fcn = globalWindowKeyPressFcn()
            mcInstrumentHandler.open();
            params = mcInstrumentHandler.params();
            fcn = params.globalWindowKeyPressFcn;
        end
        
        % RESET DAQ
        function resetDAQ()
            instruments = mcInstrumentHandler.getInstruments();
            
            disp('Resetting DAQ devices:');
            
            for ii = 1:length(instruments)
                if strcmpi(instruments{ii}.config.kind.kind(1:2), 'ni')
                    disp(['    Closing ' instruments{ii}.config.name]);
                    instruments{ii}.close();
                end
            end
            
            daqreset();
            disp('Reset DAQ.');
        end
        
        % FIGURE
        function f = createFigure(obj, toolBarMode)     % Creates a figure that has the proper params.globalWindowKeyPressFcn (e.g. for arrow key control outside of mcUserInput).
            mcInstrumentHandler.open();
            params = mcInstrumentHandler.params();

            if ischar(obj)
                str = obj;
            else
                str = class(obj);
            end
            
            f = figure('NumberTitle', 'off', 'Tag', str, 'Name', str, 'MenuBar', 'none', 'ToolBar', 'none', 'Visible', 'off');    % , 'ToolBar', 'figure');
            
            if isa(obj, 'mcSavableClass')
                
            end
            
%             if isfield(obj, 'config')
%                 if isfield(obj.config, 'gui')
%                     if isfield(obj.config.gui, 'position')
%                         f.Position = obj.config.gui.position;
%                     end
%                 end
%             end
            
            if strcmp(toolBarMode, 'saveopen')
                t = uitoolbar(f, 'tag', 'FigureToolBar');
                
                uipushtool(t, 'TooltipString', 'Open in New Window',  'ClickedCallback', @obj.loadGUI_Callback,    'CData', iconRead(fullfile(params.mcFolder, 'core', 'icons','file_open_new.png')));
%                 uipushtool(t, 'TooltipString', 'Open in This Window', 'ClickedCallback', @obj.loadGUI_Callback,       'CData', iconRead(fullfile(params.mcFolder, 'core', 'icons','file_open.png')));
                
%                 uipushtool(t, 'TooltipString', 'Save As', 'ClickedCallback', @obj.saveAsGUI_Callback, 'CData', iconRead(fullfile(params.mcFolder, 'core', 'icons','file_save_as.png')));
                uipushtool(t, 'TooltipString', 'Save',    'ClickedCallback', @obj.saveGUI_Callback,   'CData', iconRead(fullfile(params.mcFolder, 'core', 'icons','file_save.png')));
            end
            
            if ~isempty(params.globalWindowKeyPressFcn)
                f.WindowKeyPressFcn = params.globalWindowKeyPressFcn;
            end

            params.figures{length(params.figures)+1} = f;
            
            mcInstrumentHandler.params(params);
        end
    end
end




