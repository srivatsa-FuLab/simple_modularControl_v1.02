classdef mcAxis < mcSavableClass
% Abstract class for instruments with 1D motion.
%
% Syntax:
%   a = mcAxis()                                % Open with default configuration.
%   a = mcAxis(config)                          % Open with configuration given by config.
%   a = mcAxis('config_file.mat')               % Open with config file in 'MATLAB_PATH\configs\axisconfigs\'
%   a = mcAxis(config, emulate)                 % Same as above, except with the option (boolean) to start axis in emulation mode.
%   a = mcAxis('config_file.mat', emulate)     
%
%   config = mcAxis.<configName>Config()        % Returns a static config struture for that type
%   
%   str =   a.name()                            % Returns the default name. This is currently nameShort().
%   str =   a.nameUnits()                       % Returns info about this axis in 'name (units)' form.
%   str =   a.nameShort()                       % Returns short info about this axis in a readable form.
%   str =   a.nameVerb()                        % Returns verbose info about this axis in a readable form.
%
%   tf =    a.open()                            % Opens a session of the axis (e.g. for the micrometers, a serial session); returns whether open or not.
%   tf =    a.close()                           % Closes the session of the axis; returns whether closed or not.
%
%   tf =    a.inRange(x)                        % Returns true if x is in the external range of a.
%
%   tf =    a.goto(x)                           % If x is in range, makes sure axis is open, moves axis to x, and returns success.
%
%   tf =    a.read(x)                           % Sets a.x to the physical position of the instrument (e.g. poll slow micrometers for current position), and returns success.
%
%   x =     a.getX(x)                           % Returns the position of the axis (internal a.x) in external units.
%   x =     a.getXt(x)                          % Returns the target position of the axis (internal a.xt) in external units.
%
% Status: Finished and mostly commented.

    properties
%         config = [];            % Defined in mcSavableClass. All static variables (e.g. valid range) go in config.
        
        s = [];                 % Session, whether serial, NIDAQ, or etc.
        t = []                  % Timer to read the axis, for certain axes which do not travel immediately.
        
        isOpen = false;         % Boolean.
        inUse = false;          % Boolean.
        inEmulation = false;    % Boolean.
        %inEmulation = true;    % Boolean.
        isObservable = true;    % Boolean. Should update ox and oxt to allow listeners to see the changes.
        scan = []               % Empty struct for scan variables (see startScan, etc).
        
        reservedBy = [];        % Object (unfinished...)
    end
    
    properties
        extra = {};
    end
    
    properties (SetObservable)
        x = 0;                  % Current position (external units).
        xt = 0;                 % Target position (external units).
    end
    
%     properties (SetObservable)
%         ox = 0;                  % Current position.
%         oxt = 0;                 % Target position.
%     end
    
    methods (Static)
        function config = defaultConfig()
            config = mcAxis.timeConfig();
        end
        function config = timeConfig()
            config.class =              'mcAxis';
            
            config.name =               'Time';

            config.kind.kind =          'Time';
            config.kind.name =          'Time';
            config.kind.int2extConv =   @(x)(x);                % Conversion from 'internal' units to 'external'.
            config.kind.ext2intConv =   @(x)(x);                % Conversion from 'external' units to 'internal'.
            
            % Seconds:
%             config.kind.intRange =      [0 Inf];
%             config.kind.intUnits =      's';      % 'Internal' units.
%             config.kind.extUnits =      's';      % 'External' units.
%             config.kind.base =          0;
            
            % Scans:
            config.kind.intRange =      [1 Inf];
            config.kind.intUnits =      'scan #';   % 'Internal' units.
            config.kind.extUnits =      'scan #';   % 'External' units.
            config.kind.base =          1;
            
            % Not sure which one to use...
            
            config.keyStep =            0;
            config.joyStep =            0;
        end
    end
        
    methods
        function a = mcAxis(~)
            if strcmpi(class(a), 'mcAxis')          % If this is the time axis...
                a.construct(a.defaultConfig());
                
                a = mcInstrumentHandler.register(a);
            end
%             if nargin == 0
%                 a.construct(a.defaultConfig());
%             elseif nargin == 1
%                 if isstruct(varin)
%                     a.construct(varin);
%                 else
%                     error('mcAxis(): Configs must be of type struct.');
%                 end
%             end
        end
        
        function construct(a, varin)
            % Constructor
            if iscell(varin)
                config = varin{1};
                
                if length(varin) == 2
                    if islogical(varin{2}) || isnumeric(varin{2})
                        a.inEmulation = varin{2};
                    else
                        warning('Second argument not understood; it needs to be logical or numeric');
                    end
                end
            else
                config = varin;
            end
                    
            if ischar(config)
                if strcmpi(config(end-3:end), '.mat')
                    if isempty(strfind(config, filesep))
                        config = [mcInstrumentHandler.getConfigFolder() class(obj) filesep config];
                    end
                    
                    if exist(config, 'file')
                        vars = load(config);
                        if isfield(vars, 'config')
                            a.config = vars.config;
                        else
                            error('mcAxis.construct(): .mat file given for config has no field config...');
                        end
                    else
                    error(['mcAxis.construct(' config '): File given for config does not exist...']);
                    end
                else
                    error(['mcAxis.construct(' config '): File given for config is not .mat...']);
                end
            elseif isstruct(config)
                a.config = config;
            else
                error('mcAxis(): Not sure how to interpret config in mcAxis(config)...');
            end
            
            if ~isfield(a.config, 'class')
                error('mcAxis(): Class not specified in config. Please specify class.');
            end
            
            if iscell(a.config.kind.intRange)
                a.config.kind.extRange = cellfun(a.config.kind.int2extConv, a.config.kind.intRange, 'UniformOutput', false);
            else
                a.config.kind.extRange = a.config.kind.int2extConv(a.config.kind.intRange);
            end

            params = mcInstrumentHandler.getParams();
            if params.shouldEmulate
                a.inEmulation = true;
            end
            
            a.x = a.config.kind.base;
            a.xt = a.x;
        end
        
        function tf = eq(a, b)      % Check if a foreign object (b) has the same properties as this axis object (a).
            if ~(isvalid(a) && isvalid(b))
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
            
            if strcmpi(a.config.kind.kind, b.config.kind.kind)     % If they are the same kind...
                tf = a.Eq(b);
            else
                tf = false;
            end
        end
   
        function str = name(a)
            str = a.nameShort();
        end
        function str = nameUnits(a) % Returns description in 'name (units)' form.
            str = [a.config.name ' (' a.config.kind.extUnits ')'];
        end
        function str = nameRange(a) % Returns description in 'nRange: rmin to rmax (units)' form.
            if iscell(a.config.kind.extRange)
                str = ['Allowed Values: ' strjoin(cellfun(@(x)([num2str(x) ',' ]), a.config.kind.extRange(1:end-1), 'UniformOutput', false)) ' or ' num2str(a.config.kind.extRange{end}) ' (' a.config.kind.extUnits ')'];
            else
                str = ['Range: ' num2str(a.config.kind.extRange(1)) ' to ' num2str(a.config.kind.extRange(2)) ' (' a.config.kind.extUnits ')'];
            end
        end
        function str = nameShort(a) % Returns description in 'name (info1:info2:...)' form with ' (Emulation)' if emulating.
            if a.inEmulation
                str = [a.NameShort() ' (Emulation)'];
            else
                str = a.NameShort();
            end
        end
        function str = nameVerb(a)  % Returns a more-detailed description of the Axis.
            if a.inEmulation
                str = [a.NameVerb() ' (Emulation)'];
            else
                str = a.NameVerb();
            end
        end
        
        function tf = open(a)       % Opens a session of the axis (e.g. for the micrometers, a serial session); returns whether open or not.
            if a.isOpen
%                 warning([a.name() ' is already open...']);
                tf = true;     % Return true because axis is open already.
            elseif a.inUse
                warning([a.name() ' is already in use...']);
                tf = false;
            else
                a.isOpen = true;
                a.inUse = true;
                
                if a.inEmulation
                    % Should something be done?
                    tf = true;
                else
                    try
                        a.Open();
                        tf = true;     % Return true because axis has been opened.
                    catch err
%                         disp(['mcAxis.open() - ' a.config.name ': ' err.message]);
                        tf = false;
                    end
                end
            end
        end
        function tf = close(a)      % Closes the session of the axis; returns whether closed or not.
            if a.isOpen
                a.isOpen = false;
                a.inUse = false;
                
                if a.inEmulation
                    % Should something be done?
                    tf = true;
                else
                    try
                        a.Close();
%                         disp('mcAxis was closed');
                        tf = true;     % Return true because axis was open and is now closed.
                    catch err
                        disp(['mcAxis.close() - ' a.config.name ': ' err.message]);
                        tf = false;
                    end
                end
            elseif a.inUse
                warning([a.name() ' is in use elsewhere and cannot be used...']);
                tf = false;     % Return false because axis is in use by something else.
            else
%                 warning([a.name() ' is not open; nothing to close...']);
                tf = true;     % Return true because axis is closed already.
            end
        end
        
        function x = getX(a)        % Returns the value of a.x in external units.
            a.read();
            x = a.config.kind.int2extConv(a.x);
        end
        function x = getXt(a)       % Returns the value of a.xt in external units.
            x = a.config.kind.int2extConv(a.xt);
        end
        
        function tf = read(a)       % Reads the value of a.x internally; Returns success.
            tf = true;
            
            if ~a.inUse || (a.isOpen && a.inUse)    % If the axis is not in use by another process (i.e. a process other than itself)
                if a.open()
                    if a.inEmulation
                        a.ReadEmulation();
                    else
                        a.Read();
                    end
                else
                    tf = false;
                end
            else
                tf = false;
            end
        end
        
        function tf = inRange(a, x)
            if iscell(a.config.kind.extRange)
                switch x
                    case a.config.kind.extRange
                        tf = true;
                    otherwise
                        tf = false;
                end
            else
                tf = x <= max(a.config.kind.extRange) && x >= min(a.config.kind.extRange);
            end
        end
        
        function tf = goto(a, x)    % If x is in range, makes sure axis is open, moves axis to x, and returns success.
            tf = true;
            
            if isnan(x)
                tf = false;
            else
                if a.inRange(x)
                    if a.open()
                        if a.config.kind.ext2intConv(x) ~= a.xt  % If we aren't already at the desired value (change? there might be cases where this feature is undesirable.
                            if a.inEmulation
                                a.GotoEmulation(x);
                            else
                                a.Goto(x);
                            end
                        
                            a.read();
                        end
                    else
                        tf = false;
                    end
                else
                    tf = false;
                end
            end
        end
        
        function tf = reserve(a, reservedBy)    % Returns whether the axis was successfully reserved by the object.
            tf = false;
            
            if ~a.isReserved()
                a.isReserved = reservedBy;
                tf = true;
            end
        end
        function tf = isReserved(a) % Returns whether the axis is currently reserved by a valid object.
            tf = isvalid(a.reservedBy);
            
            if ~tf
                a.reservedBy = [];
            end
        end
        function str = reservedByStr(a)         % Returns the name of the reserving object.
            if isempty(a.reservedBy)
                str = 'Axis is not currently reserved.';
            else
                str = class(a.reservedBy);
            end
        end
        
        function wait(a)            % Wait for the axis to reach the target value.
            % Generalize this!
            
            a.read();               % Remove possibility of delay if the axis is already there but has not been read...
                
            switch a.config.kind.kind
                case 'grid'
                    a.config.grid.wait();               % ...then use the virtual grid wait() function.
                case {'time', 'aptcontrol', 'eopizeo'}
                    % Do nothing.
                otherwise
                    while a.x ~= a.xt       % Make it a 'difference less than tolerance'?
                        a.read();
                        pause(.1);
                    end
            end
            
%             if strcmpi(a.config.kind.kind, 'grid')  % If it is a virtual grid axis...
%                 a.config.grid.wait();               % ...then use the virtual grid wait() function.
%             elseif  strcmpi(a.config.kind.kind, 'time')
%                 % Do nothing.
%             else
%                 if strcmpi(a.config.kind.kind, 'aptcontrol')
%                     while round(mod(a.x - a.xt, 360), 3) ~= 0
%                         a.read();
%                         pause(.1);
%                     end
%                 else
%                     while a.x ~= a.xt       % Make it a 'difference less than tolerance'?
%                         a.read();
%                         pause(.1);
%                     end
%                 end
%             end
        end
        
        function info = getInfo(a)  % (Currently unused)
%             {'Instrument', 'Position', 'Unit', 'isOpen',   'inUse',    'inEmulation'};
            info = {a.name(), a.getX(), a.extUnits, a.isOpen, a.inUse, a.inEmulation, '', '', '', ''};
            
            ii = 7;
            for var = a.extra
                if ii <= 10
                    info{ii} = get(a.config, var);
                    ii = ii + 1;
                end
            end
        end
        
        function startScan(a, amp, type)
            % Makes the axis scan in a wave (`type` = 'sine', 'sawtooth') with amplitude `amp` (external units) about the
            %   current position. This amplitude is truncated if it would go out of range. Returns whether the scan started. If
            %   a linear scan is currently running, then the parameters (e.g. `amp`, `type`) are changed accordingly.
            
            error('mcAxis.startScan(): Unfinished');
            
            if ~isnumeric(amp)
                error('mcAxis.startScan(): Amplitude `amp` must be numeric.')
            end
            
            if amp == 0
                if ~isempty(a.scan)
                    a.stopScan();
                end

                return;
            elseif amp < 0
                amp = -amp;
                warning('mcAxis.startScan(): Negative amplitude was given; taking the absolute value.');
            end

            if ~a.inRange(a.x - amp)
                amp = abs(a.x - min(a.config.kind.extRange));
                warning('mcAxis.startScan(): Lower bound of scan was out of range.');
            end
            if ~a.inRange(a.x + amp)
                amp = abs(a.x - max(a.config.kind.extRange));
                warning('mcAxis.startScan(): Upper bound of scan was out of range.');
            end

            if amp == 0
                warning('mcAxis.startScan(): Cannot start at scan at the edge of range (such a scan would be no fun).');
            end
            
            
            if a.close()            % Make sure the axis is closed before we start messing with it.
                a.inUse

                makeNew = isempty(a.scan);

                if makeNew

                end
            end
        end
        function sineFill_Callback(a, ~, ~)                 % This should *never* be called by the user.
            
            error('mcAxis.sineFill_Callback(): Unfinished');
            
            if a.scan.isScanning
                
            else
                a.scan.s.wait();
                delete(a.scan.s);
                
                a.scan =    [];
                a.inUse =   false;
            end
        end
        function stopScan(a)
            
            error('mcAxis.stopScan(): Unfinished');
            
            a.scan.isScanning = false;
        end
    end
    
    methods     % To be defined by the daughter mca<Name>.
        function tf = Eq(~, ~)
            tf = true;     % or false?
        end
        
        function str = NameShort(a)
            str = a.config.name;
        end
        function str = NameVerb(a)
            str = a.config.name;
        end
        
        function Open(~)
        end
        function Close(~)
        end
        
        function ReadEmulation(~, ~)
        end
        function Read(~, ~)
        end
        
        function GotoEmulation(~, ~)
        end
        function Goto(~, ~)
        end
    end
end




