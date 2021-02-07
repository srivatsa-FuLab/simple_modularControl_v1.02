classdef mcScan < mcSavableClass
% mcScan
    
    properties
        f = [];
        
        pw = 420;
        ph = 40;
        
        tab1 = [];
        tab2 = [];
        tab3 = [];
        
        p1 = [];
        p2 = [];
        
        scanAxes = {};
        scanInputs = {};
        
        addAxisButton = [];
        addInputButton = [];
    end
    
    methods
        function gui = mcScan(varin)
            
%             gui.f = figure('MenuBar', 'none', 'ToolBar', 'none', 'NumberTitle', 'off', 'Name', 'mcScanGUI (Generic)', 'Resize', 'off', 'Position', [100, 100, gui.pw + 24, 15*gui.ph]);%, 'SizeChangedFcn', @gui.sizeChangedFcn);
            gui.f = mcInstrumentHandler.createFigure(gui, 'saveopen');
            gui.f.Resize =      'off';
%             f.Visible =     'off';
%             f.MenuBar =     'none';
%             f.ToolBar =     'none';
            gui.f.Position = [100, 100, gui.pw + 24, 15*gui.ph];
            
%             f=gui.f;
%             u1 = uicontrol('Style','push', 'parent', f,'pos',...
%               [20 100 100 100],'string','button1');
%             u2 = uicontrol('Style','push', 'parent', f,'pos',...
%               [150 250 100 100],'string','button2');
%             u3 = uicontrol('Style','push', 'parent', f,'pos',...
%               [250 100 100 100],'string','button3');
%             hlist2 = [u1 u2 u3];   
%             align(hlist2,'distribute','bottom');
            scan = uicontrol(gui.f,...
                              'String', 'Scan!',...
                              'Style', 'push',... 
                              'Units', 'normalized',...
                              'Position', [.015 .005 .97 .09],...
                              'Callback', @gui.scan);
            
            tabgp = uitabgroup(gui.f, 'Position', [0 .1 1 .9]);
            gui.tab1 = uitab(tabgp, 'Title', 'Axes', 'Units', 'pixels');
            gui.tab2 = uitab(tabgp, 'Title', 'Inputs', 'Units', 'pixels');
%             gui.tab3 = uitab(tabgp, 'Title', 'Save/Load', 'Units', 'pixels');
            
%             gui.p1 = uipanel(gui.f, 'Units', 'pixels', 'Position', [0,100,gui.pw,gui.ph]); %, 'Position', [.5,1,0,0]);
%             gui.p2 = uipanel(gui.f, 'Position', [.5,1,0,0]);

            tabpos = gui.tab1.Position;
%             pause(.1);
            
%             gui.scanAxes{1} =   uipanel(gui.tab1, 'Units', 'pixels', 'Position', [tabpos(3)/2-gui.pw/2, tabpos(4)-1*gui.ph, gui.pw, gui.ph]);
%             gui.scanInputs{1} = uipanel(gui.tab2, 'Units', 'pixels', 'Position', [tabpos(3)/2-gui.pw/2, tabpos(4)-1*gui.ph, gui.pw, gui.ph]);
            
%             gui.scanAxes

%             uicontrol(  gui.scanAxes{1}, ...  
%                         'Style', 'push',...
%                         'String', 'Add Axis',...
%                         'Units', 'pixels',...
%                         'Position', [5,5,gui.pw-10,gui.ph-10],...
%                         'Callback', @gui.makeAxis);
%             uicontrol(  gui.scanInputs{1}, ...  
%                         'Style', 'push',...
%                         'String', 'Add Input',...
%                         'Units', 'pixels',...
%                         'Position', [5,5,gui.pw-10,gui.ph-10],...
%                         'Callback', @gui.makeInput);

            gui.addAxisButton = uicontrol(  gui.tab1, ...  
                        'Style', 'push',...
                        'String', 'Add Axis',...
                        'Units', 'pixels',...
                        'Position', [tabpos(3)/2-gui.pw/2 + 5, tabpos(4)-2*gui.ph + 15, gui.pw-10, gui.ph-10],...
                        'Callback', @gui.makeAxis_Callback);
            gui.addInputButton = uicontrol(  gui.tab2, ...  
                        'Style', 'push',...
                        'String', 'Add Input',...
                        'Units', 'pixels',...
                        'Position', [tabpos(3)/2-gui.pw/2 + 5, tabpos(4)-2*gui.ph + 15, gui.pw-10, gui.ph-10],...
                        'Callback', @gui.makeInput_Callback);

%             saveButton = uicontrol(  gui.tab3, ...  
%                         'Style', 'push',...
%                         'String', 'Save Configuration',...
%                         'Units', 'pixels',...
%                         'Position', [tabpos(3)/2-gui.pw/2 + 5, tabpos(4)-2*gui.ph + 5, gui.pw/2-10, gui.ph-10],...
%                         'Callback', @rand,...
%                         'Enable', 'off');
%             loadButton = uicontrol(  gui.tab3, ...  
%                         'Style', 'push',...
%                         'String', 'Load Configuration',...
%                         'Units', 'pixels',...
%                         'Position', [tabpos(3)/2 + 15, tabpos(4)-2*gui.ph + 5, gui.pw/2-10, gui.ph-10],...
%                         'Callback', @rand,...
%                         'Enable', 'off');
                    
%             tabpos = gui.tab1.Position;
%             gui.addAxisButton.Position = [tabpos(3)/2-gui.pw/2 + 5, tabpos(4)-1*gui.ph + 5, gui.pw-10, gui.ph-10];
%             
%             tabpos = gui.tab2.Position;
%             gui.addInputButton.Position = [tabpos(3)/2-gui.pw/2 + 5, tabpos(4)-1*gui.ph + 5, gui.pw-10, gui.ph-10];
                    
%             tabpos = gui.tab3.Position;
%             saveButton.Position = [tabpos(3)/2-gui.pw/2 + 5, tabpos(4)-1*gui.ph + 5, gui.pw/2-10, gui.ph-10];
%             loadButton.Position = [tabpos(3)/2 + 5, tabpos(4)-1*gui.ph + 5, gui.pw/2-10, gui.ph-10];
            
%                     pause(10);

%             gui.makeAxis(0);
%             gui.makeInput(0);
                    
            gui.alignPanels();
            
            pause(.1);
            
            gui.f.Visible = 'on';
        end
        
%         function sizeChangedFcn(gui,~,~)
%             gui.alignPanels()
%         end
        function makeAxis_Callback(gui,~,~)
            gui.makeAxis(0);
        end
        function makeInput_Callback(gui,~,~)
            gui.makeInput(0);
        end
        
        function makeAxis(gui, index)
            [axes_, axesNames, ~] = mcInstrumentHandler.getAxes();
            
            choices = [{'Choose'} axesNames];
            
            if index == 0
                index =                                 length(gui.scanAxes) + 1;
%                 gui.scanAxes{index}.instrument =        0;
                gui.scanAxes{index}.instrumentName =    'Choose';
                gui.scanAxes{index}.instrumentIndex =   1;
                gui.scanAxes{index}.range =             [NaN NaN 50];
                
                if index > 1
                    if gui.scanAxes{index-1}.choose.Value == 2
                        gui.scanAxes{index-1}.instrumentIndex = 1;
                        gui.scanAxes{index-1}.choose.Value =    1;
                        gui.scanAxes{index-1}.range =           [NaN NaN 50];
                        
                        gui.scanAxes{index}.instrumentIndex = 2;
                        gui.scanAxes{index}.range =             [0 10 50];
                    end
                end
            else
                ii = 1;
                gui.scanAxes{index}.choose.Value = 1;
                
                for axis_ = axes_
%                     if exists(gui.scanAxes{index}.instrument)
%                         if axis_{1} == gui.scanAxes{index}.instrument
%                             gui.scanAxes{index}.instrumentName =  axesNames{ii+1};
%                             gui.scanAxes{index}.instrumentIndex = ii+1;       % Improve this?
%                         end
%                     else
                        if strcmpi(axesNames{1}, gui.scanAxes{index}.instrumentName)
                            gui.scanAxes{index}.choose.Value = ii+1;       % Improve this?
                        end
%                     end
                    ii = ii + 1;
                end
                
                if gui.scanAxes{index}.choose.Value == 1
                    gui.scanAxes{index}.range =             [NaN NaN 50];
                end
            end

            gui.scanAxes{index}.panel = uipanel(gui.tab1, 'Units', 'pixels', 'Position', [0,0,gui.pw,gui.ph]);
            
            curX = 5;
            
            lh = 3;
            uh = -1 + gui.ph/2;
            
%             uicontrol(  gui.scanAxes{l+1},...
%                         'Style', 'text',...
%                         'String', 'Axis: ',...
%                         'HorizontalAlignment', 'left',...
%                         'Position', [12,uh,100,gui.ph/2 - 4]);
                    
            uicontrol(  gui.scanAxes{index}.panel,...
                        'Style', 'text',...
                        'String', 'from ',...
                        'HorizontalAlignment', 'right',...
                        'Position', [200,uh,35,gui.ph/2 - 4]);
            uicontrol(  gui.scanAxes{index}.panel,...
                        'Style', 'text',...
                        'String', 'to ',...
                        'HorizontalAlignment', 'right',...
                        'Position', [200,lh,35,gui.ph/2 - 4]);
                    
            gui.scanAxes{index}.choose = ...
            uicontrol(  gui.scanAxes{index}.panel,...
                        'Style', 'popupmenu',...
                        'String', choices,... %{'Choose', 'Axis1', 'Axis2', 'Axis3'}
                        'Value', gui.scanAxes{index}.instrumentIndex,...
                        'Position', [2,(lh + uh)/2,200,gui.ph/2-1],...
                        'Callback', @gui.chooseInstrument_Callback);
                    
            gui.scanAxes{index}.editUp = ...
            uicontrol(  gui.scanAxes{index}.panel,...
                        'Style', 'edit',...
                        'String', gui.scanAxes{index}.range(1),...
                        'Position', [235,uh,50,gui.ph/2 - 4],...
                        'Callback', @gui.obeyRange_Callback);
            gui.scanAxes{index}.unitUp = ...
            uicontrol(  gui.scanAxes{index}.panel,...
                        'Style', 'text',...
                        'String', ' (?)',...
                        'HorizontalAlignment', 'left',...
                        'Position', [285,uh,50,gui.ph/2 - 4]);
            gui.scanAxes{index}.editDown = ...
            uicontrol(  gui.scanAxes{index}.panel,...
                        'Style', 'edit',...
                        'String', gui.scanAxes{index}.range(2),...
                        'Position', [235,lh,50,gui.ph/2 - 4],...
                        'Callback', @gui.obeyRange_Callback);
            gui.scanAxes{index}.unitDown = ...
            uicontrol(  gui.scanAxes{index}.panel,...
                        'Style', 'text',...
                        'String', ' (?)',...
                        'HorizontalAlignment', 'left',...
                        'Position', [285,lh,50,gui.ph/2 - 4]);
            uicontrol(  gui.scanAxes{index}.panel,...
                        'Style', 'text',...
                        'String', 'steps ',...
                        'HorizontalAlignment', 'right',...
                        'Position', [315,lh,35,gui.ph/2 - 4]);
            gui.scanAxes{index}.editStep = ...
            uicontrol(  gui.scanAxes{index}.panel,...
                        'Style', 'edit',...
                        'String', gui.scanAxes{index}.range(3),...
                        'Value', gui.scanAxes{index}.range(3),...
                        'Position', [350,lh,50,gui.ph/2 - 4],...
                        'Callback', @gui.obeyRange_Callback);
%                         'Position', [2,lh,100,gui.ph/2 - 4]);

            uicontrol(  gui.scanAxes{index}.panel,...
                        'Style', 'push',...
                        'String', 'X',...
                        'Position', [398,uh,gui.ph/2 - 4,gui.ph/2 - 4],...
                        'Callback', @gui.removePanel_Callback);
            
            gui.alignPanels();
        end
        function makeInput(gui, index)
            [inputs, inputNames] = mcInstrumentHandler.getInputs();
            
            choices = [{'Choose'} inputNames];
            
            if index == 0
                index =                                 length(gui.scanInputs) + 1;
                gui.scanInputs{index}.instrument =        0;
                gui.scanInputs{index}.instrumentName =    'Choose';
                gui.scanInputs{index}.instrumentIndex =   1;
                gui.scanInputs{index}.integrationTime =   1;
            else
                ii = 1;
                gui.scanInputs{index}.instrumentIndex = 1;
                
                for input = inputs
                    if exists(gui.scanAxes{index}.instrument)
                        if input{1} == gui.scanInputs{index}.instrument
                            gui.scanInputs{index}.instrumentName =  inputNames{ii+1};
                            gui.scanInputs{index}.instrumentIndex = ii+1;       % Improve this?
                        end
                    else
                        if strcmpi(inputNames{1}, gui.scanInputs{index}.instrumentName)
                            gui.scanInputs{index}.instrument =  inputs{ii+1};
                            gui.scanInputs{index}.instrumentIndex = ii+1;       % Improve this?
                        end
                    end
                    ii = ii + 1;
                end
                
                if gui.scanInputs{index}.instrumentIndex == 1
                    gui.scanInputs{index}.integrationTime =     1;
                end
            end

            gui.scanInputs{index}.panel = uipanel(gui.tab2, 'Units', 'pixels', 'Position', [0,0,gui.pw,gui.ph]);
            
            lh = 3;
            uh = -1 + gui.ph/2;
            
%             uicontrol(  gui.scanAxes{l+1},...
%                         'Style', 'text',...
%                         'String', 'Axis: ',...
%                         'HorizontalAlignment', 'left',...
%                         'Position', [12,uh,100,gui.ph/2 - 4]);
            [~, inputNames] = mcInstrumentHandler.getInputs();
            gui.scanInputs{index}.choose = ...
            uicontrol(  gui.scanInputs{index}.panel,...
                        'Style', 'popupmenu',...
                        'String', [{'Choose'} inputNames],...
                        'Value', gui.scanInputs{index}.instrumentIndex,...
                        'Position', [2,(lh + uh)/2,200,gui.ph/2 - 1],...
                        'Callback', @gui.chooseInstrument_Callback);
%                         'Position', [2,lh,100,gui.ph/2 - 4]);
                    
            uicontrol(  gui.scanInputs{index}.panel,...
                        'Style', 'text',...
                        'String', 'Integration ',...
                        'HorizontalAlignment', 'right',...
                        'Position', [205,uh,60,gui.ph/2 - 4]);
            gui.scanInputs{index}.integrationTime = ...
            uicontrol(  gui.scanInputs{index}.panel,...
                        'Style', 'edit',...
                        'String', gui.scanInputs{index}.integrationTime,...
                        'Position', [265,uh,50,gui.ph/2 - 4],...
                        'Callback', @gui.setIntegration);
            uicontrol(  gui.scanInputs{index}.panel,...
                        'Style', 'text',...
                        'String', ' (s)',...
                        'HorizontalAlignment', 'left',...
                        'Position', [315,uh,30,gui.ph/2 - 4]);

            uicontrol(  gui.scanInputs{index}.panel,...
                        'Style', 'push',...
                        'String', 'X',...
                        'Position', [398,uh,gui.ph/2 - 4,gui.ph/2 - 4],...
                        'Callback', @gui.removePanel_Callback);
            
            gui.alignPanels();
        end
        function removePanel(gui, panel)
            saI = cellfun(@(x)(x.panel == panel), gui.scanAxes);
            if sum(saI) > 0
                gui.scanAxes = gui.scanAxes(~saI);
            end
            
            siI = cellfun(@(x)(x.panel == panel), gui.scanInputs);
            if sum(siI) > 0
                gui.scanInputs = gui.scanInputs(~siI);
            end
            
            delete(panel);
            
            gui.alignPanels();
        end
        function alignPanels(gui)
            tabpos = gui.tab1.Position;
                
%             if ~isempty(gui.scanAxes)
                for ii = 1:length(gui.scanAxes)
                    gui.scanAxes{ii}.panel.Position = [tabpos(3)/2-gui.pw/2, tabpos(4)-(ii+1)*gui.ph, gui.pw, gui.ph];
                end
%             end
%                 
%             if ~isempty(gui.scanInputs)
                for ii = 1:length(gui.scanInputs)
                    gui.scanInputs{ii}.panel.Position = [tabpos(3)/2-gui.pw/2, tabpos(4)-(ii+1)*gui.ph, gui.pw, gui.ph];
                end
%             end
        end
        
        function removePanel_Callback(gui, src, ~)
            gui.removePanel(src.Parent);
        end
        
        function updateInstruments(gui)
            if isvalid(gui)
                [~, axesNames, ~] = mcInstrumentHandler.getAxes();
                choicesA = [{'Choose'} axesNames];
                
                for ii = 1:length(gui.scanAxes)
                    gui.scanAxes{ii}.choose.String = choicesA;
                    gui.scanAxes{ii}.choose.Value = 1;
                    
                    for jj = 2:length(choicesA)
                        if strcmpi(choicesA{jj}, gui.scanAxes{ii}.instrumentName)
                            gui.scanAxes{ii}.choose.Value = jj;
                        end
                    end
                end
                
                [~, inputNames] = mcInstrumentHandler.getInputs();
                choicesI = [{'Choose'} inputNames];
                
                for ii = 1:length(gui.scanInputs)
                    gui.scanInputs{ii}.choose.String = choicesI;
                    gui.scanInputs{ii}.choose.Value = 1;
                    
                    for jj = 2:length(choicesI)
                        if strcmpi(choicesI{jj}, gui.scanInputs{ii}.instrumentName)
                            gui.scanInputs{ii}.choose.Value = jj;
                        end
                    end
                end
            end
        end
        
        function chooseInstrument_Callback(gui, src, ~)
            panel = src.Parent;
            
            saI = cellfun(@(x)(x.panel == panel), gui.scanAxes);
            saIndex = (1:length(gui.scanAxes))*(saI');
            if sum(saI) == 1
                gui.scanAxes{saIndex}.instrumentName = gui.scanAxes{saIndex}.choose.String{gui.scanAxes{saIndex}.choose.Value};
                
                if gui.scanAxes{saIndex}.choose.Value == 2  % If time was selected...
                    if saIndex ~= length(gui.scanAxes)
                        gui.scanAxes{end}.choose.Value = 2;
                        gui.chooseAxis(length(gui.scanAxes));
                        
                        gui.scanAxes{saIndex}.choose.Value = 1;
                        
                        questdlg('Time can only be the last axis', 'Warning!', 'Okay', 'Okay');
                    end
                else                                        % Otherwise, make sure that no other panel is using this axis...
                    for ii = 1:length(gui.scanAxes)
                        if ii ~= saIndex && gui.scanAxes{saIndex}.choose.Value == gui.scanAxes{ii}.choose.Value
                            gui.scanAxes{ii}.choose.Value = 1;  % If another panel is using this axis, set it to 'Choose' mode.
                            gui.chooseAxis(ii);
                        end
                    end
                end
                
                gui.chooseAxis(saIndex);
            elseif sum(saI) > 1
                error('There seem to be two of the same panel!?');
            end
            
            siI = cellfun(@(x)(x.panel == panel), gui.scanInputs);
            siIndex = (1:length(gui.scanInputs))*(siI');
            if sum(siI) == 1
                gui.scanInputs{siIndex}.instrumentName = gui.scanInputs{siIndex}.choose.String{gui.scanInputs{siIndex}.choose.Value};
                
                for ii = 1:length(gui.scanInputs)               % Then, make sure that no other panel is using this axis...
                    if ii ~= siIndex && gui.scanInputs{siIndex}.choose.Value == gui.scanInputs{ii}.choose.Value
                        gui.scanInputs{ii}.choose.Value = 1;    % If another panel is using this input, set it to 'Choose' mode.
                        gui.chooseInput(ii);
                    end
                end
                
                gui.chooseInput(siIndex);
            elseif sum(siI) > 1
                error('There seem to be two of the same panel!?');
            end
            
            
        end
        
        function chooseAxis(gui, index)
            [axes_, ~, ~] = mcInstrumentHandler.getAxes();
            
            ii = gui.scanAxes{index}.choose.Value-1;
            
            if ii == 0
                gui.scanAxes{index}.range = [NaN NaN 50];
                
                gui.scanAxes{index}.unitUp.String =     ' (?)';
                gui.scanAxes{index}.unitDown.String =   ' (?)';
                
                gui.scanAxes{index}.unitUp.TooltipString =      '';
                gui.scanAxes{index}.unitDown.TooltipString =    '';
            else
%                 gui.scanAxes{index}.range = [gui.scanAxes{index}.editUp.String gui.scanAxes{index}.editDown.String gui.scanAxes{index}.editStep.String];
%                 range = gui.scanAxes{index}.range
%                 parentRange = axes_{ii}.config.kind.extRange
                if gui.scanAxes{index}.range(1) < min(axes_{ii}.config.kind.extRange) || isnan(gui.scanAxes{index}.range(1))
                    gui.scanAxes{index}.range(1) = min(axes_{ii}.config.kind.extRange);
                end
                if gui.scanAxes{index}.range(1) > max(axes_{ii}.config.kind.extRange)
                    gui.scanAxes{index}.range(1) = max(axes_{ii}.config.kind.extRange);
                end
                if gui.scanAxes{index}.range(2) < min(axes_{ii}.config.kind.extRange)
                    gui.scanAxes{index}.range(2) = min(axes_{ii}.config.kind.extRange);
                end
                if gui.scanAxes{index}.range(2) > max(axes_{ii}.config.kind.extRange) || isnan(gui.scanAxes{index}.range(2))
                    gui.scanAxes{index}.range(2) = max(axes_{ii}.config.kind.extRange);
                end
                
                if  ii == 1
                    gui.scanAxes{index}.range(1) = 0;

                    if gui.scanAxes{index}.range(2) <= 0 || isnan(gui.scanAxes{index}.range(2)) || isinf(gui.scanAxes{index}.range(2))
                        gui.scanAxes{index}.range(2) = 10;
                    end
                end
                
%                 finalRange = gui.scanAxes{index}.range
                
                gui.scanAxes{index}.unitUp.String =     [' (' axes_{ii}.config.kind.extUnits ')'];
                gui.scanAxes{index}.unitDown.String =   [' (' axes_{ii}.config.kind.extUnits ')'];
                
                gui.scanAxes{index}.unitUp.TooltipString =      axes_{ii}.nameRange();
                gui.scanAxes{index}.unitDown.TooltipString =    axes_{ii}.nameRange();
            end
                
            gui.scanAxes{index}.editUp.String =     gui.scanAxes{index}.range(1);
            gui.scanAxes{index}.editDown.String =   gui.scanAxes{index}.range(2);
            gui.scanAxes{index}.editStep.String =   gui.scanAxes{index}.range(3);
        end
        function chooseInput(gui, index)
%             [axes_, ~, ~] = mcInstrumentHandler.getAxes();
%             
%             ii = gui.scanAxes{index}.choose.Value;
        end
        function obeyRange_Callback(gui, src, ~)
            panel = src.Parent;
            
            saI = cellfun(@(x)(x.panel == panel), gui.scanAxes);
            index = (1:length(gui.scanAxes))*(saI');
            if sum(saI) > 1
                error('There seem to be two of the same panel!?');
            end
            
            gui.scanAxes{index}.range(1) = str2double(gui.scanAxes{index}.editUp.String);
            gui.scanAxes{index}.range(2) = str2double(gui.scanAxes{index}.editDown.String);
            gui.scanAxes{index}.range(3) = abs(round(str2double(gui.scanAxes{index}.editStep.String)));
            
            [axes_, ~, ~] = mcInstrumentHandler.getAxes();
            
            ii = gui.scanAxes{index}.choose.Value-1;
            if ii == 0
                gui.scanAxes{index}.range(1) = NaN;
                gui.scanAxes{index}.range(2) = NaN;
            elseif ii == 1  % If time is selected,
                gui.scanAxes{index}.range(1) = 0;
                
                if gui.scanAxes{index}.range(2) <= 0 || isnan(gui.scanAxes{index}.range(2))
                    gui.scanAxes{index}.range(2) = 10;
                end
            elseif ~iscell(axes_{ii}.config.kind.extRange)  % Otherwise, if time isn't selected...
                if gui.scanAxes{index}.range(1) < min(axes_{ii}.config.kind.extRange) || isnan(gui.scanAxes{index}.range(1))
                    gui.scanAxes{index}.range(1) = min(axes_{ii}.config.kind.extRange);
                end
                if gui.scanAxes{index}.range(1) > max(axes_{ii}.config.kind.extRange)
                    gui.scanAxes{index}.range(1) = max(axes_{ii}.config.kind.extRange);
                end
                if gui.scanAxes{index}.range(2) < min(axes_{ii}.config.kind.extRange)
                    gui.scanAxes{index}.range(2) = min(axes_{ii}.config.kind.extRange);
                end
                if gui.scanAxes{index}.range(2) > max(axes_{ii}.config.kind.extRange) || isnan(gui.scanAxes{index}.range(2))
                    gui.scanAxes{index}.range(2) = max(axes_{ii}.config.kind.extRange);
                end
                if isnan(gui.scanAxes{index}.range(3)) || gui.scanAxes{index}.range(3) <= 0
                    gui.scanAxes{index}.range(3) = gui.scanAxes{index}.editStep.Value;
                end
            end
            
            gui.scanAxes{index}.editStep.Value = gui.scanAxes{index}.range(3);
            
            gui.scanAxes{index}.editUp.String =     gui.scanAxes{index}.range(1);
            gui.scanAxes{index}.editDown.String =   gui.scanAxes{index}.range(2);
            gui.scanAxes{index}.editStep.String =   gui.scanAxes{index}.range(3);
        end
        function setIntegration(gui, src, ~)
            panel = src.Parent;
            
            saI = cellfun(@(x)(x.panel == panel), gui.scanInputs);
            index = (1:length(gui.scanInputs))*(saI');
            if sum(saI) > 1
                error('There seem to be two of the same panel!?');
            end
            
            val =  str2double(src.String);
            
            if val < 0
                val = -val;
            elseif val == 0 || isnan(val)
                val = 1;
            end
            
            src.String = val;
            gui.scanInputs{index}.integrationTime = val;
        end
    
        function scan(gui, src, ~)
            params = [];
            proceed = true;
            
            [axes_, ~, ~] = mcInstrumentHandler.getAxes();
%             c = cellfun(@(x)(x.choose.Value), gui.scanAxes)
            aIndex =    cellfun(@(x)(x.choose.Value), gui.scanAxes);

            if all(aIndex ~= 1)
                params.axes = axes_(aIndex - 1);
            else
                questdlg('At least one axis has not been chosen...', 'Warning!', 'Okay', 'Okay');
                proceed = false;
            end
            
%             linspace(gui.scanAxes{1}.range(1), gui.scanAxes{1}.range(2), gui.scanAxes{1}.range(3))
            params.scans =      cellfun(@(x)({linspace(x.range(1), x.range(2), x.range(3))}), gui.scanAxes);
            
            [inputs, ~] = mcInstrumentHandler.getInputs();
            iIndex =    cellfun(@(x)(x.choose.Value), gui.scanInputs);

            if all(iIndex ~= 1)
                params.inputs = inputs(iIndex - 1);
            else
                questdlg('At least one input has not been chosen...', 'Warning!', 'Okay', 'Okay');
                proceed = false;
            end
            
            params.intTimes =    cellfun(@(x)(double(x.integrationTime)), gui.scanInputs);
            
%             params
            
            if proceed
                mcData(params)
                mcDataViewer(mcData(params))
            end
        end
    end
end

% function makeInteger_Callback(src, event)
%     src
%     event
%     event.Source
%     
%     src.String = round(str2double(src.String));
%     
%     if isnan(src.String)
%         src.String = src.Value;
%     end
%     
%     src.Value = src.String;
% end




