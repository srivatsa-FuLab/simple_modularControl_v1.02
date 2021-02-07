% Template digital output config

function config = digitalConfig()
    config.class = 'mciDAQ';

    config.name =               'Digital Output';

    config.kind.kind =          'NIDAQdigital';
    config.kind.name =          'Digital Output';
    config.kind.shouldNormalize = false;                % If this variable is flagged, the measurement is subtracted from the previous and is divided by the time spent on a pixel.
    config.kind.sizeInput =    [1 1];

    config.dev =                'Dev1';
    config.chn =                'Port0/Line0';
    config.type =               'Output';               % This must be there to differentiate outputs from inputs
end