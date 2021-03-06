classdef mcInput < mcSavableClass
% Abstract class for instruments with that measure some sort of data. This includes:
%   - NIDAQ
%       + Counters
%       + Analog/Digital in
%   - Spectrometers
%   - Cameras
%
% Syntax:
%   I = mcInput()                               % Open with default configuration.
%   I = mcInput(config)                         % Open with configuration given by config.
%   I = mcInput('config_file.mat')              % Open with config file in 'MATLAB_PATH\configs\axisconfigs\'
%   I = mcInput(config, emulate)                % Same as above, except with the option (tf) to start axis in emulation mode.
%   I = mcInput('config_file.mat', emulate)     
%
%   config = mcInput.[INSERT_TYPE]Config        % Returns the default config struture for that type
%   
%   str =   I.name()                            % Returns the default name. This is currently nameShort().
%   str =   I.nameUnits()                       % Returns info about this input in 'name (units)' form.
%   str =   I.nameShort()                       % Returns short info about this input in a readable form.
%   str =   I.nameVerb()                        % Returns verbose info about this input in a readable form.
%
%   tf =    I.open()                            % Opens a session of the input (e.g. for a counter, a NIDAQ session); returns whether open or not.
%   tf =    I.close()                           % Closes the session of the input; returns whether closed or not.
%
%   data =  I.measure(integrationTime)          % Measures the input for integrationTime seconds and returns the result.
%
% Status: Mostly finished. Mostly commented.
%
    properties
%         config = [];            % Defined in mcSavableClass. All static variables (e.g. valid range) go in config.
        
        s = [];                 % Session, whether serial or NIDAQ.
        
        isOpen = false;         % Boolean.
        inUse = false;          % Boolean.
        inEmulation = true;    % Boolean.
        isMeasuring = false;
    end

    properties
        extra = {};
    end
    
    methods
        function construct(I, varin)        % Construct the input using info from varin
            % Constructor
            if iscell(varin)                % If varin is a cell...
                config = varin{1};          % ...assume that config is the first object in the cell...
                
                if length(varin) == 2       % ...and use any second boolean-like object as an enumaltion flag.
                    if islogical(varin{2}) || isnumeric(varin{2})
                        I.inEmulation = varin{2};
                    else
                        warning('mcInput.construct(): Second argument not understood; it needs to be logical or numeric');
                    end
                end
            else                            % If varin is not a cell,
                config = varin;
            end
                    
            if ischar(config)               % If we are given a string, assume that it is the path to the config (in .mat form)
                if strcmpi(config(end-3:end), '.mat')
                    if isempty(strfind(config, filesep))
                        config = [mcInstrumentHandler.getConfigFolder() class(obj) filesep config];
                    end
                    
                    if exist(config, 'file')
                        vars = load(config);
                        if isfield(vars, 'config')
                            I.config = vars.config;
                        else
                            error('mcInput.construct(): .mat file given for config has no field config...');
                        end
                    else
                    error(['mcInput.construct(' config '): File given for config does not exist...']);
                    end
                else
                    error(['mcInput.construct(' config '): File given for config is not .mat...']);
                end
            elseif isstruct(config)
                I.config = config;
            else
                error('mcInput.construct(): Not sure how to interpret config in mcInput(config)...');
            end
            
            params = mcInstrumentHandler.getParams();
            if params.shouldEmulate
                I.inEmulation = true;
            end
        end
        
%         function I = mcInput(varin)
% %             if strcmpi(class(I), 'mcInput')
% %                 I = mcInstrumentHandler.register(I);
% %             end
%             
%             % Constructor 
% %             switch nargin
% %                 case 0
% %                     I.config = I.defaultConfig();
% %                 case {1, 2}
% %                     if nargin == 1
% %                         config = varin;
% %                     else
% %                         config = varin{1};
% %                     end
% %                     
% %                     if ischar(config)
% %                         if exist(config, 'file') && strcmp(config(end-3:end), '.mat')
% %                             vars = load(config);
% %                             if isfield(vars, 'config')
% %                                 I.config = vars.config;
% %                             else
% %                                 error('.mat file given for config has no field config...');
% %                             end
% %                         else
% %                         	error('File given for config does not exist or is not .mat...');
% %                         end
% %                     elseif isstruct(config)
% %                         I.config = config;
% %                     else
% %                         error('Not sure how to interpret config in mcInput(config)...');
% %                     end
% %                     
% %                     if nargin == 2
% %                         if islogical(varin{2}) || isnumeric(varin{2})
% %                             I.inEmulation = varin{2};
% %                         else
% %                             warning('Second argument not understood; it needs to be logical or numeric');
% %                         end
% %                     end
% %             end
% %             
% %             params = mcInstrumentHandler.getParams();
% %             if ismac || params.shouldEmulate
% %                 I.inEmulation = true;
% %             end
% %             
% %             I = mcInstrumentHandler.register(I);
%         end
        
        function tf = eq(I, b)  % Check if a foriegn object (b) is equal to this input object (a).
            if ~isvalid(I) || ~isvalid(b)
                tf = false; return;
            end
            
            if ~isprop(b, 'config')     % Make sure that b.config.kind.kind exists...
                tf = false; return;
            else
                if ~isfield(b.config, 'kind')
                    tf = false; return;
                else
                    if ~isfield(b.config.kind, 'kind')
                        tf = false; return;
                    end
                end
            end
            
            if strcmp(I.config.kind.kind, b.config.kind.kind)               % If they are the same kind...
                tf = I.Eq(b);
            else
                tf = false;
            end
        end
        
        function str = name(I)
            str = I.nameShort();
        end
        function str = nameUnits(I)
            str = [I.config.name ' (' I.config.kind.extUnits ')'];
        end
        function str = nameShort(I)
            if I.inEmulation
                str = [I.NameShort() ' (Emulation)'];
            else
                str = I.NameShort();
            end
        end
        function str = nameVerb(I)
            if I.inEmulation
                str = [I.NameVerb() ' (Emulation)'];
            else
                str = I.NameVerb();
            end
        end
        
        function tf = open(I)           % Opens a session of the input; returns whether open or not.
            if I.isOpen
%                 warning([I.name() ' is already open...']);
                tf = true;
            elseif I.inUse
                warning([I.name() ' is already in use...']);
                tf = false;
            else
                if I.inEmulation
                    % Do something?
                    tf = true;
                else
                    try
%                         'here'
                        I.Open();
                        tf = true;     % Return true because axis has been opened.
                    catch err
                        warning(['mcInput.open() - ' I.config.name ': ' err.message]);
                        tf = false;
                    end
                end
                
                I.isOpen = true;
                I.inUse = true;
            end
        end
        function tf = close(I)          % Closes the session of the axis; returns whether closed or not.
            if I.isOpen
                if I.inEmulation
                    % Should something be done?
                    tf = true; 
                else
                    try
                        I.Close();
                        tf = true;     % Return true because axis has been opened.
                    catch err
                        disp(['mcInput.open() - ' I.config.name ': ' err.message]);
                        tf = false;
                    end
                end
                
                I.isOpen = false;
                I.inUse = false;
            elseif I.inUse
                warning([I.name() ' is in use elsewhere and cannot be used...']);
                tf = false;     % Return false because input is in use by something else.
            else
%                 warning([I.name() ' is not open; nothing to close...']);
                tf = true;     % Return true because input is closed already.
            end
        end
        
        function data = measure(I, integrationTime)
            I.isMeasuring = false;
            if I.open()
                if ~I.isMeasuring
                    if nargin == 1
                        integrationTime = 1;
                    end
                    
                    I.isMeasuring = true;

%                     try
                    if I.inEmulation
                        data = I.MeasureEmulation(integrationTime);
                    else
                        data = I.Measure(integrationTime);
                    end
%                     catch err
%                         warning(['mcInput - ' I.config.name ': ' err.message]);
%                     end

                    I.isMeasuring = false;

                    if length(size(data)) ~= length(I.config.kind.sizeInput)
                        warning(['mcInput - ' I.config.name ': measured data has unexpected size of [' num2str(size(data)) '] vs [' num2str(I.config.kind.sizeInput) ']...']);
                        data = NaN(I.config.kind.sizeInput);
                        return;
                    end
                    
                    if ~( all(size(data) == I.config.kind.sizeInput) || all(size(data) == I.config.kind.sizeInput(end:-1:1)) )  % Check for flipping...
                        warning(['mcInput - ' I.config.name ': measured data has unexpected size of [' num2str(size(data)) '] vs [' num2str(I.config.kind.sizeInput) ']...']);
                        data = NaN(I.config.kind.sizeInput);
                    end
                else
                    data = NaN(I.config.kind.sizeInput);
                    warning(['mcInput - ' I.config.name ': could not measure, already measuring']);
                end
            else
                data = NaN(I.config.kind.sizeInput);
                warning(['mcInput - ' I.config.name ': could not open input...']);
            end
        end
        
        function scans = getInputScans(I)        % scans is a cell array containing the scans for each dimension. By default, axes go from 1 to axis dim pixels.
            if all(I.config.kind.sizeInput == 1)
                scans = [];
            else
                nonsingular = I.config.kind.sizeInput(I.config.kind.sizeInput ~= 1);
                scans = cell(1, length(nonsingular));
                
                for ii = 1:length(nonsingular)
                    scans{ii} = 1:nonsingular(ii);
                end
            end
        end
        
        function units = getInputScanUnits(I)   % units is a cell array containing the units for each axis dim. By default, units are pixels.
            if all(I.config.kind.sizeInput == 1)
                units = [];
            else
                numnonsingular = length(I.config.kind.sizeInput(I.config.kind.sizeInput ~= 1));
                units = cell(1, numnonsingular);
                
                for ii = 1:numnonsingular
                    units{ii} = 'pixels';
                end
            end
        end
        
        function info = getInfo(I)
%             {'Instrument', 'Position', 'Unit', 'isOpen',   'inUse',    'inEmulation'};
            info = {I.name(), '---', I.extUnits, I.isOpen, I.inUse, I.inEmulation, '', '', '', ''};
            
            ii = 7;
            for var = I.extra
                if ii <= 10
                    info{ii} = get(I.config, var);
                    ii = ii + 1;
                end
            end
        end
    end
    
    methods
        % EQ
        function tf = Eq(~, ~)
            tf = false;     % or true?
        end
        
        % NAME
        function str = NameShort(~)
            str = '';
        end
        function str = NameVerb(~)
            str = '';
        end
        
        % OPEN/CLOSE
        function Open(~)
        end
        function Close(~)
        end
        
        % MEASURE
        function data = MeasureEmulation(~, ~)
            data = NaN(I.config.kind.sizeInput);
        end
        function data = Measure(~, ~)
            data = NaN(I.config.kind.sizeInput);
        end
    end
end




