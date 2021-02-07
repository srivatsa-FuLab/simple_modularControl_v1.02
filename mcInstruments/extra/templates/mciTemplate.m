classdef mciTemplate < mcInput              % ** Insert mci<MyNewInput> name here...
% mciTemplate aims to explain the essentials for making a custom mcInput.
%
% 1) To make a custom input, copy and rename this file to mci<MyNewInput> where <MyNewInput> is a descriptive, yet brief name
% for this type of input (e.g. mciDAQ for DAQ inputs, mciNIGPIB for a National Instruments GPIB device).
% 2) Next, replace all of the lines starred with '**' with code appropriate for the new type.
%
% Keep in mind the separation between behavior (the content of the methods) and identity (the content of i.config).
%
% There are five (relevant) properties that are pre-defined in mcInput that the user should be aware of:
%       i.config    % The config structure that should only be used to define the input identity. *No* runtime information should be stored in config (e.g. serial session).
%       i.s         % This should be used for the persistant input session, whether serial, NIDAQ, or etc.
%       i.extra     % A (currently unused) cell array which should contain the names of the essential custom variables for the config (why isn't this in i.config?).
%
% Syntax:
%   I = mci<MyNewInput>()                       % Open with default configuration.
%   I = mci<MyNewInput>(config)                 % Open with configuration given by config.
%   I = mci<MyNewInput>('config_file.mat')      % Open with config file in 'MATLAB_PATH\configs\inputconfigs\' (not entirely functional at the moment)
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
%   data =  I.measure(integrationTime)          % Measures the input for integrationTime seconds and returns the result. If an time for integration is not appropriate for this input, then integration time is ignored.
%
%   tf =    I.addToSession(s)                   % If the input is NIDAQ, adds the input to the NIDAQ session s.
%
% Also see mcInput.

    methods (Static)    % The folllowing static configs are used to define the identity of input objects. configs can also be loaded from .mat files
        % ** Change the below so that future users know what neccessary extra variables should be included in custom configs (e.g. 'dev', 'chn', and 'type' for DAQ devices).
        % Neccessary extra vars:
        %  - customVar1
        %  - customVar2
        
        function config = defaultConfig()               % Static config that should be used if no configuration is provided upon intialization.
            config = mciTemplate.customConfig();        % ** Rename this to whatever static config should be used.
        end
        function config = customConfig()                % ** Use a descriptive name for this particular 'identity' of mci<MyNewInput>.
            config.class = 'mciTemplate';
            
            config.name = 'Template';                   % ** Change this to the UI name for this identity of mci<MyNewInput>.

            config.kind.kind =          'template';     % ** Change this to the programatic name that the program should use for this identity of mci<MyNewInput>.
            config.kind.name =          'Template';     % ** Change this to the technical name (e.g. name of device) for this identity of mci<MyNewInput>.
            config.kind.intUnits =      'units';        % ** Rename these to whatever units are used (e.g. counts).
            config.kind.shouldNormalize = false;        % (Not sure if this is functional.) If this variable is flagged, the measurement is subtracted from the previous and is divided by the time spent on a pixel. Not that this is done outside the measurement currently in mcData (individual calls to .measure() will not have this behavior currently)
            config.kind.sizeInput =    [1 1];           % ** The size (i.e. dimension) of the measurement. For a spectrum, this might be [512 1], a vector 512 pixels long. For a camera, this might be [1280 720]. Future: make NaN functional for dimensions of unknown length (e.g. a string of unknown length).
            
            config.customVar1 = 'Important Var 1';      % ** The other variables required to define the identity of this input.
            config.customVar2 = 'Important Var 2';      % ** (e.g. 'dev', 'chn', and 'type' for DAQ inputs).
                                                        % ** More or less than two can be added.

        end
    end
    
    methods             % Initialization method (this is what is called to make an input object).
        function I = mciTemplate(varin)                 % ** Insert mci<MyNewInput> name here...
            I.extra = {'customVar1', 'customVar2'};     % ** Record the names of the custom variables here (These may be used elsewhere in the program in the future).
            if nargin == 0
                I.construct(I.defaultConfig());
            else
                I.construct(varin);
            end
            I = mcInstrumentHandler.register(I);
        end
    end
    

    % These methods overwrite the empty methods defined in mcInput. These methods are used in the uncapitalized parent methods defined in mcInput.
    methods
        % NAME ---------- The following functions define the names that the user should use for this input.
        function str = NameShort(I)     % 'short' name, suitable for UIs/etc.
            str = [I.config.name ' (' I.config.customVar1 ':' I.config.customVar2 ')'];                                                     % ** Change these to your custom vars.
        end
        function str = NameVerb(I)      % 'verbose' name, suitable to explain the identity to future users.
            str = [I.config.name ' (a template for custom mcInput with custom vars ' I.config.customVar1 ' and ' I.config.customVar2 ')'];  % ** Change these to your custom vars.
        end
        
        %EQ ------------- The function that should return true if the custom vars are the same (future: use i.extra for this?)
        function tf = Eq(I, b)          % Compares two mciTemplates
            tf = strcmpi(I.config.customVar1,  b.config.customVar1) && strcmpi(I.config.customVar2,  b.config.customVar2);                  % ** Change these to your custom vars, or do whatever neccessary to decide whether two identities are identical.
        end

        % OPEN/CLOSE ---- The functions that define how the input should init/deinitialize (these functions are not used in emulation mode).
        function Open(I)                % Do whatever neccessary to initialize the input.
            I.s = open(I.config.customVar1, I.config.customVar2);   % ** Change this to the custom code which opens the input. Keep in mind that I.s should be used to store session info (e.g. serial ports, DAQ sessions). Of course, for some inputs, this is unneccessary.
        end
        function Close(I)               % Do whatever neccessary to deinitialize the input.
            close(I.config.customVar1, I.config.customVar2);        % ** Change this to the custom code which closes the input.
        end
        
        % MEASURE ------- The 'meat' of the input: the funtion that actually does the measurement and 'inputs' the data. Ignore integration time (with ~) if there should not be one.
        function data = MeasureEmulation(I, integrationTime)
            data = rand(I.config.kind.sizeInput)*integrationTime;   % ** Change this to code that mimics the expected input. Add noise for realism.
        end
        function data = Measure(I, integrationTime)
            data = getData(I.s, integrationTime);                   % ** Change this to be the code that aquires the data.
        end
    end
    
    methods
        % EXTRA --------- Any additional functionality this input should have (remove if there is none).
        function specificFunction(I)    % ** Rename to a descriptive name for the additional functionality.
            specific(I);                % ** Change to the appropriate code for this additional functionality.
        end
    end
end




