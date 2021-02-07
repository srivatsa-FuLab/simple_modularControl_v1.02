%Template for DAQ analog output

function config = analogConfig()
    config.class =              'mcaDAQ';

    config.name =               'Analog Output';

    config.kind.kind =          'NIDAQanalog';
    config.kind.name =          'Analog Output';
    config.kind.intRange =      [0 10];
    config.kind.int2extConv =   @(x)(x);                % Conversion from 'internal' units to 'external'.
    config.kind.ext2intConv =   @(x)(x);                % Conversion from 'external' units to 'internal'.
    config.kind.intUnits =      'V';                    % 'Internal' units.
    config.kind.extUnits =      'V';                    % 'External' units.
    config.kind.base =           0;                     % The (internal) value that the axis seeks at startup.

    config.dev =                'Dev1';
    config.chn =                'ao0';
    config.type =               'Voltage';

    config.keyStep =            .1;
    config.joyStep =            .5;
end