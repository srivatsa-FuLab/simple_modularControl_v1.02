classdef (Sealed) mcaTemplate < mcAxis          % ** Insert mca<MyNewAxis> name here...
% mcaTemplate aims to explain the essentials for making a custom mcAxis.
%
% 1) To make a custom axis, copy and rename this file to mca<MyNewAxis> where <MyNewAxis> is a descriptive, yet brief name
% for this type of axis (e.g. mcaDAQ for DAQ axes, mcaMicro for Newport Micrometers).
% 2) Next, replace all of the lines starred with '**' with code appropriate for the new type.
%
% Keep in mind the separation between behavior (the content of the methods) and identity (the content of a.config).
%
% There are five (relevant) properties that are pre-defined in mcAxis that the user should be aware of:
%       a.config    % The config structure that should only be used to define the axis identity. *No* runtime information should be stored in config (e.g. serial session).
%       a.s         % This should be used for the persistant runtime axis session, whether serial, NIDAQ, or etc.
%       a.t         % An additional 'timer' session for unusual axes (see mcaMicro for use to poll the micros about the current position).
%       a.extra     % A (currently unused) cell array which should contain the names of the essential custom variables for the config (why isn't this in a.config?).
%       a.x         % Current position of the axis in the *internal* units of the 1D parameterspace.
%       a.xt        % Target position of the axis in the *internal* units of the 1D parameterspace. This is useful for 'slow' axes which do not immdiately reach the destination (e.g. micrometers) for 'fast' axes (e.g. piezos), a.x should always equal a.xt.
%
% Syntax:
%
% + Initialization:
%
%   a = mca<MyNewAxis>()                        % Open with default configuration.
%   a = mca<MyNewAxis>(config)                  % Open with configuration given by the struct 'config'.
%   a = mca<MyNewAxis>('config_file.mat')       % Open with config file in 'MATLAB_PATH\configs\axisconfigs\' (not entirely functional at the moment)
%
%   config = mca<MyNewAxis>.<myType>Config()    % Returns a static config struture for that type (e.g. use as the config struct above).
%   
% + Naming:
%
%   str =   a.name()                            % Returns the default name. This is currently nameShort().
%   str =   a.nameUnits()                       % Returns info about this axis in 'name (units)' form.
%   str =   a.nameShort()                       % Returns short info about this axis in a readable form.
%   str =   a.nameVerb()                        % Returns verbose info about this axis in a readable form.
%
% + Interaction:
%
%   tf =    a.open()                            % Opens a session of the axis (e.g. for the micrometers, a serial session); returns whether open or not.
%   tf =    a.close()                           % Closes the session of the axis; returns whether closed or not.
%
%   tf =    a.inRange(x)                        % Returns true if x is in the external range of a.
%
%   tf =    a.goto(x)                           % If x is in range, makes sure axis is open, moves axis to x, and returns success.
%
%   tf =    a.read()                            % Reads the current position of the axis, returns success. This is useful for 'slow' axes like micrometers where a.xt (the target position) does not match the real position.
%
%   x =     a.getX(x)                           % Returns the position of the axis (a.x) in external units.
%   x =     a.getXt(x)                          % Returns the target position of the axis (a.xt) in external units.
%
% Also see mcAxis.

    methods (Static)    % The folllowing static configs are used to define the identity of axis objects. configs can also be loaded from .mat files
        % ** Change the below so that future users know what neccessary extra variables should be included in custom configs (e.g. 'dev', 'chn', and 'type' for DAQ devices).
        % Neccessary extra vars:
        %  - customVar1
        %  - customVar2
        
        function config = defaultConfig()               % Static config that should be used if no configuration is provided upon intialization.
            config = mcaTemplate.customConfig();        % ** Rename this to whatever static config should be used. Also change mcaTemplate to mca<MyNewAxis>
        end
        function config = customConfig()                % ** Use a descriptive name for this particular 'identity' of mca<MyNewAxis>.
            config.class =              'mcaTemplate';  % ** Change this to 'mca<MyNewAxis>'.
            
            config.name =               'Template';     % ** Change this to the UI name for this identity of mca<MyNewAxis>.

            config.kind.kind =          'template';     % ** Change this to the programatic name that the program should use for this identity of mca<MyNewAxis>.
            config.kind.name =          'Template';     % ** Change this to the technical name (e.g. name of device) for this identity of mca<MyNewAxis>, so a future user looking at a .mat file can figure out what it is.
            config.kind.intRange =      [-42 42];       % ** Change this to the range of the axis (e.g. [0 10] for a 0 -> 10 V DAQ piezo). This is in internal units (.extRange is generated by mcAxis). Use a cell array if the range is not continuous (e.g. on/off would be {0 1})
            config.kind.int2extConv =   @(x)(x);        % ** Change this to the conversion from 'internal' units to 'external'. IMPORTANT: Please remember to use .* and ./ etc becauase these functions may be used on arrays.
            config.kind.ext2intConv =   @(x)(x);        % ** Change this to the conversion from 'external' units to 'internal' (inverse of above).
            config.kind.intUnits =      'units';        % ** Rename these to whatever units are used...     ...internally (e.g. 'V' for DAQ piezos)
            config.kind.extUnits =      'units';        % **                                                ...externally (e.g. 'um' for DAQ piezos)
            config.kind.base =          0;              % ** Change this to the point (in external units) that the axis should seek at startup (future: NaN = don't seek?).
            
            config.keyStep =            .1;             % ** Change this to the speed or step-every-tick (in external units) that this axis should move with...     ...the keyboard and
            config.joyStep =            1;              % **                                                                                                        ...the joystick  (these can be modified in the mcUserInput UI).
            
            config.customVar1 = 'Important Var 1';      % ** The other variables required to define the identity of this axis.
            config.customVar2 = 'Important Var 2';      % ** (e.g. 'port' and 'addr' micrometers).
                                                        % ** More or less than two can be added.
        end
    end
    
    methods             % Initialization method (this is what is called to make an axis object).
        function a = mcaTemplate(varin)                 % ** Insert mca<MyNewAxis> name here...
            a.extra = {'customVar1', 'customVar2'};     % ** Record the names of the custom variables here (These may be used elsewhere in the program in the future).
            if nargin == 0
                a.construct(a.defaultConfig());
            else
                a.construct(varin);
            end
            a = mcInstrumentHandler.register(a);
        end
    end
    
    % These methods overwrite the empty methods defined in mcAxis. These methods are used in the uncapitalized parent methods defined in mcAxis.
    methods
        % NAME ---------- The following functions define the names that the user should use for this axis.
        function str = NameShort(a)     % 'short' name, suitable for UIs/etc.
            str = [a.config.name ' (' a.config.customVar1 ':' a.config.customVar2 ')'];                                                     % ** Change these to your custom vars.
        end
        function str = NameVerb(a)      % 'verbose' name, suitable to explain the identity to future users.
            str = [a.config.name ' (a template for custom mcAxes with custom vars ' a.config.customVar1 ' and ' a.config.customVar2 ')'];   % ** Change these to your custom vars.
        end
        
        %EQ ------------- The function that should return true if the custom vars are the same (future: use a.extra for this?)
        function tf = Eq(a, b)          % Compares two mcaTemplates
            tf = strcmpi(a.config.customVar1,  b.config.customVar1) && strcmpi(a.config.customVar2,  b.config.customVar2);                  % ** Change these to your custom vars, or do whatever neccessary to decide whether two identities are identical.
        end
        
        % OPEN/CLOSE ---- The functions that define how the axis should init/deinitialize (these functions are not used in emulation mode).
        function Open(a)                % Do whatever neccessary to initialize the axis.
            a.s = open(a.config.customVar1, a.config.customVar2);   % ** Change this to the custom code which opens the axis. Keep in mind that a.s should be used to store session info (e.g. serial ports, DAQ sessions). Of course, for some inputs, this is unneccessary.
        end
        function Close(a)               % Do whatever neccessary to deinitialize the axis.
            close(a.config.customVar1, a.config.customVar2);        % ** Change this to the custom code which closes the axis.
        end
        
        % READ ---------- For 'slow' axes that take a while to reach the target position (a.xt), define a way to determine the actual position (a.x). These do *not* have to be defined for 'fast' axes.
        function ReadEmulation(a)       
            a.x = a.xt;         % ** In emulation, just assume the axis is 'fast'?
        end
        function Read(a)
            a.x = read(a.s);    % ** Change this to the code to get the actual postition of the axis.
        end
        
        % GOTO ---------- The 'meat' of the axis: the funtion that translates the user's intended movements to reality.
        function GotoEmulation(a, x)
            a.xt = a.config.kind.ext2intConv(x);    % ** Usually, behavior should not deviate from this default a.GotoEmulation(x) function. Change this if more complex behavior is desired.
            a.x = a.xt;
        end
        function Goto(a, x)
            a.xt = a.config.kind.ext2intConv(x);    % Set the target position a.xt (in internal units) to the user's desired x (in internal units).
            a.x = a.xt;                             % If this axis is 'fast' and immediately advances to the target (e.g. peizos), then set a.x.
            goto(a.s, a.x)                          % ** Change this to be the code that actually moves the axis (also change the above if different behavior is desired).
                                                    % Also note that all 'isInRange' error checking is done in the parent mcAxis.
        end
    end
        
    methods
        % EXTRA --------- Any additional functionality this axis should have (remove if there is none).
        function specificFunction(a)    % ** Rename to a descriptive name for the additional functionality.
            specific(a);                % ** Change to the appropriate code for this additional functionality.
        end
    end
end




