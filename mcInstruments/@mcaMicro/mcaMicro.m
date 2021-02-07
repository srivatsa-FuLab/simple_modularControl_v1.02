classdef (Sealed) mcaMicro < mcAxis
% mcaMicro is the subclass of mcAxis for Newport serial micrometers.
%
% Also see mcaTemplate and mcAxis.
%
% Status: Finished. Reasonably commented.
    
    methods (Static)
        % Neccessary extra vars:
        %  - port       % USB port that the axis is connected to (e.g. 'COM1')
        %  - addr       % Not sure what this is used for (Srivatsa?) always is 1. Maybe this is used with a USB hub?
        
        function config = defaultConfig()
            config = mcaMicro.microConfig();
        end
        
        %--------------------------------------------
        % Your instruments
        % Add functions for your specific instruments
        %-------------------------------------------- 
        config = microConfig();
        
    end
    
    methods
        function a = mcaMicro(varin)
            a.extra = {'port', 'addr'};
            if nargin == 0
                a.construct(a.defaultConfig());
            else
                a.construct(varin);
            end
            a = mcInstrumentHandler.register(a);
        end
    end
    
    % These methods overwrite the empty methods defined in mcAxis. mcAxis will use these. The capitalized methods are used in
    %   more-complex methods defined in mcAxis.
    methods %(Access = ?mcAxis)
        % NAME
        function str = NameShort(a)
            str = [a.config.name ' (' a.config.port ':' a.config.addr ')'];
        end
        function str = NameVerb(a)
            str = [a.config.name ' (serial micrometer on port ' a.config.port ', address ' a.config.addr ')'];
        end
        
        % EQ
        function tf = Eq(a, b)
            tf = strcmpi(a.config.port,  b.config.port);    % Is address ever used? Maybe for a USB hub?
        end
        
        % OPEN/CLOSE
        function Open(a)        % Consider putting error detection on this?
            disp(['Opening micrometer on port ' a.config.port '...']);
            
            a.s = serial(a.config.port);
            set(a.s, 'BaudRate', 921600, 'DataBits', 8, 'Parity', 'none', 'StopBits', 1, ...
                'FlowControl', 'software', 'Terminator', 'CR/LF');
            fopen(a.s);

            % The following is Srivatsa's code.
            pause(.25);
            fprintf(a.s, [a.config.addr 'HT1']);         % Simplifying function for this?
            fprintf(a.s, [a.config.addr 'SL-5']);        % negative software limit x=-5
            fprintf(a.s, [a.config.addr 'BA0.003']);     % change backlash compensation
            fprintf(a.s, [a.config.addr 'FF05']);        % set friction compensation
            fprintf(a.s, [a.config.addr 'PW0']);         % save to controller memory
            pause(.25);

            fprintf(a.s, [a.config.addr 'OR']);          % Get to home state (should retain position)
            pause(.25);
            
            disp(['...Finished opening micrometer on port ' a.config.port]);
        end
        function Close(a)
            fprintf(a.s, [a.config.addr 'RS']);
            fclose(a.s);    % Not sure if all of these are neccessary; Srivatsa's old code...
            delete(a.s);
        end
        
        % READ
        function ReadEmulation(a)
            if abs(a.x - a.xt) > .1           % Simple equation that attracts a.x to the target value of a.xt.
                a.x = a.x + .1*sign(a.xt - a.x);
            else
                a.x = a.xt;
            end
        end
        function Read(a)
            fprintf(a.s, [a.config.addr 'TP']);     % Ask for device state...
            str = fscanf(a.s);                      % Receive device state.

            a.x = str2double(str(4:end));           % We do not care about the first three characters...
            
            if abs(a.x - a.xt) < .0001              % If the micrometers are within .1um, assume the position was reached.
                a.x = a.xt;
            end
        end
        
        % GOTO
        function GotoEmulation(a, x)
            a.xt = a.config.kind.ext2intConv(x);
            
            % The micrometers are not immediate, so...
            if isempty(a.t)         % ...if the timer to update the position of the micrometers is not currently running...
                a.t = timer('ExecutionMode', 'fixedRate', 'TimerFcn', @a.timerUpdateFcn, 'Period', .5); % 2fps
                start(a.t);         % ...then run it.
            end
        end
        function Goto(a, x)
            fprintf(a.s, [a.config.addr 'SE' num2str(a.config.kind.ext2intConv(x))]);   % Tell the axes to goto the desired position.
            fprintf(a.s, 'SE');                                 % Not sure why this doesn't use config.addr... Srivatsa?

            a.xt = a.config.kind.ext2intConv(x);
            
            if abs(a.xt - a.x) > .02 && isempty(a.t)    % If the goto distance is greater than 20 um,...
                a.t = timer('ExecutionMode', 'fixedRate', 'TimerFcn', @a.timerUpdateFcn, 'Period', .5); % 2fps
                start(a.t);     % ...then start a timer to track the positions of the micrometers (at 2fps) as they reach the destination
            end
        end
    end
    
    methods
        % EXTRA
        function timerUpdateFcn(a, ~, ~)
            a.read();
            if abs(a.x - a.xt) < .0001  % If the axes are within .1um, stop updating.
                stop(a.t);
                delete(a.t);
                a.t = [];
            end
        end
    end
end




