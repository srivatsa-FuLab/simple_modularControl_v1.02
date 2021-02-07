%Template DAQ voltage input 

function config = voltageConfig()
    config.class = 'mciDAQ';

    config.name =               'Default Voltage Input';

    config.kind.kind =          'NIDAQanalog';
    config.kind.name =          'DAQ Voltage Input';
    config.kind.extUnits =      'V';                    % 'External' units.
    config.kind.shouldNormalize = false;
    config.kind.sizeInput =    [1 1];

    config.dev =                'Dev1';
    config.chn =                'ai0';
    config.type =               'Voltage';
end