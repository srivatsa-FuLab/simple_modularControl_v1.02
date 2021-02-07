%Thorlabs galvo mirrors

function config = galvoConfig()
    config.class =              'mcaDAQ';

    config.name =               'Default Galvo';

    config.kind.kind =          'NIDAQanalog';
    config.kind.name =          'Tholabs Galvometer';   % Check for better name.
    config.kind.intRange =      [-10 10];
    config.kind.int2extConv =   @(x)(x.*1000);          % Conversion from 'internal' units to 'external'.
    config.kind.ext2intConv =   @(x)(x./1000);          % Conversion from 'external' units to 'internal'.
    config.kind.intUnits =      'V';                    % 'Internal' units.
    config.kind.extUnits =      'mV';                   % 'External' units.
    config.kind.base =           0;                     % The (internal) value that the axis seeks at startup.

    config.dev =                'cDAQ1Mod1';
    config.chn =                'ao0';
    config.type =               'Voltage';

    config.keyStep =            .5;
    config.joyStep =            5;
end