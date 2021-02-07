classdef mcScalePanel < handle
% mcScalePanel 
    
    properties
        panel = [];     % The actual panel that the scale uicontrols live in (not sure why this isn't in gui).
        
        min = 0;        % The minimum that the user chooses.
        max = 1;        % The maximum that the user chooses.
        
        gui = [];       % All the gui data (e.g. uicontrols) live here in this struct.
        
        data = [];      % Reference to parent mcProcessedData.
    end
    
    methods
        function panel = mcScalePanel(f, pos, data)
            pw = 250;           % Panel Width, the width of the side panel

            bp = 5;             % Button Padding
            bw = pw/2 - 2*bp;   % Button Width, the width of a button/object
            bh = 16;            % Button Height, the height of a button/object

            psh = 3.25*bh;         % Scale figure height

            panel.panel = uipanel('Parent', f, 'Units', 'pixels', 'Position', [pos(1) pos(2) pw+2 psh+2*bh], 'Title', 'Scale');
            panel.data = data;
            
            panel.gui.minText =    uicontrol('Parent', panel.panel, 'Style', 'text',   'String', 'Min:',   'Units', 'pixels', 'Position', [bp,psh,bw/4,bh], 'HorizontalAlignment', 'right');
            panel.gui.minEdit =    uicontrol('Parent', panel.panel, 'Style', 'edit',   'String', 0,        'Units', 'pixels', 'Position', [2*bp+bw/4,psh,bw/2,bh]); %, 'Enable', 'Inactive');
            panel.gui.minSlid =    uicontrol('Parent', panel.panel, 'Style', 'slider', 'Value', 0,         'Units', 'pixels', 'Position', [3*bp+3*bw/4,psh,5*bw/4,bh], 'Min', 0, 'Max', 2, 'SliderStep', [2/300, 2/30]); % Instert reasoning for 2/3

            panel.gui.maxText =    uicontrol('Parent', panel.panel, 'Style', 'text',   'String', 'Max:',   'Units', 'pixels', 'Position', [bp,psh-bh,bw/4,bh], 'HorizontalAlignment', 'right');
            panel.gui.maxEdit =    uicontrol('Parent', panel.panel, 'Style', 'edit',   'String', 1,        'Units', 'pixels', 'Position', [2*bp+bw/4,psh-bh,bw/2,bh]); %, 'Enable', 'Inactive');
            panel.gui.maxSlid =    uicontrol('Parent', panel.panel, 'Style', 'slider', 'Value', 1,         'Units', 'pixels', 'Position', [3*bp+3*bw/4,psh-bh,5*bw/4,bh], 'Min', 0, 'Max', 2, 'SliderStep', [2/300, 2/30]);
            % uicontrol('Parent', panel.panel, 'Style', 'slider', 'Units', 'pixels', 'Position', [bp,psh,bw,bh]);
            
            panel.gui.dataMinText = uicontrol('Parent', panel.panel, 'Style', 'text',  'String', 'Data Min:',  'Units', 'pixels', 'Position', [2*bp+bw,psh-2*bh,bw/2,bh], 'HorizontalAlignment', 'right');
            panel.gui.dataMinEdit = uicontrol('Parent', panel.panel, 'Style', 'edit',  'String', 0,            'Units', 'pixels', 'Position', [3*bp+3*bw/2,psh-2*bh,bw/2,bh], 'Enable', 'Inactive');

            panel.gui.dataMaxText = uicontrol('Parent', panel.panel, 'Style', 'text',  'String', 'Data Max:',  'Units', 'pixels', 'Position', [2*bp+bw,psh-3*bh,bw/2,bh], 'HorizontalAlignment', 'right');
            panel.gui.dataMaxEdit = uicontrol('Parent', panel.panel, 'Style', 'edit',  'String', 1,            'Units', 'pixels', 'Position', [3*bp+3*bw/2,psh-3*bh,bw/2,bh], 'Enable', 'Inactive');

            panel.gui.normAuto =    uicontrol('Parent', panel.panel, 'Style', 'check', 'String', 'Auto Normalize', 'Units', 'pixels', 'Position', [bp,psh-2*bh,1.1*bw,bh], 'Value', 1);
            panel.gui.norm =        uicontrol('Parent', panel.panel, 'Style', 'push',  'String', 'Normalize',      'Units', 'pixels', 'Position', [bp,psh-3*bh,1.1*bw,bh], 'Callback', @panel.normalize_Callback);

            panel.gui.minEdit.Callback = @panel.edit_Callback;
            panel.gui.maxEdit.Callback = @panel.edit_Callback;
            
            panel.gui.minSlid.Callback = @panel.slider_Callback;
            panel.gui.maxSlid.Callback = @panel.slider_Callback;
            
            % Apparently, can't have two listeners on one object...
%             prop = findprop(mcProcessedData, 'data');
%             panel.datalistener = event.proplistener(panel.data, prop, 'PostSet', @panel.dataChanged_Callback);
%             listener = panel.datalistener
        end
        
        function edit_Callback(panel, src,~)
            val = str2double(src.String);

            if isnan(val)   % If it's NaN (if str2double didn't work), check if it's an equation
                try
                    val = eval(src.String);
                catch err
                    display(err.message);
                    val = 0;
                end
            end

            if isnan(val)   % If it's still NaN, set to zero
                val = 0;
            end

            switch src
                case panel.gui.minEdit
                    panel.gui.minSlid.Value = val;
                    panel.slider_Callback(panel.gui.minSlid, 0)
                case panel.gui.maxEdit
                    panel.gui.maxSlid.Value = val;
                    panel.slider_Callback(panel.gui.maxSlid, 0)
            end
        end
        function normalize_Callback(panel, ~, ~)
            if ~isnan(str2double(panel.gui.dataMinEdit.String))
                panel.gui.minSlid.Max = str2double(panel.gui.dataMinEdit.String);
            end
            panel.gui.minSlid.Value = panel.gui.minSlid.Max;

            if ~isnan(str2double(panel.gui.dataMaxEdit.String))
                panel.gui.maxSlid.Max = str2double(panel.gui.dataMaxEdit.String);
            end
            panel.gui.maxSlid.Value = panel.gui.maxSlid.Max;

            panel.slider_Callback(panel.gui.minSlid, -1);
            panel.slider_Callback(panel.gui.maxSlid, -1);
        end
        function slider_Callback(panel, src, ~)
            maxMagn = floor(log10(src.Max));

            if src.Value <= 0
                src.Value = 0;
                src.Max = 1e4;

                switch src
                    case panel.gui.minSlid
                        panel.gui.minEdit.String = 0;
                    case panel.gui.maxSlid
                        panel.gui.maxEdit.String = 0;
                end
            else
                magn = floor(log10(src.Value));

        %         if magn ~= log10(src.Value)
        %             magn = magn-1;
        %         end

                str = [num2str(src.Value/(10^magn), '%1.1f') 'e' num2str(magn)];

                switch src
                    case panel.gui.minSlid
                        panel.gui.minEdit.String = str;
                    case panel.gui.maxSlid
                        panel.gui.maxEdit.String = str;
                end

                if magn+1 > maxMagn
                    switch src
                        case panel.gui.minSlid
                            panel.gui.minSlid.Max = 1.5*10^(magn+1);
                        case panel.gui.maxSlid
                            panel.gui.maxSlid.Max = 1.5*10^(magn+1);
                    end
                end

                if magn+1 < maxMagn
                    switch src
                        case panel.gui.minSlid
                            panel.gui.minSlid.Max = 1.5*10^(magn+1);
                        case panel.gui.maxSlid
                            panel.gui.maxSlid.Max = 1.5*10^(magn+1);
                    end
                end
            end

            if panel.gui.minSlid.Value > panel.gui.maxSlid.Value
                switch src
                    case panel.gui.minSlid
                        panel.gui.maxSlid.Value = panel.gui.minSlid.Value;
                        if panel.gui.maxSlid.Max < panel.gui.minSlid.Value
                            panel.gui.maxSlid.Max = panel.gui.minSlid.Value;
                        end
                        if panel.gui.maxSlid.Min > panel.gui.minSlid.Value
                            panel.gui.maxSlid.Min = panel.gui.minSlid.Value;
                        end
                        panel.slider_Callback(panel.gui.maxSlid, 0);      % Possible recursion if careless?
                    case panel.gui.maxSlid
                        panel.gui.minSlid.Value = panel.gui.maxSlid.Value;
                        if panel.gui.minSlid.Max < panel.gui.maxSlid.Value
                            panel.gui.minSlid.Max = panel.gui.maxSlid.Value;
                        end
                        if panel.gui.minSlid.Min > panel.gui.maxSlid.Value
                            panel.gui.minSlid.Min = panel.gui.maxSlid.Value;
                        end
                        panel.slider_Callback(panel.gui.minSlid, 0);
                end
            else
                
            end
            
            panel.applyScale();
        end
        function dataChanged_Callback(panel, ~, ~)
%             a = panel.data
%             b = panel.data.data
            if panel.data.parent.r.plotMode == 0
                m = min(panel.data.parent.d.data{panel.data.input}(:));
                M = max(panel.data.parent.d.data{panel.data.input}(:));
            else
                m = panel.data.min();
                M = panel.data.max();
            end
            
            if all(isnan(m)) || isempty(m)
                m = 0;
            end
            if all(isnan(M)) || isempty(M)
                M = 1;
            end
            
%             if m == M
%                 m = m - 1;
%                 M = M + 1;
%             end

            if m <= 0
                str = '0';
            else
                magn = floor(log10(m));
%                 str = [num2str(m/(10^magn), '%1.1f') 'e' num2str(magn)];
                str = [num2str(floor(m/(10^(magn-1)))/10, '%1.1f') 'e' num2str(magn)];
            end

            if M <= 0
                STR = '0';
            else
                magn = floor(log10(M));
%                 STR = [num2str(M/(10^magn), '%1.1f') 'e' num2str(magn)];
                STR = [num2str(ceil(M/(10^(magn-1)))/10, '%1.1f') 'e' num2str(magn)];
            end
            
            if isnan(str2double(str))
                str = '0';
            end
            if isnan(str2double(STR))
                STR = '1';
            end
            
            if str2double(STR) < str2double(str)
                str = '0';
                STR = '1';
            end
            
            str0 = panel.gui.dataMinEdit.String;
            STR0 = panel.gui.dataMaxEdit.String;

            panel.gui.dataMinEdit.String = str;
            panel.gui.dataMaxEdit.String = STR;

            if panel.gui.normAuto.Value && ~(strcmpi(str0, str) && strcmpi(STR0, STR))
                panel.normalize_Callback(0,0);
            else
                panel.applyScale()
            end
        end
        function applyScale(panel)
            m = panel.gui.minSlid.Value;
            M = panel.gui.maxSlid.Value;
            
            if m == M
                M = .001 + M;   % Make better?
            end

            if ~isempty(panel.data)
                switch panel.data.parent.r.plotMode
                    case 0
                        xlim(panel.data.parent.dataViewer.a, [m M]);
                    case 1
                        ylim(panel.data.parent.dataViewer.a, [m M]);
                        panel.data.parent.dataViewer.posL.sel.YData = [m M];
                        panel.data.parent.dataViewer.posL.pix.YData = [m M];
                        panel.data.parent.dataViewer.posL.prv.YData = [m M];
                        panel.data.parent.dataViewer.posL.act.YData = [m M];
                    case 2
        %                 disp('here');
        %                 panel.data.parent.dataViewer.a
                        caxis(panel.data.parent.dataViewer.a, [m M]);
                end
            end
        end
    end
end




