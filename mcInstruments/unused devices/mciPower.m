classdef mciPower < mcInput
% mciPower combines a mcInput for power reading and a mcAxis controlling a flip mirror to the
% powermeter for seamless power measurement.
%
% Also see mcaTemplate and mcAxis.
%
% Status: Probably will replace this...

    methods (Static)
        % Neccessary extra vars:
        %  - power  (mcInput)
        %  - flip   (mcAxis)
        
        function config = defaultConfig()
            config = mciPower.diamondConfig();
        end
        function config = diamondConfig()
            config.class = 'mciPower';
            
            config.name = 'Powermeter';
            
            config.power =  mciNIGPIB();
            
            flipConfig =        mcaDAQ.digitalConfig();
            flipConfig.chn = 	'Port0/Line1';
            flipConfig.name = 	'Flip Mirror';
            config.flip =       mcaDAQ(flipConfig);

            config.kind.kind =          'mciPower';
            config.kind.name =          'Interjecting Powermeter';
            config.kind.extUnits =      config.power.config.kind.extUnits; % 'External' units.
            config.kind.shouldNormalize = false;                    % If this variable is flagged, the measurement is subtracted from the previous and is divided by the time spent on a pixel. Not that this is done outside the measurement currently in mcData (individual calls to .measure() will not have this behavior currently)
            config.kind.sizeInput =     config.power.config.kind.sizeInput;
        end
    end
    
    methods
        function I = mciPower(varin)
            I.extra = {'power', 'flip'};
            if nargin == 0
                I.construct(I.defaultConfig());
            else
                I.construct(varin);
            end
            I = mcInstrumentHandler.register(I);
        end
    end
    
    % These methods overwrite the empty methods defined in mcInput. mcInput will use these. The capitalized methods are used in
    %   more-complex methods defined in mcInput.
    methods
        % EQ
        function tf = Eq(I, b)  % Check if a foriegn object (b) is equal to this input object (a).
            tf = I.config.power == b.config.power && I.config.flip == b.config.flip;
        end
        
        % NAME
        function str = NameShort(I)
            % This is the reccommended a.nameShort().
            str = [I.config.name ' [' I.config.power.nameShort() ':' I.config.flip.nameShort() ']'];
        end
        function str = NameVerb(I)
            str = [I.config.name ' [a axis-input combination consisting of ' I.config.power.nameShort() ' and ' I.config.flip.nameShort() ']'];
        end
        
        % OPEN/CLOSE
        function Open(I)
            I.config.power.open();
            I.config.flip.open();
        end
        function Close(I)
            I.config.power.close();
            I.config.flip.close();
        end
        
        % MEASURE
        function data = MeasureEmulation(I, ~)
            data = rand(I.config.kind.sizeInput);
        end
        function data = Measure(I, ~)
            prevX = I.config.flip.getX();       % Get the previous state of the flip mirror.
            
            I.config.flip.goto(0);              % Flip the mirror in...
            pause(.5);                          % Wait a bit...
            data = I.config.power.measure();    % And measure.
            
            I.config.flip.goto(prevX);          % Then restore the previous state.
        end
    end
end




