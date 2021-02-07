classdef mciNIGPIB < mcInput
% mciNIGPIB connects to National Instruments USB to GPIB connectors. Currently, the only GPIB
% instruments that we care about connection to are the Newport powermeters. Use NIMAX to identify
% the appropriate primary and secondary addresses.
%
% Also see mciTemplate and mcInput.
%
% Status: Finished. Mostly uncommented.

    methods (Static)
        % Neccessary extra vars:
        %  - chn
        %  - primaryAddress
        %  - boardIndex?
        
        function config = defaultConfig()
            config = mciNIGPIB.powermeterConfig();
        end
        function config = powermeterConfig()
            config.class = 'mciNGPIB';
            
            config.name = 'Powermeter';

            config.kind.kind =          'nigpib';
            config.kind.name =          'NIGPIB Powermeter';
            config.kind.extUnits =      'W';                    % 'External' units: watts.
            config.kind.shouldNormalize = false;                % If this variable is flagged, the measurement is subtracted from the previous and is divided by the time spent on a pixel. Not that this is done outside the measurement currently in mcData (individual calls to .measure() will not have this behavior currently)
            config.kind.sizeInput =    [1 1];
            
            config.chn = 'B';
            config.primaryAddress = 5;
        end
    end
    
    methods
        function I = mciNIGPIB(varin)
            I.extra = {'chn', 'primaryAddress'};
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
            tf = strcmp(I.config.chn,  b.config.chn) && I.config.primaryAddress == b.config.primaryAddress;
        end
        
        % NAME
        function str = NameShort(I)
            str = [I.config.name ' (' I.config.chn ':' num2str(I.config.primaryAddress) ')'];
        end
        function str = NameVerb(I)
            str = [I.config.name ' (NIGPIB connection on channel ' I.config.chn ' and with primary address ' num2str(I.config.primaryAddress) ')'];
        end
        
        function Open(I)
            I.s = instrfind('Type', 'gpib', 'BoardIndex', 0, 'PrimaryAddress', I.config.primaryAddress); %, 'Tag', '');
            
            if isempty(I.s)                                     % Create the GPIB object if it does not exist
                I.s = gpib('NI', 0, I.config.primaryAddress);
            else                                                % otherwise use the object that was found.
                fclose(I.s);
                I.s = I.s(1);                                   % I don't understand this line (Kai-Mei's code).
            end
            
            fopen(I.s);
        end
        function Close(I)
            fclose(I.s);
        end
        
        % MEASURE
        function data = MeasureEmulation(I, ~)
            data = rand(I.config.kind.sizeInput);
        end
        function data = Measure(I, ~)
            fprintf(I.s, ['R_' I.config.chn '?']);  % Send the command.
            pause(0.2);                             % Wait for the powermeter to process and reply (wait longer?)
            str = fscanf(I.s);                      % Get the power.
            
            % Now convert to numeric... (error check this!)
            data = eval(str);
        end
    end
    
    methods
        % EXTRA
        function setWavelength(I, wavelength)
            str = num2str(wavelength);  % Do checks on this?
            
            if I.open()
                fprintf(I.s, ['LAMBDA_' I.config.chn ' ' str]); 
            end
        end
    end
end




