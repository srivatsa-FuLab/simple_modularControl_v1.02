classdef mcVideo < mcInput
% mcVideo gets video with videoinput. It is a subclass of mcInput becaues it acts like an input. It does not start with mci
% because it is more than 'just an input'...
    
    properties
        f = [];         % Figure.
        a = [];         % Axes; video displayed here.
        v = [];         % videoinput object
        i = [];         % image object
        p = [];         % plot object (for border);
        % s = [];         % scatterplot object (for adding points to the view) (already defined in mcInput)
        
        fb = [];        % Feedback vars
        
        pidArray = [];      % PIDs for the x, y, and z axes.
    end
    
    methods (Static)
        % Neccessary extra vars:
        %  - adaptor    string
        %  - format     string
        %  - fbAxes     cell array with {x,y,z}; [] for no feedback
        
        function config = defaultConfig()
            config = mcVideo.blueConfig();
        end
        function config = blueConfig()
            config.name =               'Blue';

            config.kind.kind =          'videoinput';
            config.kind.name =          'videoinput() Input';
            config.kind.extUnits =      'arb';                      % 'External' units.
            config.kind.normalize =     false;
            config.kind.sizeInput =     [NaN NaN];                  % Unknown until initiation
            
            config.adaptor =            'avtmatlabadaptor64_r2009b';
            config.format =             'F0M5_Mono8_640x480';
            
            
            configPiezoX = mcaDAQ.piezoConfig();    configPiezoX.name = 'Piezo X'; configPiezoX.chn = 'ao0';       % Customize all of the default configs...
            configPiezoY = mcaDAQ.piezoConfig();    configPiezoY.name = 'Piezo Y'; configPiezoY.chn = 'ao1';
            configPiezoZ = mcaDAQ.piezoZConfig();   configPiezoZ.name = 'Piezo Z'; configPiezoZ.chn = 'ao2';
            
            config.fbAxes = {mcaDAQ(configPiezoX), mcaDAQ(configPiezoY), mcaDAQ(configPiezoZ)};
        end
        function config = brynnConfig()
            config.name =               'Point Grey';

            config.kind.kind =          'videoinput';
            config.kind.name =          'videoinput() Input';
            config.kind.extUnits =      'arb';                      % 'External' units.
            config.kind.normalize =     false;
            config.kind.sizeInput =     [NaN NaN];                  % Unknown until initiation
            
            config.adaptor =            'pointgrey';
            config.format =             '';
            
            configGalvoX = mcaDAQ.galvoXBrynnConfig();
            configGalvoY = mcaDAQ.galvoYBrynnConfig();
            
            configObjZ = mcaEO.brynnObjConfig();
            
            config.fbAxes = {mcaDAQ(configGalvoX), mcaDAQ(configGalvoY), mcaEO(configObjZ)};
        end
    end
    
    methods
        function vid = mcVideo(varin)
            vid.extra = {'adaptor', 'format', 'fbAxes'};
            if nargin == 0
                vid.construct(vid.defaultConfig());
            else
                vid.construct(varin);
            end
            vid = mcInstrumentHandler.register(vid);
            
            
            if ~vid.inEmulation
%                 if nargin == 0
%                     varin = mcVideo.defaultConfig();
%                 end
% 
%                 vid = vid@mcInput(varin);   % Change this?
%                 vid.construct(varin);

                vid.f = mcInstrumentHandler.createFigure(vid, 'saveopen');

%                 vid.f.Resize =      'off';
                if strcmpi(vid.config.format, 'F0M5_Mono8_640x480')
                    %vid.f.Position =    [50, 50, 1280, 960];
                    vid.f.Position =    [50, 50, 850, 800];
                else
                    vid.f.Position =    [50, 50, 960, 960];
                end
                vid.f.Visible =     'on';
    %             f.MenuBar =     'none';
    %             f.ToolBar =     'none';
                % Future: make resize fnc
                % Future: make close fnc

                hToolbar = findall(vid.f, 'tag', 'FigureToolBar');
                % Create a uipushtool in the toolbar
                uitoggletool(hToolbar, 'TooltipString', 'Image Feedback', 'ClickedCallback', @vid.toggleFeedback_Callback, 'CData', iconRead(fullfile('icons','feedback.png')));

                vid.a = axes(   'Position', [0 0 1 1],...
                                'XTick', 0,...
                                'YTick', 0,...
                                'LineWidth', 4,...
                                'Box', 'on');
                            
               % set(vid.a,'DataAspectRatio', [1 1 1]);
                
    %             vid.a = axes('Position', [.01 .01 .98 .98], 'XTick', 0, 'YTick', 0, 'LineWidth', 4, 'Box', 'on');

    %             hold(vid.a, 'on')
                
                if isempty(vid.config.format)
                    vid.v = videoinput(vid.config.adaptor, 1);
                else
                    vid.v = videoinput(vid.config.adaptor, 1, vid.config.format);
                end

                vid.v.FramesPerTrigger = 1;
               
                
              % vidRes = vid.v.VideoResolution
              
              %Custom ROI defined 2020/01/02 by srivatsa
                vid.v.ROIPosition = [19 34 400 434];
                ROI = vid.v.ROIPosition;
                vidRes = [ROI(3)-ROI(1) ROI(4)-ROI(2)];
                
                nBands = vid.v.NumberOfBands;
                vid.i = image(zeros(vidRes(2), vidRes(1), nBands), 'YData', [vidRes(2) 1], 'ButtonDownFcn', @vid.windowButtonDownFcn);
                preview(vid.v, vid.i);     % this appears on the axes we made.
                
                hold(vid.a, 'on')

                vid.p = plot([1 1 vidRes(1) vidRes(1) 1], [1 vidRes(2) vidRes(2) 1 1]);
                vid.p.Color = [0 1 0];
                vid.p.LineWidth = .01;
                
                vid.s = scatter(-1, -1, 200,...
                    'PickableParts', 'none',...
                    'Marker', 'o',...
                    'MarkerEdgeColor', 'r',...
                    'MarkerFaceColor', 'r',...
                    'MarkerFaceAlpha', .25,...
                    'LineWidth', 1.5);

                vid.config.kind.sizeInput = vidRes;

%                 vid.config.fbAxes{1}.name()
%                 vid.config.fbAxes{2}.name()
%                 vid.config.fbAxes{3}.name()

                vid.pidArray = {mcPID(vid.config.fbAxes{1}), mcPID(vid.config.fbAxes{2}), mcPID(vid.config.fbAxes{3})};
            end
        end
        
        function image = getImage(vid)
            image = flipud(getsnapshot(vid.v));
        end
        
        function saveGUI_Callback(vid, ~, ~)
            [FileName, PathName, FilterIndex] = uiputfile({'*.png', 'Image (*.png)'}, 'Save As');
            
            if all(FileName ~= 0)
                switch FilterIndex
                    case 1  % .png
                        imwrite(vid.getImage(), [PathName FileName]);
                end
            else
                disp('No file given...');
            end
        end
        
%         function focusFcn(vid, ~, event, ~)
%             % Future
%         end
%         function startFocus_Callback(vid, ~, ~)
%             vid.i.UpdatePreviewWindowFcn = @vid.focusFcn;
%         end
%         function stopFocus_Callback(vid, ~, ~)
%             vid.i.UpdatePreviewWindowFcn = [];
%         end
        function toggleFeedback_Callback(vid, src, ~)
            switch src.State
                case 'on'
                    startFeedback_Callback(vid, 0, 0);
                case 'off'
                    stopFeedback_Callback(vid, 0, 0);
            end
        end
        function startFeedback_Callback(vid, ~, ~)
            disp('Starting Feedback');
            % Srivatsa's code:
            vid.fb.frame_init = imadjust(flipud(vid.getImage()));         % imadjust increases the contrast of the image by normalizing the data.
            vid.fb.points1 = detectSURFFeatures(vid.fb.frame_init, 'NumOctaves', 6, 'NumScaleLevels', 10,'MetricThreshold', 500);
            [vid.fb.features1, vid.fb.valid_points1] = extractFeatures(vid.fb.frame_init,  vid.fb.points1);
            
            vid.fb.targetContrast = getContrast(vid.fb.frame_init);
            
            setappdata(vid.i, 'UpdatePreviewWindowFcn', @vid.feedbackFcn);
        end
        function stopFeedback_Callback(vid, ~, ~)
            disp('Stopping Feedback');
%             vid.i.UpdatePreviewWindowFcn = [];
            setappdata(vid.i, 'UpdatePreviewWindowFcn', []);
            vid.p.Color = [0 1 0];       
            vid.p.LineWidth = .01;
        end
        function feedbackFcn(vid, ~, event, ~)  % Third input is handle to image (special to this callback).
            vid.i.CData = event.Data;
            
            frame = imadjust(event.Data);   % Normalize image (remove for performance?)
            
            % XY FEEDBACK
            points2 = detectSURFFeatures(frame, 'NumOctaves', 6, 'NumScaleLevels', 10,'MetricThreshold', 500);
            [features2, valid_points2] = extractFeatures(frame,  points2);
%             points2.selectStrongest(50))

            indexPairs = matchFeatures(vid.fb.features1, features2);

            matchedPoints1 = vid.fb.valid_points1(indexPairs(:, 1), :);
            matchedPoints2 = valid_points2(indexPairs(:, 2), :);
            
            % Remove Outliers
            delta = (matchedPoints2.Location - matchedPoints1.Location);
            dist = sum(delta.*delta, 2); %sqrt(delta(:,1).*delta(:,1) + delta(:,2).*delta(:,2));

            mean_dist = mean(dist);
            stdev_dist = std(dist);
            
            % And filter the points such that only those within one standard deviation of the mean remain (change in the future?).
            filteredPoints = dist <= mean_dist + stdev_dist & dist >= mean_dist - stdev_dist;
            
            if ~isempty(filteredPoints)                       % If there are points left after the filtering...
                offset = mean(delta(filteredPoints, :));
                
                if length(offset) == 2
                    vid.pidArray{1}.compute(-offset(1));         % Calculate the output of the pids (recommended um), based on the input offset...
                    vid.pidArray{2}.compute(-offset(2));    % WARNING, this will need to be modified to account for negative axes...

                    d = sum(offset.*offset);

                    if ~isnan(d)
                        vid.p.Color = [1 - 1/(1 + .25*d) 1/(1 + .25*d) 0];       % Amount of red represents the deviation from the desired value.
                        vid.p.LineWidth = 5 - 4/(1 + .25*d);
                    end
                end
            end
            
            % Z FEEDBACK
%             contrast = getContrast(frame);
%             
%             if contrast < .9*vid.fb.targetContrast     % If the contrast is significantly less than 
%                 contrast
%                 vid.fb.targetContrast
%             end
            
            drawnow limitrate
        end
        
        function windowButtonDownFcn(vid, ~, e)
            switch e.Button
                case 1      % left click
                    vid.addPoint(e);
                case 3      % right click
                    vid.deletePoint(e);
            end
        end
        function addPoint(vid, e)
            vid.s.XData(end+1) = e.IntersectionPoint(1);
            vid.s.YData(end+1) = e.IntersectionPoint(2);
        end
        function deletePoint(vid, e)
            X = vid.s.XData - e.IntersectionPoint(1);
            Y = vid.s.YData - e.IntersectionPoint(2);
            
            D = X.^2 + Y.^2;
            
            vid.s.XData = vid.s.XData(D ~= min(D));
            vid.s.YData = vid.s.YData(D ~= min(D));
        end
    end

    methods
        % EQ
        function tf = Eq(vid, b)  % Check if a foreign object (b) is equal to this input object (a).
            tf = strcmp(vid.config.adaptor,  b.config.adaptor) && strcmp(vid.config.format, b.config.format);
        end
        
        % NAME
        function str = NameShort(vid)
            str = [vid.config.name ' (' vid.config.adaptor ', ' vid.config.format ')'];
        end
        function str = NameVerb(vid)
            str = [vid.config.name ' (video object with adaptor ' vid.config.adaptor ' and format ' vid.config.format ')'];
        end
        
        % OPEN/CLOSE uneccessary.
        
        % MEASURE
        function data = MeasureEmulation(~, ~)
            data = vid.getImage();
        end
        function data = Measure(vid, ~)
            data = vid.getImage();
        end
    end
end

function contrast = getContrast(image)  % Returns a number proportional(?) to the contrast of the image
%     i = gpuArray(image);    % Use GPU acceleration or not?
    
    contrast = sum(sum(imabsdiff(image, imfilter(image, fspecial('gaussian')))));
end




