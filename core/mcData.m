classdef mcData < mcSavableClass
% mcData is an object that encapsulates our generic data structure. This allows the same data structure to be used by multiple
%   classes. For instance, the same mcData can be used by multiple mcProcessedDatas.
%
% Syntax (needs finalizing):
%   d = mcData()
%   d = mcData(d)                                                       % Load old or new data (just the d structure) into this class.
%   d = mcData('insert/file/path/d.mat')                                % Load old data (from a .mat) into this class.
%   d = mcData(axes_, scans, inputs, integrationTime)                   % Load with cell arrays axes_ (contains the mcAxes to be used), scans (contains the paths, in numeric arrays, for these axes to take... e.g. linspace(0, 10, 50) is one such path from 0 -> 10 with 50 steps), and inputs (contains the mcInputs to be measured at each point). Also load the numeric array integration time (in seconds) which denotes (when applicable) how much time is spent measuring each input.
%   d = mcData(axes_, scans, inputs, integrationTime, shouldOptimize)   % In addition to the previous, shouldOptimize tells the mcData to optimize after finishing or not (only works for 1D and 2D scans with singular data) 
%
% Status: Mosly finished and commented.

    properties (SetObservable)
        d = [];     % Our generic data structure. d for data. This acts like the 'config' of other classes and is the structure that is saved in the .mat file.
        
        % d contains:
        %
        % - d.class                 string              % Always equals 'mcData'; allows other parts of the program to distinguish it from other configs. (Change?)
        % - d.name                  string              % Name of this mcData scan. If left empty or uninitiated, it is auto-generated.
        % - d.kind.name             string              % Always equals 'mcData'; allows other parts of the program to distinguish it from other configs. (Change?)
        %
        % - d.axes                  cell array          % The configs for the axes. For n axes, this is 1xn.
        % - d.inputs                cell array          % The configs for the inputs. For m inputs, this is 1xm.
        % - d.scans                 cell array          % The points that each axis scans across. The ith entry in the cell array corresponds to the ith axis. Note that these are in external units.
        % - d.intTimes              numeric array       % Contains the integration time for each input. Thus this is 1xm. For NIDAQ devices which 'can scan fast' by scanning altogether, the maximum intTime is used.
        %
        % - d.data                  cell array          % This is the 'meat' of this structure. Data is a   cell array (each entry corresponding to each input). Each entry contains an (n+N)-dimensional matrix where N is the dimension of the input.
        %
        % - d.info.timestamp        string              % The file is, by default, named <d.info.timestamp d.name>.mat. This is generated every time the data is reset.
        % - d.info.fname            string              % Where the data should be saved (in the background). This is generated every time the data is reset.
        % - d.info.version          numeric array       % The version of modularControl that this data was taken with. This is generated every time the data is reset.
        % - d.info.other.axes       cell array          % configs for all the axes when the scan is started.
        % - d.info.other.status     numeric array       % status (i.e. a.x) of all of the above axes.
        %
        % - d.index                 numeric array       % Current 'position' of the axes in the scan.
        %
        % - d.flags.circTime        boolean             % Flags whether the data should be circshifted for infinite data aquisistion. If this is not set, assumes false. If time is not an axis, assumes false.
        % - d.flags.shouldOptimize  boolean             % Whether or not the axes should be optimized on the brightest point of the 1st input. Only works for 1 or 2 axes with 0D inputs. Note that this is not general and should be replaced by an mcOptimizationRoutine struct for a general optimization.
        % - d.flags.optimizeMove    numeric array       % After optimizing, move by this much (can be [x y] if we are in 2D; just [x] for 1D).
        % 
        % - d.config                unused              % (due to inheritence from mcSavableClass) (change this?)
    end

    properties (SetObservable)
        dataViewer = [];        % 'Pointer' to the current data viewer.
        r = [];                 % Struct for runtime-generated info, generated from d. r for runtime.
        
        % - r.isInitialized = false;                        % Whether or not the computer-generated fields have been calculated.
        % 
        % RUNTIME-GENERATED INPUT INFO:
        % 
        % - r.i.num                 integer                 % The number of inputs.
        % 
        % The following are (1xd.i.num) arrays. The ith value in each array contains the info relevant to the ith input.
        % 
        % - r.i.i                   mcInput array           % Contains the objects that point to the appropriate inputs.
        % - r.i.dimension           numeric array           % The dimension of the input (0 for number, 1 for vector, 2 for image).
        % - r.i.length              numeric array           % Lengths of the inputs (prod of the dimensions) e.g. length of 16x16 input is 256
        % - r.i.name                cell array (strings)    % Contains the name (just the name) of each input.
        % - r.i.nameUnit            cell array (strings)    % Contains the name and units of the inputs in "name (unit)" form.
        % - r.i.unit                cell array (strings)    % Just contains the units of the inputs.
        % - r.i.isNIDAQ             boolean array           % Whether or not each input is an NIDAQ input and can use 'faster' scanning procedures. 
        % - r.i.inEmulation         boolean array           % Whether or not each input is in emulation mode.
        % - r.i.numInputAxes        numeric                 % = sum(d.r.i.dimension); the total number of dimensions.
        % - r.i.scans               cell array              % Contains the vectors corresponding to the edges of theinputs.
        % 
        % RUNTIME-GENERATED AXIS INFO:
        % 
        % - r.a.num                 integer                 % The number of axes.
        % 
        % The following are (1xd.i.num) arrays. The ith value in each array contains the info relevant to the ith input.
        % 
        % - r.a.a                   mcAxis array            % Contains the objects that point to the appropriate axes.
        % - r.a.name                cell array (strings)    % Contains the name (just the name) of each axis.
        % - r.a.nameUnit            cell array (strings)    % Contains the name and units of the axes in "name (unit)" form.
        % - r.a.unit                cell array (strings)    % Just contains the units of the axes.
        % - r.a.isNIDAQ             boolean array           % Whether or not each axis is an NIDAQ input and can use 'faster' scanning procedures.        
        % - r.a.inEmulation         boolean array           % Whether or not each axis is in emulation mode.
        % - r.a.scansInternalUnits  cell array              % Contains the info in data.scans, except in internal units.
        % - r.a.prev                numeric array           % Contains the positions of all of the loaded axes before the scan begins. This allows for returning to the same place.
        % - r.a.timeIsAxis          boolean                 % Whether or not time is one of the axes (Future: Remove?)
        % 
        % RUNTIME-GENERATED LAYER INFO:
        % 
        % - r.l.num                 integer
        % - r.l.layer               numeric array           % Current layer that any connected mcProcessedDatas should process.
        % - r.l.axis                numeric array           % 1 ==> mcAxis, positive nums ==> the num'th axis of an input
        % - r.l.type                numeric array           % 0 ==> mcAxis, positive nums imply the num'th input.
        % - r.l.weight              numeric array           % First d.a.num indices are the weights of each axis. (Weight needs better explaination!)
        % - r.l.scans               cell arrray             % Contains all the scans (for both axes and inputs). If no scans are given for the inputs, then 1:size(dim) pixels is used.
        % - r.l.lengths             numeric arrray          % The length (how many points) in each layer.
        % - r.l.name                cell array (strings)    % The name of each layer.
        % - r.l.nameUnit            cell array (strings)    % The name of each layer in "name (units)" form.
        % - r.l.unit                cell array (strings)    % The unit of each layer.
        % 
        % OTHER RUNTIME-GENERATED INFO:
        % 
        % - r.plotMode              integer             % e.g. 1 = '1D', 2 = '2D', ...
        % - r.isInitialized         boolean             % Is created once the initialize() function has been called.
        % - r.scanMode              integer             % paused = -1; new = 0; running = 1; finished = 2.
        % - r.aquiring              boolean             % whether we are aquiring currently or not.
        % - r.s                     DAQ session         % Only used if all the inputs and the first axis are NIDAQ.
        % - r.canScanFast           boolean             % Variable that decides whether the above should be used.
        % - r.timeIsAxis            boolean             % Flagged if time is the last axis (not currently used).
    end
    
    % Configs
    methods (Static)
        function data = defaultConfig()  % The Config that is used if no vars are given to mcData.
%             data = mcData.testConfig();
%             data = mcData.singleSpectrumConfig();
%             data = mcData.counterConfig(mciSpectrum(), 10, 1);
            data = mcData.xyzConfig2();
%             data = mcData.testConfig();
        end
        function data = xyzConfig()      % Just a test Config.
            data.class = 'mcData';
            
            configPiezoX = mcaDAQ.piezoConfig(); configPiezoX.name = 'Piezo X'; configPiezoX.chn = 'ao0';       % Customize all of the default configs...
            configPiezoY = mcaDAQ.piezoConfig(); configPiezoY.name = 'Piezo Y'; configPiezoY.chn = 'ao1';
            configPiezoZ = mcaDAQ.piezoZConfig(); configPiezoZ.name = 'Piezo Z'; configPiezoZ.chn = 'ao2';
            
            configCounter = mciDAQ.counterConfig(); configCounter.name = 'Counter'; configCounter.chn = 'ctr2';
            
            data.axes =     {configPiezoX, configPiezoY, configPiezoZ};                         % Fill the...   ...axes...
            data.scans =    {linspace(-10,10,21), linspace(-10,10,21), linspace(-10,10,2)};     %               ...scans...
            data.inputs =   {configCounter};                                                    %               ...inputs.
            data.intTimes = .05;
        end
        function data = xyzConfig2()      % Just a test Config.
            data.class = 'mcData';
            
            configPiezoX = mcaDAQ.piezoConfig(); configPiezoX.name = 'Piezo X'; configPiezoX.chn = 'ao0';       % Customize all of the default configs...
            configPiezoY = mcaDAQ.piezoConfig(); configPiezoY.name = 'Piezo Y'; configPiezoY.chn = 'ao1';
            configPiezoZ = mcaDAQ.piezoZConfig(); configPiezoZ.name = 'Piezo Z'; configPiezoZ.chn = 'ao2';
            
            configTest = mciFunction.randConfig();
            
            data.axes =     {configPiezoX, configPiezoY, configPiezoZ};                         % Fill the...   ...axes...
            data.scans =    {linspace(-10,10,21), linspace(-10,10,21), linspace(-10,10,2)};     %               ...scans...
            data.inputs =   {configTest};                                                       %               ...inputs.
            data.intTimes = .05;
        end
        function data = squareScanConfig(axisX, axisY, input, range, speedX, pixels)                 % Square version of the below.
            data = mcData.scanConfig(axisX, axisY, input, range, range, speedX, pixels, pixels); 
        end
        function data = scanConfig(axisX, axisY, input, rangeX, rangeY, speedX, pixelsX, pixelsY)    % Rectangular 2D scan with arbitrary axes and input.
            data.class = 'mcData';
            
            if length(rangeX) == 1
                center = axisX.getX();
                rangeX = [center - rangeX/2 center + rangeX/2];
            elseif length(rangeX) ~= 2
                error('mcData.scanConfig(): Not sure how to use rangeX');
            end
            if length(rangeY) == 1
                center = axisY.getX();
                rangeY = [center - rangeY/2 center + rangeY/2];
            elseif length(rangeY) ~= 2
                error('mcData.scanConfig(): Not sure how to use rangeY');
            end
            
            if diff(rangeX) == 0
                error('mcData.scanConfig(): rangeX(1) should not equal rangeX(2)');
            end
            if diff(rangeY) == 0
                error('mcData.scanConfig(): rangeY(1) should not equal rangeY(2)');
            end
            
            if abs(diff(rangeX)) > abs(diff(axisX.config.kind.extRange))
                warning('mcData.scanConfig(): rangeX is too wide, setting to maximum');
                rangeX = axisX.config.kind.extRange;
            end
            if abs(diff(rangeY)) > abs(diff(axisY.config.kind.extRange))
                warning('mcData.scanConfig(): rangeY is too wide, setting to maximum');
                rangeY = axisY.config.kind.extRange;
            end
            
            if min(rangeX) < min(axisX.config.kind.extRange)
                warning('mcData.scanConfig(): rangeX is below range, shifting up');
%                 rangeX
                rangeX = rangeX + (min(axisX.config.kind.extRange) - min(rangeX));
            end
            if min(rangeY) < min(axisY.config.kind.extRange)
                warning('mcData.scanConfig(): rangeY is below range, shifting up');
%                 rangeY
                rangeY = rangeY + (min(axisY.config.kind.extRange) - min(rangeY));
            end
            
            if max(rangeX) > max(axisX.config.kind.extRange)
                warning('mcData.scanConfig(): rangeX is above range, shifting down');
%                 rangeX
                rangeX = rangeX + (max(axisX.config.kind.extRange) - max(rangeX));
            end
            if max(rangeY) > max(axisY.config.kind.extRange)
                warning('mcData.scanConfig(): rangeY is above range, shifting down');
%                 rangeY
                rangeY = rangeY + (max(axisY.config.kind.extRange) - max(rangeY));
            end
            
            
            if speedX < 0
                speedX = -speedX;
            elseif speedX == 0
                error('mcData.scanConfig(): It will take quite a long time to finish the scan if speedX == 0...');
            end
            
            
            if pixelsX ~= round(pixelsX)
                warning(['mcData.scanConfig(): pixelsX (' num2str(pixelsX) ') was not an integer, rounding to ' num2str(round(pixelsX)) '...']);
                pixelsX = round(pixelsX);
            end
            if pixelsX < 0
                pixelsX = -pixelsX;
            elseif pixelsX == 0
                error('mcData.scanConfig(): pixelsX should not equal zero...');
            end
            
            if pixelsY ~= round(pixelsY)
                warning(['mcData.scanConfig(): pixelsY (' num2str(pixelsY) ') was not an integer, rounding to ' num2str(round(pixelsY)) '...']);
                pixelsY = round(pixelsY);
            end
            if pixelsY < 0
                pixelsY = -pixelsY;
            elseif pixelsY == 0
                error('mcData.scanConfig(): pixelsY should not equal zero...');
            end
            
            
            data.axes =     {axisX, axisY};                                                                     % Fill the...   ...axes...
            data.scans =    {linspace(rangeX(1), rangeX(2), pixelsX), linspace(rangeY(1), rangeY(2), pixelsY)}; %               ...scans...
            data.inputs =   {input};                                                                            %               ...inputs.
            data.intTimes = (diff(rangeX)/speedX)/pixelsX;
        end
        function data = optimizeConfig(axis_, input, range, pixels, seconds)                         % Optimizes 'input' over 'range' of 'axis_'
            % axis_ = arb mcAxis
            % input = arb mcInput
            % range = (centered) distance to scan over
            % pixels = # of points to aquire data at over range
            % seconds = total scan time
            
                        
            data.class = 'mcData';
            
%             axis_
%             input
%             range
%             pixels
%             seconds
            center = axis_.getX();
            
            scan = linspace(center - range/2, center + range/2, pixels);
            scan = scan(scan <= max(axis_.config.kind.extRange) & scan >= min(axis_.config.kind.extRange));  % Truncate the scan.
            
            data.axes =     {axis_};                    % Fill the...   ...axis...
            data.scans =    {scan};                     %               ...scan...
            data.inputs =   {input};                    %               ...input.
            data.intTimes = seconds/pixels;
            data.flags.shouldOptimize = true;
            

        end
        function data = optimizeMoveConfig(axis_, input, range, pixels, seconds, move)                         % Optimizes 'input' over 'range' of 'axis_'
            data = mcData.optimizeConfig(axis_, input, range, pixels, seconds);
            data.flags.optimizeMove = move;
        end
        function data = counterConfig(input, length, integrationTime)    
            data.class = 'mcData';
            
            data.axes =     {mcAxis()};                 % This is the time axis.
            data.scans =    {1:abs(round(length))};     % range of 'scans ago'.
            data.inputs =   {input};                    % input.
            data.intTimes = integrationTime;
            data.flags.circTime = true;
        end
        function data = sineConfig(axis_, range, pixels, period)    
            data.class = 'mcData';
            
            data.axes =     {axis_, mcAxis()};
            data.scans =    {range*.5*sin(linspace(0, 2*pi, pixels)) + axis_.getX(), 1:10};
            data.inputs =   {mciDAQ(mciDAQ.counterConfig)};
            data.intTimes = period/pixels;
            data.flags.circTime = true;
        end
        function data = inputConfig(input, length, integrationTime)    
            data.class = 'mcData';
            
            data.axes =     {mcAxis()};                 % This is the time axis.
            data.scans =    {1:abs(round(length))};     % range of 'scans ago'.
            data.inputs =   {input};                    % input.
            data.intTimes = integrationTime;
        end
        function data = singleConfig(input, integrationTime)    
            data.class = 'mcData';
            
            data.axes =     {};
            data.scans =    {};
            data.inputs =   {input};                    % input.
            data.intTimes = integrationTime;
        end
        function data = testConfig()
            data.class = 'mcData';
            
            data.axes =     {mcAxis()};
            data.scans =    {1:10};
            c1 = mciFunction.randConfig(); c1.name = 'Test 1';
            c2 = mciFunction.testConfig(); c2.name = 'Test 2';
            c3 = mciFunction.testConfig(); c3.name = 'Test 3';
            
            data.inputs =   {mciFunction(c1), mciFunction(c2), mciFunction(c3)};
            
%             c1
%             c2
%             c3
%             
%             data.inputs{1}
%             data.inputs{2}
%             data.inputs{3}
%             
%             data.inputs{1}.config
%             data.inputs{2}.config
%             data.inputs{3}.config
%             
%             pause(5);
            
            data.intTimes = [1 1 1];
        end
        function data = singleSpectrumConfig()
            data.class = 'mcData';
            
            data.axes =     {};
            data.scans =    {};
            data.inputs =   {mciSpectrum()};
            data.intTimes = 120;
        end
        
        function data = single_hires_SpectrumConfig()
            data.class = 'mcData';
            
            data.axes =     {};
            data.scans =    {};
            data.inputs =   {mci_hires_Spectrum()};
            data.intTimes = 90;
        end
        
        function data = PLEConfig()
%             data = mcData.inputConfig(mciPLE(), 20, 1);
            data = mcData.counterConfig(mciPLE(), 20, 1);
%             data = mcData.singleConfig(mciPLE(), 1);
        end
        
        %srivatsa
        function data = autoPLEConfig()
            
            %Modified by Srivatsa 11/23/2018
            
            %Configure autople run
            pts = mcaPoints.modifyAndPromptBrightSpotConfig();
            
            
            %Configure optimization sequence
            px = mciDaughter.daughterConfig(pts, 'prevOpt(end,1,3) + 25', [1 1], 'um'); px.name = 'X Offset From Expected';
            py = mciDaughter.daughterConfig(pts, 'prevOpt(end,2,3) + 25', [1 1], 'um'); py.name = 'Y Offset From Expected';
            pz = mciDaughter.daughterConfig(pts, 'prevOpt(end,3,2) + 25', [1 1], 'um'); pz.name = 'Absolute Z';

            sx = mciDaughter.daughterConfig(pts, 'prev{1}', [pts.optPix 1], 'cts');     sx.name = 'X Scan';
            sy = mciDaughter.daughterConfig(pts, 'prev{2}', [pts.optPix 1], 'cts');     sy.name = 'Y Scan';
            sz = mciDaughter.daughterConfig(pts, 'prev{3}', [pts.optPix 1], 'cts');     sz.name = 'Z Scan';
            
           
            count = mciDAQ.counterConfig;
            
            %Code to take spectra and change waveplate rotator
            
                %spec =  mciDataWrapper.dataConfig(mcData.inputConfig(mciSpectrum.pyWinSpecConfig(), 2, 60));   % (60 sec exposures; eventually unlock this...)
                %spec.name = 'Spectrometer';

                %gple = mciGotoWrapper.pleModeConfig();
                %gopt = mciGotoWrapper.optModeConfig();
                %gspec = mciGotoWrapper.specModeConfig();

            PLE =   mciPLE.PLEConfig(1, 3, 1000, 5, 1);
            numScans = 20;
            ple =   mciDataWrapper.dataConfig(mcData.inputConfig(PLE, numScans, 1));        % (Fake integrationTime)
            ple.name = 'PLE';


            data.axes =         {pts, mcAxis};                                              % bright points, time
            data.scans =        {pts.nums, 1:2};                                            % all points, 2x scan
            data.inputs =       {count, px, py, pz, sx, sy, sz, ple};
            data.intTimes =     NaN(size(data.inputs));
            data.intTimes(1) =  4;

            
            %I = mciGotoWrapper(gopt);
            %I.measure();    % Make sure we are in the opt configuration at the start.
        end
        
    end
    
    % Core Functionality
    methods
        function d = mcData(varargin)  % Intilizes the mcData object d. Checks the d.d struct for errors.
%             varin
            
            switch nargin
                case 0
%                     error('We shouldnt be here')
                    d.d = mcData.defaultConfig();    % If no vars are given, assume a 10x10um piezo scan centered at zero (outdated).
                case 1
                    if ischar(varargin{1})
                        c = load(varargin{1});
                
                        if isfield(c, 'data')
                            answer = 'yes';

                            if any(c.data.info.version ~= mcInstrumentHandler.version())
                                str = [ 'Warning: the file "' varargin{1} '" was created with modularControl version v' strrep(num2str(c.data.info.version), '  ', '.')...
                                        ', whereas the current version is v' strrep(num2str(mcInstrumentHandler.version()), '  ', '.')...
                                        '. This could potentially lead to version-conflict errors. Proceed anyway?'];

                                answer = questdlg(str, 'Warning, Version Mismatch!', 'Yes', 'No', 'Yes');
                            end

                            switch lower(answer)
                                case 'yes'
                                    d.d = c.data;
                                case 'no'
                                    disp(['mcData(' varargin{1} '): File was not loaded due to version conflict...']);
                            end
                        else
                            disp(['mcData(' varargin{1} '): No file given to load...']);
                        end
                    else
                        d.d = varargin{1};
                    end
                case 4
                    d.d.axes =                  varargin{1};       % Otherwise, assume the four variables are axes, scans, inputs, integration time...
                    d.d.scans =                 varargin{2};
                    d.d.inputs =                varargin{3};
                    d.d.intTimes =              varargin{4};
                    d.d.flags.shouldOptimize =  false;
                case 5          
                    d.d.axes =                  varargin{1};       % And if a 5th var is given, assume it is shouldOptimize
                    d.d.scans =                 varargin{2};
                    d.d.inputs =                varargin{3};
                    d.d.intTimes =              varargin{4};
                    d.d.flags.shouldOptimize =  varargin{5};
            end
            
            d.d.class = 'mcData';
            
            if ~isfield(d.d, 'flags')
                d.d.flags = [];
            end
            
            if ~isfield(d.d.flags, 'shouldOptimize')
                d.d.flags.shouldOptimize = false;
            end
            
            if ~isfield(d.d.flags, 'optimizeMove')
                d.d.flags.optimizeMove = zeros(1, length(d.d.axes));
            end
            
            if ~isfield(d.d.flags, 'circTime')
                d.d.flags.circTime = false;
            end
            
            % Check lengths of axes and scans...
            if length(d.d.axes) ~= length(d.d.scans)
                error('mcData(): Expected axes and scans to have the same length.');
            end
            
            % Checking the axes...
            if iscell(d.d.axes)
                for ii = 1:length(d.d.axes)
                    if isa(d.d.axes{ii}, 'mcAxis')
                        c = class(d.d.axes{ii});
                        d.d.axes{ii} = d.d.axes{ii}.config;
                        d.d.axes{ii}.class = c;                 % Store the class of the axis (e.g. mcaDAQ) if it isn't already...
                    elseif isstruct(d.d.axes{ii})
                        % Do nothing.
                    else
                        error(['mcData(): Unknown data type for the ' getSuffix(ii) ' axis: ' class(d.d.axes{ii})]);
                    end
                end
            else
                error('mcData(): d.d.axes must be a cell array.');
            end
            
            % Checking the scans...
            if iscell(d.d.scans)
                for ii = 1:length(d.d.scans)
                    if ~isnumeric(d.d.scans{ii})
                        error(['mcData(): Expected numeric array for the scan of the ' getSuffix(ii) ' axis. Got: ' class(d.d.scans{ii})]);
                    end
                    if min(size(d.d.scans{ii})) ~= 1 || max(size(d.d.scans{ii})) == 1 || length(size(d.d.scans{ii})) ~= 2   % If d.d.scans{ii} isn't a 1xn or nx1 vector...
                        error(['mcData(): Expected a 1xn or nx1 vector (n > 1) for the scan of the ' getSuffix(ii) ' axis. Instead, got a matrix of dimension [ ' num2str(size(d.d.scans{ii})) ' ].']);
                    end
                end
            else
                error('mcData(): d.d.scans must be a cell array.');
            end
            
            % Check lengths of inputs and intTimes...
            if length(d.d.inputs) ~= length(d.d.intTimes)
                error('mcData(): Expected inputs and intTimes to have the same length.');
            end
            
            % Checking the inputs...
            if isempty(d.d.inputs)
                error('mcData(): d.d.inputs is empty. Cannot do a scan without inputs.');
            end
            
            if iscell(d.d.inputs)
                for ii = 1:length(d.d.inputs)
                    if isa(d.d.inputs{ii}, 'mcInput')
                        c = class(d.d.inputs{ii});
                        d.d.inputs{ii} = d.d.inputs{ii}.config;
                        d.d.inputs{ii}.class = c;               % Store the class of the input (e.g. mciDAQ) if it isn't already...
                    elseif isstruct(d.d.inputs{ii})
                        % Do nothing.
                    else
                        error(['mcData(): Unknown data type for the ' getSuffix(ii) ' input: ' class(d.d.inputs{ii})]);
                    end
                end
            else
                error('mcData(): d.d.inputs must be a cell array');
            end
            
            % Checking the intTimes...
            if isnumeric(d.d.intTimes)
                if any(d.d.intTimes < 0)
                    error('mcData(): Integration times cannot be negative.');
                end
            else
                error('mcData(): d.d.intTimes must be a numeric array.');
            end
            
            d.initialize();
            
            % Need more checks?!
        end
        
        function tf = eq(d, b)
            if      isfield(d.d, 'info')        && isfield(b.d, 'info') 
                if  isfield(d.d.info, 'fname')  && isfield(b.d.info, 'fname')
                    tf = strcmpi(d.info.fname, b.info.fname);
                else
                    tf = false;
                end
            else
                tf = false;
            end
        end
        
        function initialize(d)      % Initializes the d.r (r for runtime) variables in the mcData object.
            if ~isfield(d.r, 'isInitialized')     % If not initialized, then intialize.
                
                % GENERATE INPUT RUNTIME DATA (r.i) ============================================================================
                
                % First, figure out how many inputs we have.
                d.r.i.num =             length(d.d.inputs);
                
                % Then, initialize empty lists.
                d.r.i.i =               cell( 1, d.r.i.num);
                
                d.r.i.dimension =       zeros(1, d.r.i.num);
                d.r.i.length =          zeros(1, d.r.i.num);
                d.r.i.size =            cell( 1, d.r.i.num);
                
                d.r.i.name =            cell( 1, d.r.i.num);
                d.r.i.nameUnit =        cell( 1, d.r.i.num);
                d.r.i.unit =            cell( 1, d.r.i.num);
                
                d.r.i.isNIDAQ =         false(1, d.r.i.num);
                d.r.i.inEnmulation =    false(1, d.r.i.num);
                
                % And initialize empty variables.
                d.r.l.axis =            [];
                d.r.l.type =            [];
                d.r.l.weight =          [];
                d.r.l.scans =           [];
                d.r.l.lengths =         [];
                d.r.l.name =            [];
                d.r.l.nameUnit =        [];
                d.r.l.unit =            [];
                
                % See above for the definitions of these variables.
                    
                inputLetters = 'XYZUVW';    % Figure out what we should call the ith input axis (the 1st is called X, the second Y, ... )

                for ii = 1:d.r.i.num        % Now fill the empty lists
                    c = d.d.inputs{ii};     % Get the config for the iith input.
                    
                    if isfield(c, 'class')
                        try
                            d.r.i.i{ii} = eval([c.class '(c)']);    % Make a mcInput (subclass) object based on that config.
                        catch
                            
                        end
                    else
                        error('mcData(): Config given without class. ');
                    end
                    
                    % Extract some info from the config.
                    d.r.i.dimension(ii) =   sum(c.kind.sizeInput > 1);
                    d.r.i.size{ii} =        c.kind.sizeInput(c.kind.sizeInput > 1);   % Poor naming.
                    d.r.i.length(ii) =      prod(d.r.i.size{ii});
                    
                    d.r.i.name{ii} =            d.r.i.i{ii}.nameShort();        % Generate the name of the inputs in... ...e.g. 'name (dev:chn)' form
                    d.r.i.nameUnit{ii} =        d.r.i.i{ii}.nameUnits();        %                                       ...'name (units)' form
                    d.r.i.unit{ii} =            d.d.inputs{ii}.kind.extUnits;   %                                       ...'units'

                    d.r.i.isNIDAQ(ii) =         strcmpi('nidaq', c.kind.kind(1:min(5,end)));
                    d.r.i.inEmulation(ii) =     d.r.i.i{ii}.inEmulation;
                    
                    % For inputs which have dimension (e.g. a vector input like a spectrum vs a number like a voltage), fill in some info so we can display data over these input axes.
                    d.r.l.axis =    [d.r.l.axis     1:d.r.i.dimension(ii)];             % If an input has dimension dim, then 1:dim is added, representing the 'dim' axes that this input has.
                    d.r.l.type =    [d.r.l.type     ones(1, d.r.i.dimension(ii))*ii];   % To identify which input the above belongs to, the index is tagged with the number of the axis.
                    d.r.l.scans =   [d.r.l.scans    d.r.i.i{ii}.getInputScans()];
                    d.r.l.lengths = [d.r.l.lengths  d.r.i.size{ii}];                    % Will this be a cell?
                    
                    if d.r.i.dimension(ii) > length(inputLetters)
                        error('mcData.initialize(): Too many dimensions on this input. Not enough letters to describe each dimension.')
                    end
                    
                    inUnits = d.r.i.i{ii}.getInputScanUnits();
                    
                    for jj = 1:d.r.i.dimension(ii)
%                         jj
                        d.r.l.name =        [d.r.l.name     {[d.d.inputs{ii}.name ' ' inputLetters(jj)]}];
                        d.r.l.nameUnit =    [d.r.l.nameUnit {[d.d.inputs{ii}.name ' ' inputLetters(jj) ' (' inUnits{jj} ')']}];
                        d.r.l.unit =        [d.r.l.unit     inUnits(jj)];
                    end
                    
                    iwAdd = ones(1, d.r.i.dimension(ii));       % Temporary variable: 'indexWeightAdd' because it will be added to d.r.l.weight.
                    for jj = 2:length(iwAdd)
                        iwAdd(jj:end) = iwAdd(jj:end)*d.r.i.size{ii}(jj-1);
                    end
                    d.r.l.weight =              [d.r.l.weight iwAdd];
                end
                
                % And gather some statistics based on the filled lists.
                d.r.i.numInputAxes = sum(d.r.i.dimension);
                

                % GENERATE AXIS RUNTIME DATA (r.a) =============================================================================
                
                % Again, first figure out how many axes we have.
                d.r.a.num =         length(d.d.axes);
                
                if d.d.flags.shouldOptimize
                    if d.r.a.num > 2
                        error(['mcData.initialize(): Optimization of 1D and 2D data sets enabled, not ' num2str(d.r.a.num) 'D'])
                    end
                    
                    if length(d.d.flags.optimizeMove) ~= d.r.a.num
                        warning(['mcData.initialize(): Expected to move ' num2str(d.r.a.num) ' axis after optimization, not ' num2str(length(d.d.flags.optimizeMove))]);
                        
                        if      d.r.a.num == 1
                            d.d.flags.optimizeMove = 0;
                        elseif  d.r.a.num == 2
                            d.d.flags.optimizeMove(2) = 0;
                        end
                    end
                end
                
                % Make some empty lists...
                d.r.a.length =          zeros(1, d.r.a.num);
                
                d.r.a.a =               cell(1, d.r.a.num);
                justname =              cell(1, d.r.a.num);
                d.r.a.name =            cell(1, d.r.a.num);
                d.r.a.nameUnit =        cell(1, d.r.a.num);
                d.r.a.unit =            cell(1, d.r.a.num);
                
                d.r.a.isNIDAQ =         false(1, d.r.a.num);
                d.r.a.inEnmulation =    false(1, d.r.a.num);
                
                d.r.a.prev =            NaN( 1, d.r.a.num);

                % ...and fill them.
                for ii = 1:d.r.a.num
                    c = d.d.axes{ii};     % Get the config for the iith axis.
                    
                    if isfield(c, 'class')
                        d.r.a.a{ii} = eval([c.class '(c)']);    % Make a mcInput (subclass) object based on that config),
                    else
                        error('mcData(): Config given without class. ');
                    end
                    
%                     s = d.d.scans{ii}
                    d.r.a.length(ii) =      length(d.d.scans{ii});
%                     l = d.r.a.length(ii)
                    
                    justname{ii} =          d.d.axes{ii}.name;
                    d.r.a.name{ii} =        d.r.a.a{ii}.nameShort();
                    d.r.a.nameUnit{ii} =    d.r.a.a{ii}.nameUnits();
                    d.r.a.unit{ii} =        d.d.axes{ii}.kind.extUnits;
                    
                    d.r.a.isNIDAQ(ii) =     strcmpi('nidaq', c.kind.kind(1:min(5,end))) && ~strcmpi('cDAQ1Mod1', c.dev);    % Find the nidaq devices (because we can make these go faster). cDAQ1Mod1 is a DAQ in the diamond room that controls galvos. Our counter is on Dev1. Because these cannot be used together for timed tasks, axes on cDAQ1Mod1 are not considered fask nidaq axes programatically.
                    d.r.a.inEmulation(ii) = d.r.a.a{ii}.inEmulation;
                    
%                     d.r.a.prev =            d.r.a.a{ii}.getX();
                    
                    d.r.a.scansInternalUnits{ii} = arrayfun(d.r.a.a{ii}.config.kind.ext2intConv, d.d.scans{ii});
                end
                
                % GENERATE LAYER RUNTIME DATA (r.l) ============================================================================
                
                d.r.l.name =        [justname       d.r.l.name];
                d.r.l.nameUnit =    [d.r.a.nameUnit d.r.l.nameUnit];
                d.r.l.unit =        [d.r.a.unit     d.r.l.unit];
                
                d.r.l.num = d.r.a.num + d.r.i.numInputAxes;
                
                % Then, figure out how we should initially display the data, based on the total number of axes we have.
                d.r.plotMode = max(min(2, d.r.a.num + d.r.i.numInputAxes),1);   % Plotmode takes in 0 = histogram (no axes); 1 = 1D (1 axis); ...
                
                % And choose which axes to initially display.
                d.r.l.layer = ones(1,  d.r.a.num + d.r.i.numInputAxes)*(1 + d.r.plotMode);  % e.g. for 2D, the layer is initially set to all 3s.
                n = min(d.r.plotMode, d.r.a.num + d.r.i.numInputAxes);
                d.r.l.layer(1:n) = 1:n;                                                     % Then the first two axes are set to 1 and 2 (for 2D).
                
                % Then, add mcAxis info to the layer information...
                d.r.l.axis =    [ones( 1, d.r.a.num) d.r.l.axis];
                d.r.l.type =    [zeros(1, d.r.a.num) d.r.l.type];
                d.r.l.lengths = [d.r.a.length  d.r.l.lengths];
                d.r.l.scans =   [d.d.scans d.r.l.scans];
                
                % Index weight is best described by an example: If one has a 5x4x3 matrix, then incrimenting the x axis
                %   increases the linear index (the index if the matrix was streached out) by one. Incrimenting the y axis
                %   increases the linear index by 5. And incrimenting the z axis increases the linear index by 20 = 5*4. So the
                %   index weight in this case is [1 5 20].
                d.r.l.weight =  [ones(1,  d.r.a.num) d.r.l.weight];    
                
                % Make index weight according to the above specification.
                for ii = 2:(d.r.a.num + 1) % Not sure about this line!!!        % replace? d.r.i.numInputAxes
                    d.r.l.weight(ii:end) = d.r.l.weight(ii:end) * d.r.a.length(ii-1);
                end
                
                if ~isempty(d.d.axes)
                    d.d.flags.circTime = d.d.flags.circTime && strcmpi('time', d.d.axes{end}.kind.kind);
                
                    d.r.canScanFast = d.r.a.isNIDAQ(1) && ~d.r.a.inEmulation(1) && all(d.r.i.isNIDAQ & ~d.r.a.inEmulation);
                else
                    d.r.canScanFast = false;
                    d.d.flags.circTime = false;
                end
                
                % MCDATA NAMING ================================================================================================
                
                % Now, figure out what this mcData should be named.
                if ~isfield(d.d, 'name')
                    d.d.name = '';
                end
                
                % If there isn't already a name, generate one:
                if isempty(d.d.name)
                    if d.r.i.num < 5
                        for ii = 1:(d.r.i.num-1)
                            d.d.name = [d.d.name '[' d.d.inputs{ii}.name '], '];
                        end

                        d.d.name = [d.d.name '[' d.d.inputs{d.r.i.num}.name ']'];
                    else
                        d.d.name = ['[' num2str(d.r.i.num) ' inputs]'];
                    end
                        
                    if ~isempty(d.r.a.a)
                        d.d.name = [d.d.name ' vs '];
                        
                        if d.r.a.num < 5
                            for ii = 1:(d.r.a.num-1)
                                d.d.name = [d.d.name '[' d.r.l.name{ii} '], '];
                            end

                            d.d.name = [d.d.name '[' d.r.l.name{d.r.a.num} ']'];
                        else
                            d.d.name = ['[' num2str(d.r.a.num) ' axes]'];
                        end
                    end
                end
                
                % FINAL ========================================================================================================
                
                if ~isfield(d.d, 'index')
                    d.resetData();
                    d.r.scanMode = 0;
                else
                    d.r.scanMode = -1;      % Check for finished?
                end
                
                d.r.isInitialized = true;
            end
        end
        
        function resetData(d)
            % INITIALIZE THE DATA TO NAN 
            data =   cell([1, d.r.i.num]);      % d.r.i.num layers of data (one layer per input)

            for ii = 1:d.r.i.num
                % [d.r.l.lengths(d.r.l.type == 0 | d.r.l.type == ii) 1]
                data{ii} =      NaN([d.r.l.lengths(d.r.l.type == 0 | d.r.l.type == ii) 1]);
            end
            
            d.d.data = data;

            % Make the variable that keeps track of where we are in 
            d.d.index =          ones(1, d.r.a.num);
%             d.d.currentIndex =   2;
            
            d.d.info.version = mcInstrumentHandler.version();
            [d.d.info.fname, d.d.info.timestamp] =  mcInstrumentHandler.timestamp(1);
                
            d.r.scanMode = 0;
            
            [~, ~, ~, d.d.other.status] = mcInstrumentHandler.getAxes();    % Huge bug came from saving other.axes! Will fix soon.
        end
        
        function kill(d)
            

            
            if isvalid(d)
                d.r.aquiring = false;

                d.r.scanMode = -2;   % quit

                if isfield(d.r, 's') && ~isempty(d.r.s) && isvalid(d.r.s)
                    d.r.s.stop();
                end

                %display('mcData.kill(): Waiting for last mcInput to finish .measure()ing...');

                for ii = 1:d.r.i.num
                    if strcmpi(d.r.i.i{ii}.config.class, 'mciDataWrapper')
                        if isa(d.r.i.i{ii}.s, 'mcData')
                            d.r.i.i{ii}.s.kill();
                        end
                    end
                end
            end
        end
        
        function aquire(d)
            d.r.aquiring = true;
            d.r.scanMode = 1;
            
            if any(mcInstrumentHandler.version() ~= d.d.info.version)
                mcDialog(  ['Warning! This data was initalized with modular Control version [ ' num2str(d.d.info.version)... 
                            ' ]. The current version is [ ' num2str(mcInstrumentHandler.version()) ' ].'], 'Warning!');
            end
            
            % Check d.d.other.axes, d.d.other.status...
            
            if d.r.a.num == 0   % A simple case if we have no axes...
                for ii = 1:d.r.i.num
                    d.d.data{ii} = d.r.i.i{ii}.measure(d.d.intTimes(ii));
                end
                
%                 disp('HERE2')
                d.r.scanMode = 2;
            else
                nums = 1:d.r.a.num;

                if all(isnan(d.r.a.prev))       % If the previous positions of the axes have not already been set...
                    for ii = nums               % For every axis,
                        d.r.a.prev(ii) = d.r.a.a{ii}.getX();                % Remember the pre-scan positions of the axes.
                    end
                end

%                 if all(isnan(d.r.a.prev))       % Then goto the starting position...
                for ii = nums               % For every axis,
                    d.r.a.a{ii}.goto(d.d.scans{ii}(d.d.index(ii)));     % And goto the starting position.               
                end

                for ii = nums               % Then, again for every axis,
                    d.r.a.a{ii}.wait();     % Wait for the axis to reach the starting position (only relevant for micros/etc).        
                end
%                 end

                if d.r.aquiring
                    % Make a NIDAQ session if it is neccessary and has not already been created.
                    if d.r.canScanFast && (~isfield(d.r, 's') || isempty(d.r.s) || ~isvalid(d.r.s))
                        d.r.s = daq.createSession('ni');

%                         d.r.a.a{1}.s;
                        d.r.a.a{1}.close();
%                         d.r.a.a{1}.s;
                        d.r.a.a{1}.addToSession(d.r.s);         % First add the axis,

                        for ii = 1:d.r.i.num
%                             d.r.i.i{ii}.s
%                             d.r.i.i{ii}.close();
%                             d.r.i.i{ii}.s
                            d.r.i.i{ii}.addToSession(d.r.s);    % Then add the inputs
                        end
                    end 
                end

                while d.r.aquiring
                    w = d.r.l.weight(1:d.r.a.num);
                    w(1) = 0;
                    
                    d.aquire1D(w * (d.d.index - 1)' + 1);
                    
                    if length(d.r.a.a)>1
 %                       pause(1) %sri; settling time for new piezo stack
                    end
%                     if ~d.r.canScanFast
%                         drawnow
%                     end

                    currentlyMax =  d.d.index == d.r.a.length;  % Variables to figure out which indices need incrimenting/etc.

                    if all(currentlyMax) && ~d.d.flags.circTime       % If the scan has finished...
                        d.r.scanMode = 2;
                        break;
                    end

                    toIncriment =   [true currentlyMax(1:end-1)] & ~currentlyMax;
                    toReset =       [true currentlyMax(1:end-1)] &  currentlyMax;

                    if ~d.r.aquiring                % If the scan was stopped...
%                         display('Scan stopped...');
                        break;
                    end

                    if d.d.flags.circTime && toIncriment(end)     % If we have run out of bounds and need to circshift...
%                         disp('Time is axis and overrun!');

                        for ii = 1:d.r.i.num        % ...for every input, circshift the data forward one 'time' forward.
                            d.d.data{ii} = circshift(d.d.data{ii}, [0, max(d.r.l.weight(d.r.l.type == 0 | d.r.l.type == ii))]);
                        end

                        toIncriment(end) = false;   % and pretend that the time axis does not need to be incrimented.
                    end

                    d.d.index = d.d.index + toIncriment;    % Incriment all the indices that were after a maximized index and not maximized.
                    d.d.index(toReset) = 1;                 % Reset all the indices that were maxed (except the first) to one.

                    for ii = nums((toIncriment | toReset) & nums ~= 1)
                        a = d.r.a.a;
                        a{ii}.goto(d.d.scans{ii}(d.d.index(ii)));
                    end
                end
                
%                 display('Exited loop...');

                if d.r.canScanFast   % Destroy the session, if a session was created.
                    release(d.r.s);
                    delete(d.r.s);
                    d.r.s = [];
                end
                
%                 mode = d.r.scanMode
                    
                if d.r.scanMode == -2       % If dataViewer was quit midscan.
                    for ii = nums
                        d.r.a.a{ii}.goto(d.r.a.prev(ii));  % Then goto the stored previous values.
                    end
                    
%                     'deleting!'
                    delete(d);
                elseif d.r.scanMode == 0                % If the data was reset mid-scan,
%                     'reset!'
                    d.resetData();                      % Reset again to make sure that the last scan wasn't saved (improve this?).
                elseif d.r.scanMode ~= 2                % If the scan was unexpectantly stopped.
%                     display('...set to paused...');
                    d.r.scanMode = -1;
%                     display('...now.');
                elseif d.d.flags.shouldOptimize     % If there should be a post-scan optimization...
                    switch length(d.r.a.a)
                        case 1
                            [x, ~] = mcPeakFinder(d.d.data{1}, d.d.scans{1}, 0);        % First find the peak.
                            
                            x =     max(min(d.r.a.a{1}.config.kind.extRange), min(max(d.r.a.a{1}.config.kind.extRange), x + d.d.flags.optimizeMove));                 % Truncate x to the axis range...
                            fx =    max(min(d.r.a.a{1}.config.kind.extRange), min(max(d.r.a.a{1}.config.kind.extRange), d.d.scans{1}(1) + d.d.flags.optimizeMove));   % Truncate fx (which is in the direction that one should approach from) to the axis range...
                          
                            d.r.a.a{1}.goto(fx);                                        % Trying to approach from the same direction...
                            d.r.a.a{1}.goto(x);                                         % ...goto the peak.
                        case 2
                            [x, y] = mcPeakFinder(d.d.data{1}, d.d.scans{1}, d.d.scans{2});     % First find the peak.
                            
                            x =     max(min(d.r.a.a{1}.extRange), min(max(d.r.a.a{1}.extRange), x + d.d.flags.optimizeMove(1)));                 % Truncate x to the axis range...
                            fx =    max(min(d.r.a.a{1}.extRange), min(max(d.r.a.a{1}.extRange), d.d.scans{1}(1) + d.d.flags.optimizeMove(1)));   % Truncate fx (which is in the direction that one should approach from) to the axis range...
                          
                            y =     max(min(d.r.a.a{2}.extRange), min(max(d.r.a.a{2}.extRange), y + d.d.flags.optimizeMove(2)));                 % Truncate y to the axis range...
                            fy =    max(min(d.r.a.a{2}.extRange), min(max(d.r.a.a{2}.extRange), d.d.scans{2}(1) + d.d.flags.optimizeMove(2)));   % Truncate fy (which is in the direction that one should approach from) to the axis range...
                            
                            d.r.a.a{1}.goto(fx);                                                % Approaching from the same direction...
                            d.r.a.a{2}.goto(fy);

                            d.r.a.a{1}.goto(x);                                                 % ...goto the peak.
                            d.r.a.a{2}.goto(y);
                        otherwise
                            disp('mcData.aquire(): Optimization on more than 2 axes is not currently supported...');
                    end
                    
                    
                elseif d.r.scanMode == 2            % Should the axes goto the original values after the scan finishes?
                    for ii = nums
                        d.r.a.a{ii}.goto(d.r.a.prev(ii));  % Then goto the stored previous values.
                    end
                end

                if isvalid(d)
                    if ~d.d.flags.shouldOptimize
                        d.save();
                    end
                else
                    disp('mcData.aquire(): Warning: deleted abruptly; could not save...')
                end
            end
        end
        function aquire1D(d, jj)
            if length(d.d.axes) == 1 && d.d.flags.circTime    % If time happens to be the current axis and we should circshift...
%                 disp('Time is only axis')
                
                while d.r.aquiring
                    for ii = 1:d.r.i.num
                        len = max(d.r.l.weight(d.r.l.type == 0 | d.r.l.type == ii));
                        
                        nums = 1:d.r.l.num;
                        
                        data = circshift(d.d.data{ii}, round(nums == d.r.a.num));
                        
                        if len == 1
                            data(1) =                           d.r.i.i{ii}.measure(d.d.intTimes(ii));
                        else
                            w = d.r.l.weight(d.r.a.num + 1);
                            data(1:w:(w*d.r.i.length(ii))) =    d.r.i.i{ii}.measure(d.d.intTimes(ii));
                        end
                        
                        d.d.data{ii} = data;
                    end
                end
            elseif d.r.canScanFast
                d.r.s.Rate = 1/max(d.d.intTimes);     % Whoops; integration time has to be the same for all inputs... Taking the max for now...
                
                d.r.s.queueOutputData([d.r.a.scansInternalUnits{1}  d.r.a.scansInternalUnits{1}(1)]');   % The last point (a repeat of the final params.scan point) is to count for the last pixel (counts are differences).

                d.r.s;
                
                [data_, times] = d.r.s.startForeground();       % Should I startBackground() and use a listener? (Do this in the future!)

                for ii = 1:d.r.i.num     % Fill all of the inputs with data...
                    if d.d.inputs{ii}.kind.shouldNormalize  % If this input expects to be divided by the exposure time...
                        d.d.data{ii}(jj:jj+d.r.a.length(1)-1) = (diff(double(data_(:, ii)))./diff(double(times)))';   % Should measurment time be saved also? Should I do diff beforehand instead of individually?
                    else
                        d.d.data{ii}(jj:jj+d.r.a.length(1)-1) = double(data_(1:end-1, ii))';
                    end
                end
                
                if ~isempty(d.d.index)
                    d.d.index(1) = d.r.a.length(1);
                end
            else
                for kk = d.d.index(1):d.r.a.length(1)
%                     toc
%                     tic
                    if d.r.aquiring
                        d.r.a.a{1}.goto(d.d.scans{1}(kk));             % Goto each point...
                        d.r.a.a{1}.wait();              % ...wait for the axis to arrive (for some types)...

                        for ii = 1:d.r.i.num         % ...for every input...
                            if d.r.i.dimension(ii) == 0
                                d.d.data{ii}(jj+kk-1) = d.r.i.i{ii}.measure(d.d.intTimes(ii));  % ...measure.
                            else
                                w =     d.r.l.weight(d.r.a.num + 1);
                                base = (jj+kk-2) + 1;
                                d.d.data{ii}(base:w:(w*d.r.i.length(ii)+base-1)) = d.r.i.i{ii}.measure(d.d.intTimes(ii));  % ...measure.
                            end
                        end
                    else
                        d.d.index(1) = kk;
                        return;
                    end
                    d.d.index(1) = kk;
                end
            end
          
            
        end
    end
    
    % Additional Functionality
    methods
        function save(d)                % Background-saves the .mat file. Note that manual saving is done in mcDataViewer. (make a console command for manual saving, eventually?).


            %             'saving'
            data = d.d;     %#ok
%             tic
            
%             fname = replace(d.d.name, {'/', '\', ':', '"', '?', '<', '>', '|'}, '_');

            characters = {'/', '\', ':', '"', '?', '<', '>', '|'};

            fname = d.d.name;
            
            for ii = 1:length(characters)
                fname = strrep(fname, characters{ii}, '_');
            end

%             [d.d.info.fname ' ' fname]
            save([d.d.info.fname ' ' fname], 'data');
%             toc
        end
        
        function str = indexName()      % Brief name corresponding to current index (the point in axis-space that is currently being measured)
            d.index
        end
        
        function str = indexNameVerb()  % More elaborate (verbose) version of the above.
            
        end
    end
end





