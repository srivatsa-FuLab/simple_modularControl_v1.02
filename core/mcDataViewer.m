classdef mcDataViewer < mcSavableClass
% mcDataViewer provides a GUI for mcData.
%
% Syntax:
%   - mcDataViewer()                                                            % Views the default mcData object.
%   - mcDataViewer(data)                                                        % Views the mcData object corresponding to data. Data can be an mcData object, or anything that is valid in the line mcData(data) (e.g. d config, fname string). (Future: check to make sure this behaves nicely if an irregular type is given)
%   - mcDataViewer(data, shouldMakeManager)                                     % Same as the above, except with an additional boolean flag denoting whether the control figure should be initially visible.
%   - mcDataViewer(data, shouldMakeManager, shouldMakeVisible)                  % Same as the above, except with an additional boolean flag denoting whether the data figure should be initially visible.
%   - mcDataViewer(data, shouldMakeManager, shouldMakeVisible, shouldAquire)    % Same as the above, except with an additional boolean flag denoting whether the scan should start upon initialization.
%
% Status: Mostly finished, somewhat commented. 
% Future: definitely RGB, maybe 3D? Needs cleaning and oganization (e.g. color.R, color.G instead of colorR, colorG).
    
    properties  % Colors
        colorR = [1 0 0];
        colorG = [0 1 0];
        colorB = [0 0 1];
        
        colorSel = [1 0 1];  % Color of the lines and points denoting...     ...the currently-selected position
        colorPix = [1 1 0];  %                                               ...the pixel nearest to the currently-selected position
        colorAct = [0 1 1];  %                                               ...the actual (physical) position of the axes
        colorPrv = [0 .5 .5];  %                                             ...the previous (physical) position of the axes (e.g. for optimization).
    end

    properties  % Figure vars
        data = [];          % mcData structure currently being plotted.
        
        r = [];             % Three channels of processed data.
        g = [];
        b = [];
        
        cf = [];            % Control figure.
        cfToggle = [];      % uitoggletool in the bar that controls the visibility of cf.
        
        df = [];            % Data figure.
        a = [];             % Main axes in the data figure.
        cbar = [];          % Colorbar (eventually sort somewhere nicer).
        
        p = [];             % plot() object (for 1D).
        i = [];             % image() object (for 2D).
        % s = [];             % surf() object (for 3D)?
        h = [];             % histogram() object.
        
        pos = [];           % Contains four scatter plots (each containing one point) that denote the selected point, the selected pixel, the current point (of the axes), and the previous point (e.g. before optimization).
        posL = [];          % Contains four lines plots (each containing one line...   "     "     "   ...
        patches = [];       % Contains four patches  (each containing four points; the corners of a rectangle...   "     "     "   ...
        
        menus = [];
        tabs = [];
        scanButton = [];
        resetButton = [];
        scale = [];
        
        listeners = [];
        
        params = [];
        params1D = [];
        params2D = [];
        paramsGray = [];
        paramsRGB = [];
        
        isRGB = 0;
        
        selData = [0 0 0];
        
        scaleMin = [0 0 0]; % Unused?
        scaleMax = [1 1 1];
        
        shouldPlot = true;  % Variable to tell the gui not to plot (e.g. when plotSetup changes are happening)
        
        isPersistant = false;   % Whether the mcDataViewer should stick around when it is closed with closefigure.
    end
    
    methods (Static)
        function load()
            mcDataViewer.loadGUI_Callback(0,0)
        end
        function loadGUI_Callback(~, ~, ~)
            [FileName, PathName] = uigetfile({'*.mat','MAT-files (*.mat)'; '*.*',  'All Files (*.*)'}, 'Pick a saved mcData .mat to load in a new window...', mcInstrumentHandler.getSaveFolder(0));
            
            if isequal(FileName,0)
                disp('mcDataViewer.loadGUI_Callback(): No file given to load...');
            else
                mcDataViewer(mcData([PathName FileName]), false)    % Don't show the control window when opening...
            end
        end
    end
    
    methods
        function gui = mcDataViewer(varargin)
            shouldAquire = true;        % Change? This means that the scan will start automatically, by default.
            shouldMakeManager = true;
            shouldMakeVisible = true;
            
            switch nargin
                case 0
                    gui.data = mcData();
                otherwise
                    gui.data = varargin{1};
            end
            
            if ~isa(gui.data, 'mcData')         % If gui.data isn't an mcData object...
                gui.data = mcData(gui.data);    % Then use gui.data as the input for the mcData constructor.
            end
            
            if gui.data.r.scanMode == 2 || gui.data.r.scanMode == -1
                shouldAquire = false;
            end
            
            if nargin >= 2
                shouldMakeManager = varargin{2};
            end
            if nargin >= 3
                shouldMakeVisible = varargin{3};
            end
            if nargin >= 4
                shouldAquire =      varargin{4};
            end
            
            gui.data.dataViewer = gui;          % Make sure that the dataViewer has a pointer to this gui.
            gui.r = mcProcessedData(gui.data);  % And make the 3 channels of processed data that are displayed.
            gui.g = mcProcessedData(gui.data);
            gui.b = mcProcessedData(gui.data);
            
            % Control Figure --------------------------------------------------------------------------------------------------------------
            gui.cf = mcInstrumentHandler.createFigure(gui, 'saveopen');
            gui.cf.Visible = 'off';
            gui.cf.Position = [100,100,300,600];
            gui.cf.CloseRequestFcn = @gui.closeRequestFcnCF;
            gui.cf.Resize = 'off';      % Change? What if there are too many axes?
            gui.cf.Name = [gui.data.d.name];
            
            utg = uitabgroup('Parent', gui.cf, 'Position', [0, .525, 1, .475], 'SelectionChangedFcn', @gui.upperTabSwitch_Callback);
            gui.tabs.t0  = uitab('Parent', utg, 'Title', '0D');
            gui.tabs.t1d = uitab('Parent', utg, 'Title', '1D');
            gui.tabs.t2d = uitab('Parent', utg, 'Title', '2D');
            gui.tabs.t3d = uitab('Parent', utg, 'Title', '3D');

            javaenable = false;
            
            if javaenable
                jtabgroup = findjobj(utg);
                jtabgroup(end).setEnabledAt(3,0);
                gui.cf.Visible = 'off';
            end
 
            switch gui.data.r.plotMode
                case 0
                    utg.SelectedTab = gui.tabs.t0;
                    if javaenable
                        jtabgroup(end).setEnabledAt(1,0);
                        jtabgroup(end).setEnabledAt(2,0);
                    end
                case 1
                    utg.SelectedTab = gui.tabs.t1d;
                    if javaenable
                        jtabgroup(end).setEnabledAt(2,0);
                    end
                case 2
                    utg.SelectedTab = gui.tabs.t2d;
            end
            gui.cf.Visible = 'off';

            gui.tabs.t1d.Units = 'pixels';
            tabpos = gui.tabs.t1d.Position;

            bh = 22;
            ts = -5;
            if javaenable
                os = -5;            %#ok
            else
                os = -5 - 2*bh;     %#ok
            end

            uicontrol('Parent', gui.tabs.t3d, 'Style', 'text', 'String', 'Sometime?', 'HorizontalAlignment', 'center', 'Units', 'normalized', 'Position', [0 0 1 .95]);

            cp = .5;    % Choose position: the x value (normalized to [0 1]) of the position of the choose box.
            cw = .4;    % Choose width: the width of the choose box. should be less than or equal to 1 - cp.
            
            gui.params1D.chooseList = cell(1, gui.data.r.a.num); % This will be longer, but we choose not to calculate.
            gui.params2D.chooseList = cell(1, gui.data.r.a.num);

            for ii = 1:gui.data.r.a.num
                levellist = strcat(strread(num2str(gui.data.r.l.scans{ii}), '%s')', [' ' gui.data.r.a.a{ii}.config.kind.extUnits]);  %#ok Returns the numbers in scans in '##.## unit' form.

                for tab = [gui.tabs.t1d gui.tabs.t2d]
%                         uicontrol('Parent', tab, 'Style', 'text', 'TooltipString', gui.data.r.a.a{kk}.nameShort(), 'String', [gui.data.d.axes{ii}.name ': '], 'Units', 'pixels', 'Position', [0 tabpos(4)-bh*ii-2*bh 2*tabpos(3)/3 bh], 'HorizontalAlignment', 'right');

                    uicontrol(  'Parent', tab,...
                                'Style', 'text',...
                                'TooltipString', gui.data.r.a.name{ii},...
                                'String', [gui.data.r.l.name{ii} ': '],...
                                'Units', 'pixels',...
                                'Position', [0 tabpos(4)-bh*ii+os+ts cp*tabpos(3) bh],...
                                'HorizontalAlignment', 'right');

                    if tab == gui.tabs.t1d
                        axeslist = {'X', 'Mean'};
                    else
                        axeslist = {'X', 'Y', 'Mean'};
                    end

                    val = length(axeslist);

                    if ii == 1 && val > 1       % Sets the first and second axes (or inputs) to be the X and Y axes, while the rest are on the first layer
                        val = 1;
                    elseif ii == 2 && val > 2
                        val = 2;
                    end

                    choose = uicontrol( 'Parent', tab,...
                                        'Style', 'popupmenu',...
                                        'String', [axeslist, levellist],...
                                        'Units', 'pixels',...
                                        'Position', [cp*tabpos(3) tabpos(4)-bh*ii+os cw*tabpos(3) bh],...
                                        'Value', val,...
                                        'Callback', @gui.updateLayer_Callback);

                    if tab == gui.tabs.t1d
                        gui.params1D.chooseList{ii} = choose;
                    else
                        gui.params2D.chooseList{ii} = choose;
                    end

%                         gui.data.r.l.axis(ii) = 0;     % The layer is an axis.
%                         gui.data.r.l.type(ii) = ii;
%                         gui.data.r.l.layerDim(ii) = 1;
                end
            end

            inputLetters = 'XYZUVW';

            if isempty(ii)  % If there wasn't an axis loop, reset ii.
                ii = 0;
            end

%                 display('adding inputs');

            for kk = 1:gui.data.r.i.num
                if gui.data.r.i.dimension(kk) <= length(inputLetters)
                    jj = 0;

                    for sizeInput = gui.data.d.inputs{kk}.kind.sizeInput
                        if sizeInput ~= 1       % A vector, according to matlab, has size [1 N]. We don't want to count the 1.
                            jj = jj + 1;
                            ii = ii + 1;        % Use the ii from the axis loop.

                            levellist = strcat('pixel #', strread(num2str(1:sizeInput), '%s')');  %#ok Returns the pixels in 'pixel ##' form.

                            for tab = [gui.tabs.t1d gui.tabs.t2d]
                                % Make the text in the form 'input_name X' where X can be any letter in inputLetters.
                                uicontrol(  'Parent', tab,...
                                            'Style', 'text',...
                                            'TooltipString', [inputLetters(jj) ' axis of ' gui.data.r.i.i{kk}.nameShort()],...
                                            'String', [gui.data.d.inputs{kk}.name ' ' inputLetters(jj) ': '],...
                                            'Units', 'pixels',...
                                            'Position', [0 tabpos(4)-bh*ii+os+ts cp*tabpos(3) bh],...
                                            'HorizontalAlignment', 'right');

%                                     uicontrol('Parent', tab, 'Style', 'text', 'TooltipString', gui.data.r.i.name{kk}, 'String', [gui.data.r.l.name{kk + } ': '], 'Units', 'pixels', 'Position', [0 tabpos(4)-bh*ii-2*bh 2*tabpos(3)/3 bh], 'HorizontalAlignment', 'right');

                                if tab == gui.tabs.t1d
                                    axeslist = {'X', 'Mean'};
                                else
                                    axeslist = {'X', 'Y', 'Mean'};
                                end

                                val = length(axeslist);

                                if ii == 1 && val > 1       % Sets the first and second axes (or inputs) to be the X and Y axes, while the rest are on the first layer
                                    val = 1;
                                elseif ii == 2 && val > 2
                                    val = 2;
                                end

                                choose = uicontrol( 'Parent', tab,...
                                                    'Style', 'popupmenu',...
                                                    'String', [axeslist, levellist],...
                                                    'Units', 'pixels',...
                                                    'Position', [cp*tabpos(3) tabpos(4)-bh*ii+os cw*tabpos(3) bh],...
                                                    'Value', val,...
                                                    'Callback', @gui.updateLayer_Callback);

                                if tab == gui.tabs.t1d
                                    gui.params1D.chooseList{ii} = choose;
                                else
                                    gui.params2D.chooseList{ii} = choose;
                                end

%                                     gui.data.r.l.axis(ii) = 1;     % The layer is an input.
%                                     gui.data.r.l.type(ii) = kk;
%                                     gui.data.r.l.layerDim(ii) = 1;
                            end
                        end
                    end
                else
                    error('mcDataViewer: Input has too many dimensions... Too big for inputletters ''XYZUVW''. Fix?');
                end
            end

            ltg = uitabgroup('Parent', gui.cf, 'Position', [0, .05, 1, .475], 'SelectionChangedFcn', @gui.lowerTabSwitch_Callback);
            gui.tabs.gray = uitab('Parent', ltg, 'Title', 'Gray');
            gui.tabs.rgb =  uitab('Parent', ltg, 'Title', 'RGB');

            if javaenable
                jtabgroup = findjobj(ltg);
                jtabgroup(end).setEnabledAt(1,0);
                gui.cf.Visible = 'off';
            end

            gui.tabs.gray.Units = 'pixels';
            tabpos = gui.tabs.gray.Position;
            inputlist = cellfun(@(x)({x.name()}), gui.data.r.i.i);
            
            if gui.data.r.plotMode > 1 && gui.data.r.l.type(gui.data.r.l.layer == 2) > 0  % If we are in 2D, and using an input axis,
                gui.r.input = gui.data.r.l.type(gui.data.r.l.layer == 2);     % Then the selected input must be that input axis.
%                 INPUT = gui.r.input
            end

            uicontrol(  'Parent', gui.tabs.gray,...
                        'Style', 'text',...
                        'String', 'Input: ',...
                        'Units', 'pixels',...
                        'Position', [0 tabpos(4)-bh+os+ts tabpos(3)/3 bh],...
                        'HorizontalAlignment', 'right');
            gui.paramsGray.choose = uicontrol(  'Parent', gui.tabs.gray,...
                                                'Style', 'popupmenu',...
                                                'String', inputlist,...
                                                'Units', 'pixels',...
                                                'Position', [tabpos(3)/3 tabpos(4)-bh+os 2*tabpos(3)/3 - bh bh],...
                                                'Value', gui.r.input,...
                                                'Callback', @gui.updateInput_Callback);


            gui.scale.gray =    mcScalePanel(gui.tabs.gray, [(tabpos(3) - 250)/2 os+tabpos(4)-110], gui.r);

            gui.scale.r =       mcScalePanel(gui.tabs.rgb,  [(tabpos(3) - 250)/2 os+tabpos(4)-110], gui.r);
            gui.scale.g =       mcScalePanel(gui.tabs.rgb,  [(tabpos(3) - 250)/2 os+tabpos(4)-210], gui.g);
            gui.scale.b =       mcScalePanel(gui.tabs.rgb,  [(tabpos(3) - 250)/2 os+tabpos(4)-310], gui.b);

            gui.scanButton =    uicontrol('Parent', gui.cf, 'Style', 'push', 'Units', 'normalized', 'Position', [0, 0, .75, .05],   'Callback', @gui.scanButton_Callback);
            gui.resetButton =   uicontrol('Parent', gui.cf, 'String', 'Reset', 'Style', 'push', 'Units', 'normalized', 'Position', [.75, 0, .25, .05], 'Callback', @gui.resetButton_Callback);

            if gui.data.r.scanMode == 0                   % If new
                gui.scanButton.String = 'Start';
            elseif gui.data.r.scanMode == -1              % If paused
                gui.scanButton.String = 'Continue'; 
            elseif gui.data.r.scanMode == 2               % If finished
                gui.scanButton.String = 'Rescan';
            end
            
            % Data Figure/etc --------------------------------------------------------------------------------------------------------------
            gui.df = mcInstrumentHandler.createFigure(gui, 'saveopen');
            gui.df.GraphicsSmoothing = 'on';
            hToolbar = findall(gui.df, 'tag', 'FigureToolBar');
            gui.cfToggle = uitoggletool(hToolbar, 'TooltipString', 'Control Figure', 'ClickedCallback', @gui.toggleCF_Callback, 'CData', iconRead(fullfile('icons','control_figure.png')), 'State', gui.cf.Visible);

            gui.df.CloseRequestFcn = @gui.closeRequestFcnDF;
            menu = uicontextmenu;
            gui.menus.menu = menu;

            gui.a = axes('Parent', gui.df, 'ButtonDownFcn', @gui.figureClickCallback, 'DataAspectRatioMode', 'manual', 'BoxStyle', 'full', 'Box', 'on', 'UIContextMenu', menu, 'Xgrid', 'on', 'Ygrid', 'on'); %
            gui.a.Layer = 'top';
%             gui.a.XMinorTick = 'on';
%             gui.a.YMinorTick = 'on';
            gui.a.TickDir = 'both';
            
            colormap(gui.a, gray(256)); % Change when RGB is added...
            
            hold(gui.a, 'on');
            
            gui.r.process();
            if gui.isRGB
                gui.g.process();
                gui.b.process();
            end
            
            % Some junk values for the initial plotting while we make all of the UI objects.
            x = 1:50;
            y = 1:50;
            c = mod(magic(50),2);
            
            gui.cbar = colorbar(gui.a);
            gui.cbar.Label.String = 'Intensity (cts/sec)';
            
            % Histogram Setup --------------------------------------------------------------------------------------------------------------
            gui.h = [histogram(x, 'Parent', gui.a), histogram(x, 'Parent', gui.a), histogram(x, 'Parent', gui.a)];
            
            gui.h(1).FaceColor = gui.colorR;
            gui.h(2).FaceColor = gui.colorG;
            gui.h(3).FaceColor = gui.colorB;
            
            gui.h(1).FaceColor = gui.colorR;
            gui.h(2).FaceColor = gui.colorG;
            gui.h(3).FaceColor = gui.colorB;
            
            gui.h(1).EdgeColor = gui.colorR;
            gui.h(2).EdgeColor = gui.colorG;
            gui.h(3).EdgeColor = gui.colorB;
            
            % 1D Setup --------------------------------------------------------------------------------------------------------------
            gui.p = plot(x, rand(1, 50), x, rand(1, 50), x, rand(1, 50), 'Parent', gui.a, 'XDataMode', 'manual', 'YDataMode', 'manual', 'ButtonDownFcn', @gui.figureClickCallback, 'UIContextMenu', menu, 'Visible', 'off');
            
            gui.p(1).Color = gui.colorR;
            gui.p(2).Color = gui.colorG;
            gui.p(3).Color = gui.colorB;
            
            % Change this to line() instead of plot()?
            gui.posL.prv = plot([0 0], [-100 100], 'Parent', gui.a, 'XDataMode', 'manual', 'YDataMode', 'manual', 'LineStyle', '--', 'Color', gui.colorPrv, 'PickableParts', 'none', 'Linewidth', 2, 'Visible', 'off');
            gui.posL.sel = plot([0 0], [-100 100], 'Parent', gui.a, 'XDataMode', 'manual', 'YDataMode', 'manual', 'Color', gui.colorSel, 'PickableParts', 'none', 'Linewidth', 1, 'Visible', 'off');
            gui.posL.pix = plot([0 0], [-100 100], 'Parent', gui.a, 'XDataMode', 'manual', 'YDataMode', 'manual', 'Color', gui.colorPix, 'PickableParts', 'none', 'Linewidth', 2, 'Visible', 'off');
            gui.posL.act = plot([0 0], [-100 100], 'Parent', gui.a, 'XDataMode', 'manual', 'YDataMode', 'manual', 'Color', gui.colorAct, 'PickableParts', 'none', 'Linewidth', 2, 'Visible', 'off');
            
            % 2D Setup --------------------------------------------------------------------------------------------------------------
            gui.i = imagesc(x, y, c, 'Parent', gui.a, 'alphadata', c, 'XDataMode', 'manual', 'YDataMode', 'manual', 'ButtonDownFcn', @gui.figureClickCallback, 'UIContextMenu', menu, 'Visible', 'off');
            
            % Change this to patch() instead of scatter()?
            gui.pos.prv = scatter(0, 0, 'Parent', gui.a, 'SizeData', 40, 'XDataMode', 'manual', 'YDataMode', 'manual', 'CData', gui.colorPrv, 'PickableParts', 'none', 'Linewidth', 2, 'Marker', 'o', 'Visible', 'off');
            gui.pos.sel = scatter(0, 0, 'Parent', gui.a, 'SizeData', 40, 'XDataMode', 'manual', 'YDataMode', 'manual', 'CData', gui.colorSel, 'PickableParts', 'none', 'Linewidth', 2, 'Marker', 'x', 'Visible', 'off');
            gui.pos.pix = scatter(0, 0, 'Parent', gui.a, 'SizeData', 40, 'XDataMode', 'manual', 'YDataMode', 'manual', 'CData', gui.colorPix, 'PickableParts', 'none', 'Linewidth', 2, 'Marker', 'x', 'Visible', 'off');
            gui.pos.act = scatter(0, 0, 'Parent', gui.a, 'SizeData', 40, 'XDataMode', 'manual', 'YDataMode', 'manual', 'CData', gui.colorAct, 'PickableParts', 'none', 'Linewidth', 2, 'Marker', 'o', 'Visible', 'off');
            
            if true % darkmode
                gui.a.Color = [.1 .15 .1];
                gui.a.GridColor = [.9 .95 .9];
                gui.a.XColor = 'white';
                gui.a.YColor = 'white';
                gui.a.Title.Color = 'white';
                gui.df.Color = 'black';
                gui.cbar.Color = 'white';
            end
            
            if true % thickness
                gui.a.LineWidth = 1;
                gui.a.FontSize = 15;
                
                gui.cbar.LineWidth = 1;
                gui.cbar.FontSize = 15;
                
                gui.cbar.Label.LineWidth = 1;
                gui.cbar.Label.FontSize = 15;
                
                for ii = 1:3
                    gui.p(ii).LineWidth = 2;
                    gui.h(ii).LineWidth = 2;
                end
            end
            
            gui.a.YDir = 'normal';      % When imagesc(a) is called, a.YDir is set to Reverse. This reverts that change.
            
            % Menu Setup --------------------------------------------------------------------------------------------------------------
            gui.menus.ctsMenu = uimenu(menu, 'Label', 'Value: ~~.~~ --',                    'Callback', @copyLabelToClipboard); %, 'Enable', 'off');
            gui.menus.pixMenu = uimenu(menu, 'Label', 'Pixel: [ ~~.~~ --, ~~.~~ -- ]',      'Callback', @copyLabelToClipboard); %, 'Enable', 'off');
            gui.menus.posMenu = uimenu(menu, 'Label', 'Position: [ ~~.~~ --, ~~.~~ -- ]',   'Callback', @copyLabelToClipboard); %, 'Enable', 'off');
            
            mGoto = uimenu(menu, 'Label', 'Goto');
                mgPix = uimenu(mGoto, 'Label', 'Selected Pixel',    'Callback', {@gui.gotoPostion_Callback, 0, 0});                             %#ok
                mgPos = uimenu(mGoto, 'Label', 'Selected Position', 'Callback', {@gui.gotoPostion_Callback, 1, 0});                             %#ok
                mgPixL= uimenu(mGoto, 'Label', 'Selected Pixel And Layer',    'Callback', {@gui.gotoPostion_Callback, 0, 1});                   %#ok
                mgPosL= uimenu(mGoto, 'Label', 'Selected Position And Layer', 'Callback', {@gui.gotoPostion_Callback, 1, 1});                   %#ok
                
            mNorm = uimenu(menu, 'Label', 'Normalization'); %, 'Enable', 'off');
                mnMin = uimenu(mNorm, 'Label', 'Set as Minimum', 'Callback',    {@gui.minmax_Callback, 0});                                     %#ok
                mnMax = uimenu(mNorm, 'Label', 'Set as Maximum',  'Callback',   {@gui.minmax_Callback, 1});                                     %#ok
                panel = gui.scale.gray;
                mnNorm= uimenu(mNorm, 'Label', 'Normalize All Layers', 'Callback',    @panel.normalize_Callback);                               %#ok
                mnNormT=uimenu(mNorm, 'Label', 'Normalize This Layer', 'Callback',    @gui.normalizeThis_Callback);                             %#ok
                
            mCount = uimenu(menu, 'Label', 'Counter'); %, 'Enable', 'off');
                mcOpen =    uimenu(mCount, 'Label', 'Open', 'Callback',     @gui.openCounter_Callback);                                         %#ok
                mcOpenAt =  uimenu(mCount, 'Label', 'Open at...');
                    mcoaPix = uimenu(mcOpenAt, 'Label', 'Selected Pixel',    'Callback', {@gui.openCounterAtPoint_Callback, 0, 0});             %#ok
                    mcoaPos = uimenu(mcOpenAt, 'Label', 'Selected Position', 'Callback', {@gui.openCounterAtPoint_Callback, 1, 0});             %#ok
                    mcoaPixL= uimenu(mcOpenAt, 'Label', 'Selected Pixel And Layer',    'Callback', {@gui.openCounterAtPoint_Callback, 0, 1});   %#ok
                    mcoaPosL= uimenu(mcOpenAt, 'Label', 'Selected Position And Layer', 'Callback', {@gui.openCounterAtPoint_Callback, 1, 1});   %#ok
            
            % Finishing --------------------------------------------------------------------------------------------------------------
            hold(gui.a, 'off');                     % Why does hold need to be off?
            
            gui.plotData_Callback(0,0);             % Do an initial plot of the data (usually empty) to get the axes to be proper.

            gui.listeners.x = [];                   % Why is it neccessary to set these to empty?
            gui.listeners.y = [];
            gui.resetAxisListeners();               % Generate the listeners for the axes that are active. This updates the (cyan) marker denoting the position of the axes.
            
            prop = findprop(gui.r, 'data');
            gui.listeners.r = event.proplistener(gui.r, prop, 'PostSet', @gui.plotData_Callback);
%             gui.listeners.g = event.proplistener(gui.g, prop, 'PostSet', @gui.plotData_Callback);
%             gui.listeners.b = event.proplistener(gui.b, prop, 'PostSet', @gui.plotData_Callback);
            
            gui.plotData_Callback(0,0);
            gui.plotSetup();
            gui.makeProperVisibility();
            
            if shouldMakeVisible                    % Whether the data figure should be initially visible
                gui.df.Visible = 'on';
                
                if shouldMakeManager                % Whether the control figure should be initially visible
                    gui.cf.Visible = 'on';
                else
                    gui.cf.Visible = 'off';
                end
            else
                gui.df.Visible = 'off';
            end
            
            pause(.05);                             % Give everything time to draw/update.
            
            gui.listenToAxes_Callback(0, 0);        % Then poll the axes for thier current positions (the callback is only called when the axes change, so we need the initial positions)
                    
            if shouldAquire
                gui.scanButton_Callback(0, 0);      % Starts aquiring the data.
            end
        end
        
        function saveGUI_Callback(gui, ~, ~)
            [FileName, PathName, FilterIndex] = uiputfile({ '*.mat', 'Full Data File (*.mat)';...
                                                            '*.mat', 'Currently Displayed Data (*.mat)';...
                                                            '*.png', 'Currently Displayed Image (*.png)';...
                                                            '*.png', 'Currently Displayed Image With Axes (*.png)';...
                                                            '*.png', 'Currently Displayed Image With Axes (Alternate Method) (*.png)';...
                                                            '*.jpg', 'Currently Displayed Image With Axes (*.jpg)';...
                                                            '*.pdf', 'Currently Displayed Image With Axes (*.pdf)';...
                                                            '*.tif', 'Currently Displayed Image With Axes (*.tif)';...
                                                            '*.fig', 'Currently Displayed Image As Figure (*.fig)'},...
                                                            'Save As', [mcInstrumentHandler.getSaveFolder(0) filesep gui.data.d.info.timestamp ' ' gui.data.d.name]);
            
            if all(FileName ~= 0)
%                 if ~gui.data.d.flags.shouldOptimize
%                     % Hide the position selection markers
%                 end

                gui.turnMarkersOff();       % Turn the markers (e.g. position, selection) off when we (possibly) capture an image.
                
                switch FilterIndex
                    case 1      % .mat
                        % This case is covered below (saves in all cases).
                    case 2      % .mat 2
                        data.r = gui.r.data;        %#ok
                        
                        if gui.isRGB
                            data.g = gui.b.data;    %#ok
                            data.b = gui.b.data;    %#ok
                        else
                            data.g = [];            %#ok
                            data.b = [];            %#ok
                        end
                        
                        % Add axes!
                        
%                         data
                        
                        save([PathName FileName], '-v6', 'data');      % Make sure that the extension is three characters?
                    case 3      % .png
                        if gui.data.r.plotMode == 0
                            warning(['mcDataViewer.saveGUI_Callback() - ' gui.data.d.name ': Cannot save an axes-less histogram. Sorry.'])
                        else
                            if      gui.data.r.plotMode == 1      % 1D
                                d = gui.p(1).YData;
                                lim = gui.p(1).YLim;
                            elseif  gui.data.r.plotMode == 2      % 2D
                                d = gui.i.CData;
                                lim = gui.a.CLim;
                            end

                            if diff(lim) ~= 0
                                d = (d - min(lim))/diff(lim);
                            end

                            imwrite(d, [PathName FileName]);
                        end
                    case 4      % .png (axes)
                        imwrite(frame2im(getframe(gui.df)), [PathName FileName]);
                    otherwise  % etc
                        saveas(gui.df, [PathName FileName]);
                end
                
                pause(.05);                                         % Pause to give time for the (possible) first file to save.
                
                data = gui.data.d;                                  %#ok % Always save the .mat file, even if the user doesn't specify... (change?)
                
                if FilterIndex == 1                                 % If the full file was selected, then just save it with the provided name.
                    save([PathName FileName], '-v6', 'data');
                else                                                % If something else was saved, then save the full file in addition.
                    save([PathName FileName(1:end-4) ' (full).mat'], '-v6', 'data');   % Make sure that the extension is three characters?
                end
                
                mcInstrumentHandler.setSaveFolder(0, PathName);     % The next time one tries to save in the foreground, it will start in this folder (Remove?).
                
                gui.makeProperVisibility(); % Turn the markers back on.
                
                pause(.05);                                         % Pause again
            else
                disp('No file given...');
            end
        end
        
        function closeRequestFcnDF(gui, ~, ~)   % Close function for the data figure (the one with the graph)
            if gui.isPersistant
                gui.cf.Visible = 'off';
                gui.cfToggle.State = 'off';
                gui.df.Visible = 'off';
            else
                gui.data.kill();

                if ~isempty(gui.listeners)
%                     'Killing listeners...'
                    
                    delete(gui.listeners.x);
                    delete(gui.listeners.y);
                    delete(gui.listeners.r);
    %                 delete(gui.listeners.g);    % Should these be commented?
    %                 delete(gui.listeners.b);
                end

                delete(gui.cf);
                delete(gui.df);
                
               % disp('mcDataViewer.kill(): Murder complete!');
            end
        end
        function closeRequestFcnCF(gui, ~, ~)   % Close function for the control figure (the one with the buttons)
            gui.toggleCF_Callback(0, 0)
        end
        function toggleCF_Callback(gui, ~, ~)
            if strcmpi(gui.cf.Visible, 'on')
                gui.cf.Visible = 'off';
                gui.cfToggle.State = 'off';
            else
                gui.cf.Visible = 'on';
                gui.cfToggle.State = 'on';
            end
        end
        
        function scanButton_Callback(gui, ~, ~)
            switch gui.data.r.scanMode   % -1 = paused, 0 = new, 1 = scanning, 2 = finished
                case {0, -1}                                % If new or paused
                    gui.scanButton.String = 'Pause';
                    gui.data.r.scanMode = 1;
                    gui.data.aquire();
                case 1                                      % If scanning
                    gui.data.r.aquiring = false;
                    gui.data.r.scanMode = -1;
                    gui.scanButton.String = 'Continue';
                case 2                                      % If finished
                    gui.data.resetData();
                    gui.scanButton.String = 'Pause';
                    gui.data.r.scanMode = 1;
                    gui.data.aquire();
            end
        end
        function resetButton_Callback(gui, ~, ~)
            gui.data.r.scanMode = 0;
            gui.data.r.aquiring = false;
            gui.data.resetData();
            gui.scanButton.String = 'Start';
        end
        
        function tf = acquire(gui)
            if gui.data.r.scanMode == 1         % If we are already aquiring.
                tf = false;
            else
                gui.scanButton_Callback(0, 0);
                tf = true;
            end
        end
        
        % uimenu callbacks (when right-clicking on the graph)
        function gotoPostion_Callback(gui, ~, ~, isSel, shouldGotoLayer)    % Menu option to goto a position. See below for function of isSel and shouldGotoLayer.
            if gui.data.r.plotMode == 1 || gui.data.r.plotMode == 2
                if gui.data.r.l.type(gui.data.r.l.layer == 1)
                    warning('Cannot goto an input axis...');
                else
                    axisX = gui.data.r.a.a{gui.data.r.l.layer == 1};

                    if isSel        % If the user wants to go to the selected position
                        if gui.data.r.plotMode == 1
                            axisX.goto(gui.posL.sel.XData(1));
                        else
                            axisX.goto(gui.pos.sel.XData(1));
                        end
                    else            % If the user wants to go to the selected pixel
                        if gui.data.r.plotMode == 1
                            axisX.goto(gui.posL.pix.XData(1));
                        else
                            axisX.goto(gui.pos.pix.XData(1));
                        end
                    end
                end
            end
            
            if gui.data.r.plotMode == 2
                if gui.data.r.l.type(gui.data.r.l.layer == 2)
                    warning('Cannot goto an input axis...');
                else
                    axisY = gui.data.r.a.a{gui.data.r.l.layer == 2};

                    if isSel        % If the user wants to go to the selected position
                        axisY.goto(gui.pos.sel.YData(1));
                    else            % If the user wants to go to the selected pixel
                        axisY.goto(gui.pos.pix.YData(1));
                    end
                end
            end
            
            if shouldGotoLayer  % If the use wants to goto the current layer also...
                for ii = 1:gui.data.r.a.num
                    if      gui.data.r.plotMode == 1 && ~any(gui.data.r.l.layer{ii} == [1 2])
                        scan = gui.data.r.l.scans{ii};
                        gui.data.r.a.a{ii}.goto(scan(gui.data.d.l.layer{ii} - 2));
                    elseif  gui.data.r.plotMode == 1 && ~any(gui.data.r.l.layer{ii} == [1 2 3])
                        scan = gui.data.r.l.scans{ii};
                        gui.data.r.a.a{ii}.goto(scan(gui.data.d.l.layer{ii} - 3));
                    end
                end
            end
        end
        function minmax_Callback(gui, ~, ~, isMax)                          % Menu option to set the minimum or maximum to value of the selected pixel.
            gui.scale.gray.gui.normAuto.Value = 0;
            if isMax
                gui.scale.gray.gui.maxEdit.String = gui.selData(1);
                gui.scale.gray.edit_Callback(gui.scale.gray.gui.maxEdit, 0);
            else
                gui.scale.gray.gui.minEdit.String = gui.selData(1);
                gui.scale.gray.edit_Callback(gui.scale.gray.gui.minEdit, 0);
            end
        end
        function normalizeThis_Callback(gui, ~, ~)	% Add GB!
            gui.scale.gray.gui.normAuto.Value = 0;

            gui.scale.gray.gui.maxEdit.String = gui.r.max();
            gui.scale.gray.edit_Callback(gui.scale.gray.gui.maxEdit, 0);

            gui.scale.gray.gui.minEdit.String = gui.r.min();
            gui.scale.gray.edit_Callback(gui.scale.gray.gui.minEdit, 0);
        end
        function openCounter_Callback(gui, ~, ~)
            pixels = max(round(20/gui.data.d.intTimes(gui.r.input)), 10);   % Aim for 20 sec of data. At least 10 pixels
            data2 = mcData(mcData.counterConfig(gui.data.d.inputs{gui.r.input}, pixels, gui.data.d.intTimes(gui.r.input)));
            mcDataViewer(data2, false)    % And don't show the control window when opening...
        end
        function openCounterAtPoint_Callback(gui, ~, ~, isSel, shouldGotoLayer)
            gui.gotoPostion_Callback(0, 0, isSel, shouldGotoLayer);
            gui.openCounter_Callback(0, 0);
        end
        
        function makeProperVisibility(gui)
            switch gui.data.r.plotMode
                case 0
                    pvis = 'off';
                    ivis = 'off';
                    hvis = 'on';
                case 1
                    pvis = 'on';
                    ivis = 'off';
                    hvis = 'off';
                case 2
                    pvis = 'off';
                    ivis = 'on';
                    hvis = 'off';
            end
            
            gui.p(1).Visible =       pvis;
            gui.posL.sel.Visible =   pvis;
            gui.posL.pix.Visible =   pvis;
            gui.posL.act.Visible =   pvis;
            gui.posL.prv.Visible =   pvis;
            
            if gui.isRGB
                gui.p(2).Visible =   pvis;
                gui.p(3).Visible =   pvis;
                
                gui.h(2).Visible =   hvis;
                gui.h(3).Visible =   hvis;
            else
                gui.p(2).Visible =  'off';
                gui.p(3).Visible =  'off';
                
                gui.h(2).Visible =  'off';
                gui.h(3).Visible =  'off';
            end
            
            gui.i.Visible =         ivis;
            gui.pos.sel.Visible =   ivis;
            gui.pos.pix.Visible =   ivis;
            gui.pos.act.Visible =   ivis;
            gui.pos.prv.Visible =   ivis;
            
            gui.cbar.Visible =      ivis;
            
            gui.h(1).Visible =      hvis;
        end
        
        function turnMarkersOff(gui)
            gui.posL.sel.Visible =   'off';
            gui.posL.pix.Visible =   'off';
            gui.posL.act.Visible =   'off';
            gui.posL.prv.Visible =   'off';
            
            if gui.isRGB
                gui.p(2).Visible =  'off';
                gui.p(3).Visible =  'off';
                
                gui.h(2).Visible =  'off';
                gui.h(3).Visible =  'off';
            else
                gui.p(2).Visible =  'off';
                gui.p(3).Visible =  'off';
                
                gui.h(2).Visible =  'off';
                gui.h(3).Visible =  'off';
            end
            
            gui.pos.sel.Visible =   'off';
            gui.pos.pix.Visible =   'off';
            gui.pos.act.Visible =   'off';
            gui.pos.prv.Visible =   'off';
        end
        
        function plotSetup(gui)
            gui.a.Title.String = gui.data.d.name;
            
%             layer = gui.data.r.l.layer
            
            switch gui.data.r.plotMode
                case 0  % histogram
                    gui.a.XLabel.String = gui.data.r.i.i{gui.r.input}.nameUnits();
                    gui.a.YLabel.String = 'Number (num/bin)';
                case 1  % 1D
                    gui.p(1).XData = gui.data.r.l.scans{gui.data.r.l.layer == 1};
                    gui.p(2).XData = gui.data.r.l.scans{gui.data.r.l.layer == 1};
                    gui.p(3).XData = gui.data.r.l.scans{gui.data.r.l.layer == 1};
                    gui.a.XLim = [min(gui.p(1).XData) max(gui.p(1).XData)];         % Check to see if range is zero!
                    
                    gui.a.XLabel.String = gui.data.r.l.nameUnit{gui.data.r.l.layer == 1};
%                     gui.a.YLabel.String = gui.data.r.l.nameUnit{gui.data.r.l.layer == 2};
                    
%                     gui.a.XLabel.String = gui.data.r.a.a{gui.data.r.l.layer == 1}.nameUnits();
                    gui.a.YLabel.String = gui.data.r.i.i{gui.r.input}.nameUnits();
                case 2  % 2D
                    gui.i.XData = gui.data.r.l.scans{gui.data.r.l.layer == 1};
                    gui.i.YData = gui.data.r.l.scans{gui.data.r.l.layer == 2};
                    
                    gui.a.XLim = [min(gui.i.XData) max(gui.i.XData)];         % Check to see if range is zero!
                    gui.a.YLim = [min(gui.i.YData) max(gui.i.YData)];         % Check to see if range is zero!
                    
                    gui.a.XLabel.String = gui.data.r.l.nameUnit{gui.data.r.l.layer == 1};
                    gui.a.YLabel.String = gui.data.r.l.nameUnit{gui.data.r.l.layer == 2};
                    
                    gui.cbar.Label.String = gui.data.r.i.i{gui.r.input}.nameUnits();
            end
                        
            if gui.isRGB

            else
                gui.scale.gray.dataChanged_Callback(0,0);
            end
            
            gui.resetAxisListeners();
            gui.shouldPlot = true;
        end
        function plotData_Callback(gui,~,~)
            if isvalid(gui)
                if gui.data.r.scanMode == 2
                    gui.scanButton.String = 'Rescan (Will Overwrite Data)';
                end

                if gui.shouldPlot
                    dims = sum(size(gui.r.data) > 1);

                    if gui.data.r.plotMode == 0
                        if gui.isRGB

                        else
                            gui.a.DataAspectRatioMode = 'auto';
                            gui.a.YLimMode = 'auto';

                            gui.h(1).Data = gui.data.d.data{gui.r.input};
                            gui.h(1).NumBins = ceil(length(gui.h(1).Data)/3);

                            gui.scale.gray.dataChanged_Callback(0,0);
                        end
                    elseif gui.data.r.plotMode == 1 && dims == 1
                        if gui.isRGB

                        else
                            gui.a.DataAspectRatioMode = 'auto';
                            gui.a.YLimMode = 'manual';

                            gui.p(1).YData = gui.r.data;

                            gui.scale.gray.dataChanged_Callback(0,0);
                        end
                    elseif gui.data.r.plotMode == 2 && dims == 2
                        if gui.isRGB

                        else
                            if strcmpi(gui.data.r.l.unit{gui.data.r.l.layer == 1}, gui.data.r.l.unit{gui.data.r.l.layer == 2})
                                gui.a.DataAspectRatioMode = 'manual';
                                gui.a.DataAspectRatio = [1 1 1];
                            else
                                gui.a.DataAspectRatioMode = 'auto';
                            end

                            gui.a.YLimMode = 'manual';

                            gui.i.CData =       gui.r.data;
                            gui.i.AlphaData =   ~isnan(gui.r.data);

                            gui.scale.gray.dataChanged_Callback(0,0);
                        end
                    end
                end
            end
        end

        function figureClickCallback(gui, ~, event)
%             event.Button
            if event.Button == 3
                x = event.IntersectionPoint(1);
                y = event.IntersectionPoint(2);
                
                switch gui.data.r.plotMode
                    case 0  % histogram
                        % Do nothing.
                    case 1  % 1D
                        xlist = (gui.p(1).XData - x) .* (gui.p(1).XData - x);
                        xi = find(xlist == min(xlist), 1);
                        xp = gui.p(1).XData(xi);
                        
                        unitsX = gui.data.r.l.unit{gui.data.r.l.layer == 1};
                        
                        gui.posL.sel.XData = [x x];
                        gui.posL.pix.XData = [xp xp];

                        valr = gui.p(1).YData(xi);
                        
                        gui.selData(1) = valr;

                        if isnan(valr)
                            gui.menus.ctsMenu.Label = 'Value: ----- cts/sec';
                        else
                            gui.menus.ctsMenu.Label = ['Value: ' num2str(valr, 4) ' ' gui.data.r.i.i{gui.paramsGray.choose.Value}.config.kind.extUnits];
                        end
                        
                        gui.menus.posMenu.Label = ['Position: ' num2str(x, 4)  ' ' unitsX];
                        gui.menus.pixMenu.Label = ['Pixel: '    num2str(xp, 4) ' ' unitsX];
                    case 2  % 2D
                        xlist = (gui.i.XData - x) .* (gui.i.XData - x);
                        ylist = (gui.i.YData - y) .* (gui.i.YData - y);
                        xi = find(xlist == min(xlist), 1);
                        yi = find(ylist == min(ylist), 1);
                        xp = gui.i.XData(xi);
                        yp = gui.i.YData(yi);
                        
                        gui.pos.sel.XData = x;
                        gui.pos.sel.YData = y;
                        gui.pos.pix.XData = xp;
                        gui.pos.pix.YData = yp;
                        
                        unitsX = gui.data.r.l.unit{gui.data.r.l.layer == 1};
                        unitsY = gui.data.r.l.unit{gui.data.r.l.layer == 2};

                        val = gui.i.CData(yi, xi);
                        
                        gui.selData(1) = val;

                        if isnan(val)
                            gui.menus.ctsMenu.Label = 'Value: ----- cts/sec';
                        else
                            gui.menus.ctsMenu.Label = ['Value: ' num2str(val, 4) ' ' gui.data.r.i.i{gui.paramsGray.choose.Value}.config.kind.extUnits];
                        end
                        
                        gui.menus.posMenu.Label = ['Position: [ ' num2str(x, 4)  ' ' unitsX ', ' num2str(y, 4)  ' ' unitsY ' ]'];
                        gui.menus.pixMenu.Label = ['Pixel: [ '    num2str(xp, 4) ' ' unitsX ', ' num2str(yp, 4) ' ' unitsY ' ]'];
                end
            end
        end
        
        % Functions to update the current position of the axes
        function resetAxisListeners(gui)
            delete(gui.listeners.x);
            delete(gui.listeners.y);
            
            prop = findprop(mcAxis, 'x');
            
            switch gui.data.r.plotMode
                case 1
                    if gui.data.r.l.type(gui.data.r.l.layer == 1) == 0
                        gui.listeners.x = event.proplistener(gui.data.r.a.a{gui.data.r.l.layer == 1}, prop, 'PostSet', @gui.listenToAxes_Callback);
                    else
                        gui.pos.prv.XData = [NaN NaN];
                        gui.pos.act.XData = [NaN NaN];
                    end
                case 2
%                     ax = gui.data.r.a.a{gui.data.r.l.layer == 1}.name()
%                     ay = gui.data.r.a.a{gui.data.r.l.layer == 2}.name()
                    if gui.data.r.l.type(gui.data.r.l.layer == 1) == 0
                        gui.listeners.x = event.proplistener(gui.data.r.a.a{gui.data.r.l.layer == 1}, prop, 'PostSet', @gui.listenToAxes_Callback);
                    else
                        gui.pos.prv.XData = NaN;
                        gui.pos.act.XData = NaN;
                    end
                    if gui.data.r.l.type(gui.data.r.l.layer == 2) == 0
                        gui.listeners.y = event.proplistener(gui.data.r.a.a{gui.data.r.l.layer == 2}, prop, 'PostSet', @gui.listenToAxes_Callback);
                    else
                        gui.pos.act.YData = NaN;
                        gui.pos.prv.YData = NaN;
                    end
            end
            
            gui.listenToAxes_Callback(0,0);
        end
        function listenToAxes_Callback(gui, ~, ~)
%             isvalid(gui)
%             isobject(gui)
%             isempty(gui)
%             gui.data.r.plotMode ~= 0
%             all( gui.data.r.l.type(gui.data.r.l.layer == 1 | gui.data.r.l.layer == 2) == 0 )
%             gui;
            if isvalid(gui)
                d = gui.data;   % Really odd bug makes gui.data.r... take more time to access.
    %             gui.data.r;
    %             gui.data.r.l;
    %             R = gui.data.r;
                R = d.r;

                if R.plotMode ~= 0 && all( R.l.type(R.l.layer == 1 | R.l.layer == 2) == 0 )
                    axisX = R.a.a{R.l.layer == 1};

                    x = axisX.getX();
                    gui.posL.act.XData = [x x];
                    gui.pos.act.XData = x;

                    x = gui.data.r.a.prev(gui.data.r.l.layer == 1);
                    gui.posL.prv.XData = [x x];
                    gui.pos.prv.XData = x;

                    if gui.data.r.plotMode == 2
                        axisY = gui.data.r.a.a{gui.data.r.l.layer == 2};

                        gui.pos.act.YData = axisY.getX();
                        gui.pos.prv.YData = gui.data.r.a.prev(gui.data.r.l.layer == 2);
                    end
                end
            end
        end
        
        function updateLayer_Callback(gui, src, ~)
            layerPrev = gui.data.r.l.layer;
            inputPrev = gui.r.input;
            input =     gui.r.input;
            
            relevant =  gui.data.r.l.type == 0 | gui.data.r.l.type == gui.r.input;  % RGB case?
            
%             other = cellfun(@(x)(x.Value), gui.params1D.chooseList(~relevant));
            
            switch gui.data.r.plotMode   % Make this reference a list instead of a switch
                case 1
                    layer = cellfun(@(x)(x.Value), gui.params1D.chooseList);
                    
                    if sum(layer == 1) == 0     % If X->num, switch back to X (we need at least one X).
                        changed = cellfun(@(x)(x == src), gui.params1D.chooseList);
                        
                        layer(changed) = 1;
                    end
                    
                    if sum(layer == 1) > 1      % If num->X, swich the previous X to mean (if the new X is an incompatible layer, switch the input).
                        changed = cellfun(@(x)(x == src), gui.params1D.chooseList);
                        
                        if any(changed & ~relevant)
                            input = max(gui.data.r.l.type(changed & ~relevant));    % max prevents crash in case of fringe errors.
                        end
                        
                        layer(layer == 1 & ~changed) = 2;
                    end
                    
%                     if gui.isRGB
%                         % Complain about other input axis
%                     end
                    
                    for ii = 1:length(layer)
                        gui.params1D.chooseList{ii}.Value = layer(ii);
                    end
                case 2
                    layer = cellfun(@(x)(x.Value), gui.params2D.chooseList);
%                     disp(layer);
                    changed = cellfun(@(x)(x == src), gui.params2D.chooseList);
                    
                    if sum(layer == 1) == 0 && sum(layer == 2) == 2 && layer(changed) == 2      % If X->Y, switch Y->X.
                        layer(layer == 2 & ~changed) = 1;
                    end
                    if sum(layer == 1) == 2 && sum(layer == 2) == 0 && layer(changed) == 1      % If Y->X, switch X->Y.
                        layer(layer == 1 & ~changed) = 2;
                    end
                    
                    if sum(layer == 1) == 0     % If X->num, switch back to X.
                        layer(changed) = 1;
                    end
                    if sum(layer == 2) == 0     % If Y->num, switch back to Y.
                        layer(changed) = 2;
                    end
                    if sum(layer == 1) > 1      % If num->X, switch old X to mean
                        layer(layer == 1 & ~changed) = 3;
                    end
                    if sum(layer == 2) > 1      % If num->Y, switch old Y to mean
                        layer(layer == 2 & ~changed) = 3;
                    end
                    
%                     if sum(changed == 1) && gui.data.r.l.type(changed) > 0 && gui.data.r.l.layer(changed) < 3    % If an input axis was changed to X or Y,
%                         otherAxis = ~changed & layer < 3;
%                         
%                         if gui.data.r.l.type(otherAxis) > 0                                 % If the other axis (Y or X) is an input axis...
%                             if gui.data.r.l.type(changed) ~= gui.data.r.l.type(otherAxis)   % ...from a different input...
%                                 % Next check if the changed input axis is compatible with 2D
%                                 if gui.data.r.l.type(1) == 0        % If there is an mcAxis availible...
%                                     layer(1) = layer(otherAxis);    % ...then, set that axis to X or Y (whatever the incompatible input axis is)...
%                                     layer(otherAxis) = 3;           % ...and set the incompatible input axis to mean.
%                                 elseif sum(gui.data.r.l.type == gui.data.r.l.type(changed)) > 1     % Otherwise, if this is greater than a 1D input,
%                                     layer(find(gui.data.r.l.type == gui.data.r.l.type(changed) & ~changed, 1)) = layer(otherAxis);  % Do the same as above, except with the lowest compatible input axis.
%                                     layer(otherAxis) = 3;
%                                 else
%                                     error('2D incompatible with this input. Fix not implemented.');
%                                 end
%                             end
%                         end
%                     end
                        
                    if any(layer(~relevant) < 3)        % If any non-relevant axes are X or Y,
                        if sum(relevant) >= 2           % And if there are enough axes to replace the non-relavant X and/or Y,
                            if any(layer(~relevant) == 1)   % If the X axis is not relevant,
                                x = find(relevant & layer ~= 2, 1, 'first');   % Find the first relevant and non-y axis. Unless there was a horrible bug, we can find a non-empty x.

                                layer(layer == 1) = 3;      % Set X to mean
                                layer(x) = 1;
                            end

                            if any(layer(~relevant) == 2)   % If the Y axis is not relevant,
                                y = find(relevant & layer ~= 1, 1, 'first');   % Find the first relevant and non-y axis. Unless there was a horrible bug, we can find a non-empty y.

                                layer(layer == 2) = 3;      % Set X to mean
                                layer(y) = 2;
                            end

                            for ii = 1:length(layer)
                                gui.params2D.chooseList{ii}.Value = layer(ii);
                            end
                        else
                            warning('2D incompatible with this input.');
                            input = max(gui.data.r.l.type(layer == 1 || layer == 2));
                        end
                    end
                    
                    for ii = 1:length(layer)
%                         if layer(ii) ~= layerPrev(ii) || changed(ii)
                        gui.params2D.chooseList{ii}.Value = layer(ii);
%                         end
                    end
                otherwise
                    layer = layerPrev;
            end
            
            gui.r.input = input;
            
            if input ~= inputPrev
                gui.paramsGray.choose.Value = input;
            end
            
            gui.data.r.l.layer = layer;
            
            if any(layer ~= layerPrev) || gui.data.r.plotMode == 0
                gui.shouldPlot = false;
                gui.plotSetup();
            end
        end
        
        function updateInput_Callback(gui, src, ~)
            if gui.isRGB
                error('RGB NotImplemented');
            else
                layerPrev = gui.data.r.l.layer;
                inputPrev = gui.r.input;
            
                input =     src.Value;
                
                relevant =  gui.data.r.l.type == 0 | gui.data.r.l.type == input;
            
                % Make sure the this choice of input is compatible with the current layer...
                switch gui.data.r.plotMode
                    case 1
                        layer = cellfun(@(x)(x.Value), gui.params1D.chooseList);
                        
                        if any(layer == 1 & ~relevant)  % If the axis that is the x axis is not relevant (i.e. is not an input axis of the selected input or an mcAxis axis),
                            x = find(gui.data.r.l.type == input, 1, 'first');
                            
                            if isempty(x)
                                x = find(gui.data.r.l.type == 0, 1, 'first');
                            end
                            
                                
                            if isempty(x)
                                warning('2D incompatible with this input.');
                                src.Value = inputPrev;
                                input =     inputPrev;
                            end
                            
                            layer(layer == 1) = 2;  % Set the old X axis to mean;
                            layer(x) = 1;           % Set the found input axis to X;
                            
                            for ii = 1:length(layer)
                                gui.params1D.chooseList{ii}.Value = layer(ii);
                            end
                        end
                    case 2
%                         layerPrev
                        layer = cellfun(@(x)(x.Value), gui.params2D.chooseList);
%                         type = gui.data.r.l.type
%                         input
%                         relevant
                        
                        if any(layer(~relevant) < 3)        % If any non-relevant axes are X or Y,
                            if sum(relevant) >= 2           % And if there are enough axes to replace the non-relavant X and/or Y,
                                if any(layer(~relevant) == 1)   % If the X axis is not relevant,
                                    x = find(relevant & layer ~= 2, 1, 'first');   % Find the first relevant and non-y axis. Unless there was a horrible bug, we can find a non-empty x.
                                    
                                    layer(layer == 1) = 3;      % Set X to mean
                                    layer(x) = 1;
                                end
                                
                                if any(layer(~relevant) == 2)   % If the Y axis is not relevant,
                                    y = find(relevant & layer ~= 1, 1, 'first');   % Find the first relevant and non-y axis. Unless there was a horrible bug, we can find a non-empty y.
                                    
                                    layer(layer == 2) = 3;      % Set X to mean
                                    layer(y) = 2;
                                end
                            
                                for ii = 1:length(layer)
                                    gui.params2D.chooseList{ii}.Value = layer(ii);
                                end
                            else
                                warning('2D incompatible with this input.');
                                src.Value = inputPrev;
                                input =     inputPrev;
                            end
                        end
                    otherwise
                        layer = layerPrev;
                end       
                
                gui.r.input = input;
                gui.data.r.l.layer = layer;
            
                if any(layer ~= layerPrev) || input ~= inputPrev
                    gui.shouldPlot = false;
                    gui.plotSetup();
                end
            end
        end
        
        function upperTabSwitch_Callback(gui, src, event)
            gui.shouldPlot = false;
            
            switch event.NewValue
                case gui.tabs.t1d
                    gui.data.r.plotMode = 1;
                case gui.tabs.t2d
                    if gui.data.r.l.num < 2
                        src.SelectedTab = event.OldValue;
                    else
                        gui.data.r.plotMode = 2;
                    end
                case gui.tabs.t3d
                    if true
                        src.SelectedTab = event.OldValue;
                    else
%                         gui.data.r.plotMode = 3;
                    end
                case gui.tabs.t0
                    gui.shouldPlot = true;
                    gui.data.r.plotMode = 0;
                    gui.plotData_Callback(0,0);
            end
            
%             if gui.data.r.plotMode > 0
%                 gui.menus.menu.Enable = 'on';
%             else
%                 gui.menus.menu.Enable = 'off';
%             end
            
            gui.shouldPlot = true;
            gui.updateLayer_Callback(0, 0);
            gui.makeProperVisibility();
            gui.plotSetup();
            gui.listenToAxes_Callback(0, 0);
        end
        function lowerTabSwitch_Callback(gui, src, event)
            switch event.NewValue
                case gui.tabs.gray
                    gui.isRGB = 0;
                case gui.tabs.rgb
                    src.SelectedTab = event.OldValue;
            end
        end
    end
end

% function drawSquarePatch(p, x1, y1, x2, y2)
%     p.XData = [x1 x1 x2 x2];
%     p.YData = [y1 y2 y2 y1];
% end

function copyLabelToClipboard(src, ~)
    split = strsplit(src.Label, ': ');
    clipboard('copy', split{end});
end





