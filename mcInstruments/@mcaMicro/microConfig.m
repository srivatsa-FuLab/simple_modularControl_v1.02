%Newport CONEX TRA/LTA USB controlled micrometers

function config = microConfig()
    config.class =              'mcaMicro';

    config.name =               'Default Micrometer';

    config.kind.kind =          'Serial Micrometer';
    config.kind.name =          'Newport Micrometer';
    config.kind.intRange =      [0 25];                 % 0 -> 25 mm.
    config.kind.int2extConv =   @(x)(x.*1000);          % Conversion from 'internal' units to 'external'.
    config.kind.ext2intConv =   @(x)(x./1000);          % Conversion from 'external' units to 'internal'.
    config.kind.intUnits =      'mm';                   % 'Internal' units.
    config.kind.extUnits =      'um';                   % 'External' units.
    config.kind.base =          0;                      % The (internal) value that the axis seeks at startup.
    config.kind.resetParam =    '';                     % Currently unused? Check this.

    config.port =               'COM4';                 % Micrometer Port.
    config.addr =               '1';                    % Micrometer Address.

    config.keyStep =            .5;
    config.joyStep =            30;
end     