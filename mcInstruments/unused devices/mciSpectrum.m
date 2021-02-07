classdef mciSpectrum < mcInput
% mciSpectrum is the subclass of mcInput that reads our old spectra via a shoddy matlab-python handshake.
%
% Future: Generalize this to a mciPyTrigger?
%
% Also see mcaTemplate and mcAxis.
%
% Status: Not debugged yet.

    properties
        prevIntegrationTime;
    end

    methods (Static)
        % Neccessary extra vars:
        %  - triggerfile
        %  - datafile
        
        function config = defaultConfig()
            config = mciSpectrum.pyWinSpecConfig();
        end
        function config = pyWinSpecConfig()
            config.class =              'mciSpectrum';
            
            config.name =               'Spectrometer';

            config.kind.kind =          'pyWinSpectrum';
            config.kind.name =          'Default Spectrum Input';
            config.kind.extUnits =      'cts';                  % 'External' units.
            config.kind.normalize =     false;                  % Should we normalize?
            config.kind.sizeInput =     [1 1340];                 % This input returns a vector, not a number...
            
            config.triggerfile =        'Z:\Winspec\matlabfile.txt';
            config.datafile =           'Z:\spec.SPE';
        end
    end
    
    methods
        function I = mciSpectrum(varin)
            I.extra = {'triggerfile', 'datafile'};
            if nargin == 0
                I.construct(I.defaultConfig());
            else
                I.construct(varin);
            end
            I = mcInstrumentHandler.register(I);
%             if nargin == 0
%                 varin = mciSpectrum.defaultConfig();
%             end
%             
%             I = I@mcInput(varin);
            I.prevIntegrationTime = NaN;
        end
        
        function scans = getInputScans(I)
            if isfield(I.config, 'Ne')
                scans = {interpretNeSpectrum(I.config.Ne)};
            else
                scans = {1:1340};    % Make general?
            end
        end
        
        function units = getInputScanUnits(I)
            if isfield(I.config, 'Ne')
                units = {'nm'};
            else
                units = {'pixels'};
            end
        end
    end
    
    % These methods overwrite the empty methods defined in mcInput. mcInput will use these. The capitalized methods are used in
    %   more-complex methods defined in mcInput.
    methods
        % EQ
        function tf = Eq(I, b)  % Check if a foriegn object (b) is equal to this input object (a).
            tf = strcmp(I.config.triggerfile,   b.config.triggerfile) && ... % ...then check if all of the other variables are the same.
                 strcmp(I.config.datafile,      b.config.datafile);
        end
        
        % NAME
        function str = NameShort(I)
            str = I.config.name;
        end
        function str = NameVerb(I)
            str = [I.config.name '(with triggerfile ' I.config.triggerfile ' and datafile ' I.config.datafile];
        end
        
        % OPEN/CLOSE not neccessary
        
        % MEASURE
        function data = MeasureEmulation(~, integrationTime)
            pause(integrationTime);
            
            cosmicray = (500*rand)*(rand > .9);      % Insert cosmic ray in 10% of scans (make this scale with integrationTime?)
%             
%             size(rand(1, 1340))
%             size(exp(-((1:1340 - rand*1340)/3).^2))
            
            data = round(20*rand(1, 1340) + cosmicray.*exp(-(((1:1340) - rand*1340)/3).^2) + 100);    % Background + cosmic ray
        end
        function data = Measure(I, integrationTime)
            data = -1;
            t = now;

            fh = fopen(I.config.triggerfile, 'w');               % Create the trigger file.
            
            if (fh == -1)
                warning('mciSpectrum.measure(): oops, file cannot be written'); 
                data = NaN(I.config.kind.sizeInput);
                return;
            end 
            
            fprintf(fh, 'Trigger Spectrum\n');                  % Change this?
            fclose(fh);

            ii = 0;
            
            exposure = NaN;

            while ii < integrationTime + 60 && all(data == -1)   % Is 60 sec wiggle room enough?
                 try
                    %disp(['Waiting ' num2str(i)]);
                    d = dir(I.config.datafile);
                    
%                     d.datenum > t - 4/(24*60*60)

                    if d.datenum > t - 4/(24*60*60)
                        [data, exposure] = readSPE(I.config.datafile);
                    end
                 catch
                   % disp('bad code in mcispec')
                 end

                pause(1);
                ii = ii + 1;
                
                if ii == integrationTime
                    disp(['mciSpectrum: The integration time of ' num2str(integrationTime) ' seconds has elapsed. Waiting for one more minute.']);
                elseif mod(integrationTime + 60 - ii, 10) == 0   % If divisible by 10...
                    disp(['mciSpectrum: Waiting for ' num2str(integrationTime + 60 - ii) ' more seconds.']);
                end
            end
            
            if isnan(exposure)
                mcDialog(['Request for spectrum timed out; sorry. Did you set the exposure time greater than the expected ' num2str(integrationTime) ' seconds?'], 'mciSpectrum Failed');
                data = NaN(I.config.kind.sizeInput);
                return;
            end
            
            if integrationTime ~= exposure && I.prevIntegrationTime ~= integrationTime
                warning(['mciSpectrum: Expected exposure of ' num2str(integrationTime) ' seconds, but received ' num2str(exposure) ' second exposure.']);
%                 data = NaN(I.config.kind.sizeInput);
%                 return;
            end

            if ~all(data == -1)     % If we found the spectrum....
                ii = 0;
                
                while ii < 20
                    try             % ...try to move it to our save directory.
                        movefile(I.config.datafile, [mcInstrumentHandler.timestamp(1) '.SPE']);     % Change this to conform with the parent mcData structure?
                        break;
                    catch err
                        disp(err.message)
                    end
                    
                    ii = ii + 1;
                end
            else                    % ...otherwise, return NaN.
                data = NaN(I.config.kind.sizeInput);
            end
        end
    end
    
end




