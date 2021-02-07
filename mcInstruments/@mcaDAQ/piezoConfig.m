%Piezo-systems Jena Nanopositioner
%Currently installed on the NV microscope

function config = piezoConfig()
    config.class =              'mcaDAQ';

    config.name =               'Default Piezo';

    config.kind.kind =          'NIDAQanalog';
    config.kind.name =          'PiezosystemsJena Piezo';
    config.kind.intRange =      [0 10];
    config.kind.int2extConv =   @(x)(8.*(5 - x));       % Conversion from 'internal' units to 'external'.
    config.kind.ext2intConv =   @(x)((40 - x)./8);      % Conversion from 'external' units to 'internal'.
    config.kind.intUnits =      'V';                    % 'Internal' units.
    config.kind.extUnits =      'um';                   % 'External' units.
    config.kind.base =           5;                     % The (internal) value that the axis seeks at startup.

    config.dev =                'Dev1';
    config.chn =                'ao0';
    config.type =               'Voltage';

    config.keyStep =            .1;
    config.joyStep =            .5;
end