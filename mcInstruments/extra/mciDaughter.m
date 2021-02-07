classdef mciDaughter < mcInput
% mciDaughter reads the current value of property 'var' in some parent object 'parent'. This allows, for instance,  mcInputs with
% multiple data values to be read.
%
% Also see mcInput.

    methods (Static)    % The folllowing static configs are used to define the identity of input objects. configs can also be loaded from .mat files
        % Neccessary extra vars:
        %  - parent
        %  - var
        
        function config = defaultConfig()               % Static config that should be used if no configuration is provided upon intialization.
            config = mciDaughter.daughterConfig(mcAxis(), 'x', [1 1], 'scans ago'); % Fake...
        end
        function config = daughterConfig(parent, var, expectedSize, units)
            config.class = 'mciDaughter';

            config.kind.kind =          'daughter';
            config.kind.name =          ['Daughter of ' parent.name '(.' var ')'];
            config.kind.shouldNormalize = false;
            
            config.kind.extUnits =      units;
            config.kind.sizeInput =     expectedSize; %[1 1];
            
            % Parent error checking.
%             if isfield(parent, 'config')
%                 c = class(parent);
%                 parent = parent.config;
%                 parent.class = c;
%             end
            
%             if ~isfield(parent, 'class')
%                 error('mciDaughter.daughterConfig(): Parent must have field config.class.');    % Change? This only makes sense if we are dealing with registered instruments (mcAxes and mcInputs). Generalize to all classes?
%             end
            
            config.parent = parent;
            
            % Var error checking.
            if ~ischar(var)
                error('mciDaughter.daughterConfig(): Expected var to be a string pointing to a property of the parent mcInput')
            end
            
            config.var =    var;
            
            % Naming
            config.name = [parent.name ' (' config.var ')'];
        end
    end
    
    methods             % Initialization method (this is what is called to make an input object).
        function I = mciDaughter(varin)
            I.extra = {'parent', 'var'};
            if nargin == 0
                I.construct(I.defaultConfig());
            else
                I.construct(varin);
            end
            
            I = mcInstrumentHandler.register(I);
            
            I.inEmulation = false;      % Never emulate...
        end
    end
    

    % These methods overwrite the empty methods defined in mcInput. These methods are used in the uncapitalized parent methods defined in mcInput.
    methods
        % NAME ---------- The following functions define the names that the user should use for this input.
        function str = NameShort(I)     % 'short' name, suitable for UIs/etc.
            str = I.config.name;
        end
        function str = NameVerb(I)      % 'verbose' name, suitable to explain the identity to future users.
            str = [I.config.name ' (a daugter of ' I.config.parent.name ' pointing at the property ' I.config.var ' )'];
        end
        
        %EQ ------------- The function that should return true if the custom vars are the same (future: use i.extra for this?)
        function tf = Eq(I, b)          % Compares two mciDaughters
            tf =    strcmpi(I.config.parent.name,  b.config.parent.name) &&... % Change? Do this properly with the eq method of the class, instead of the config struct?
                    strcmp(I.config.var,  b.config.var);  % Remove!
        end

        % OPEN/CLOSE ---- The functions that define how the input should init/deinitialize (these functions are not used in emulation mode).
        function Open(I)                % Do whatever neccessary to initialize the input.
            c = I.config.parent;
            
            if isprop(c, 'config')      % ...in case the given parent was an mcInstrument object instead of an mcInstrument config...
                c = c.config;
            end
            
            if isfield(c, 'class')
                I.s = eval([c.class '(c)']);    % Make the parent...
%                 in = I.s
                I.s.open();                     % ...and open it.
            else
                error('mciDaugter(): Config given without class.');
            end
        end
        function Close(~)               % Do whatever neccessary to deinitialize the input.
            % Do nothing. The parent should not be closed because it might be doing something elsewhere.
        end
        
        % MEASURE ------- The 'meat' of the input: the funtion that actually does the measurement and 'inputs' the data. Ignore integration time (with ~) if there should not be one.
        function data = MeasureEmulation(I, integrationTime)
            data = I.Measure(integrationTime);
        end
        function data = Measure(I, ~)
            % How to incorporate integrationTime? Have a prevTime property in mcInput to compare with?

            I.close();
            I.open();
            try
                data = eval(['I.s.' I.config.var]);     % We use eval here instead of I.s.(var) because var might be a subfield (e.g. I.s.c.c) instead of just a field (e.g. I.s.c).
            catch
                data = NaN(I.config.kind.sizeInput);
            end
        end
    end
end




