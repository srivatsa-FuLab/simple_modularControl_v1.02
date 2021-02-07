%This is the SPCM counter config

function config = counterConfig()
    config.class = 'mciDAQ';

    config.name =               'Counter';

    config.kind.kind =          'NIDAQcounter';
    config.kind.name =          'DAQ Counter';
    config.kind.extUnits =      'cts/sec';              % 'External' units.
    config.kind.shouldNormalize = true;                 % If this variable is flagged, the measurement is subtracted from the previous and is divided by the time spent on a pixel.
    config.kind.sizeInput =    [1 1];

    config.dev =                'Dev1';
    config.chn =                'ctr2';
    config.type =               'EdgeCount';
end