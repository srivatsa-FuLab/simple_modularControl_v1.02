classdef mciFunction < mcInput
% mciFunction is the subclass of mcInput that wraps (near) arbitrary functions.
%
% Also see mcaTemplate and mcAxis.
%
% Status: Finished. Reasonably commented.

    methods (Static)
        % Neccessary extra vars:
        %  - fnc
        %  - description
        % Calcualted extra vars:
        %  - giveIntegration
        
        function config = defaultConfig()
            config = mciFunction.randConfig();
        end
        function config = randConfig()
            config.class = 'mciFunction';
            
            config.name =               'rand()';

            config.kind.kind =          'function';
            config.kind.name =          'rand()';
            config.kind.extUnits =      'arb';                  % 'External' units.
            config.kind.normalize =     false;
            config.kind.sizeInput =     [1 1];
            
            config.fnc =                @rand;
            config.description =        'wraps the MATLAB rand() function';
        end
        function config = testConfig()
            config.class = 'mciFunction';
            
            config.name =               'Test Input';

            config.kind.kind =          'function';
            config.kind.name =          'Large-Dimension Test Input';
            config.kind.extUnits =      'arb';                  % 'External' units.
            config.kind.normalize =     false;
            config.kind.sizeInput =     [13 10 10 8];
            
            config.fnc =                @()(rand(config.kind.sizeInput));
            config.description =        'rand()';
        end
    end
    
    methods
        function I = mciFunction(varin)
            I.extra = {'fnc', 'description'};
            if nargin == 0
                I.construct(I.defaultConfig());
            else
                I.construct(varin);
            end
            I = mcInstrumentHandler.register(I);
            I.config.giveIntegration = nargin(I.config.fnc) > 0;    % Internal variable to decide whether the integration time in I.measure(integrationTime) should be passed to the mciFunction function as an input.
        end
    end
    
    % These methods overwrite the empty methods defined in mcInput. mcInput will use these. The capitalized methods are used in
    %   more-complex methods defined in mcInput.
    methods
        % EQ
        function tf = Eq(~, ~)      % Check if a foriegn object (b) is equal to this input object (I).
            tf = false;     % Function inputs are benign.   %isequal(I.config.fnc,  b.config.fnc);
        end
        
        % NAME
        function str = NameShort(I)
            str = [I.config.name ' (' I.config.description ')'];
        end
        function str = NameVerb(I)
            str = [I.config.name ' (function input with description: ' I.config.description ')'];
        end
        
        % OPEN/CLOSE uneccessary.
        
        % MEASURE
        function data = MeasureEmulation(I, integrationTime)
             data = I.Measure(integrationTime);
        end
        function data = Measure(I, integrationTime)
            if I.config.giveIntegration
                data = I.config.fnc(integrationTime);
            else
                data = I.config.fnc();
                pause(integrationTime);
            end
        end
    end
end




