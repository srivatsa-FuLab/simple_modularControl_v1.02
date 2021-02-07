%Template for DAQ digital output

function config = digitalConfig()
    config.class =              'mcaDAQ';

    config.name =               'Digital Output';

    config.kind.kind =          'NIDAQdigital';
    config.kind.name =          'Digital Output';
    config.kind.intRange =      {0 1};                  % Use a cell array to define discrete values.
    config.kind.int2extConv =   @(x)(x);
    config.kind.ext2intConv =   @(x)(x);
    config.kind.intUnits =      '1/0';                  % 'Internal' units.
    config.kind.extUnits =      '1/0';                  % 'External' units. (Should this be volts?)
    config.kind.base =           0;                     % The (internal) value that the axis seeks at startup.

    config.dev =                'Dev1';
    config.chn =                'Port0/Line0';
    config.type =               'Output';               % This must be there to differentiate outputs from inputs

    config.keyStep =            1;
    config.joyStep =            1;
end        