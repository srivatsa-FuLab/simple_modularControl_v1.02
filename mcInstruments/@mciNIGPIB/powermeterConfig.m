%Newport GPIB powermeter input only

function config = powermeterConfig()
            config.class = 'mciNGPIB';
            
            config.name = 'Powermeter';

            config.kind.kind =          'nigpib';
            config.kind.name =          'NIGPIB Powermeter';
            config.kind.extUnits =      'W';                    % 'External' units: watts.
            config.kind.shouldNormalize = false;                % If this variable is flagged, the measurement is subtracted from the previous and is divided by the time spent on a pixel. Not that this is done outside the measurement currently in mcData (individual calls to .measure() will not have this behavior currently)
            config.kind.sizeInput =    [1 1];
            
            config.chn = 'B';
            config.primaryAddress = 5; 	%GPIB addresss (can be set on the powermeter or via NI-MAX)
 end