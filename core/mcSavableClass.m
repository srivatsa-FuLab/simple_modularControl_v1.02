classdef mcSavableClass < handle
% mcSavableClass is the parent class for objects (mostly figures) that have
%   configs which are savable and should be recoverable in the future (e.g.
%   after restart).
%
% Status: Mostly finished. Needs commenting.
    
    properties
        config = [];
    end
    
    methods
        function makeClassFolder(obj)   % Makes the folder 
            folder = [mcInstrumentHandler.getConfigFolder() class(obj)];
            if ~exist(folder, 'file')
                mkdir(folder);
            end
        end
        
        function load(obj)
            fname = [mcInstrumentHandler.getConfigFolder() class(obj) filesep 'config.mat'];
            
            if exist(fname, 'file')
                load(fname);
                c = load(fname);
                
                if isfield(c.config, 'ver')     % If this .mat config was created after the check for version was implemented...
                    if all(c.config.ver == mcInstrumentHandler.version())   % And if we are using the same version...
                        obj.config = c.config;  % Then use the .mat config as our config.
                    end
                end
            end
        end
        
        function save(varin)            % Saves the config which defines an idenity of a mcSavableClass subclass.
%             'saving!'
            switch nargin   % Figure out where to save.
                case 1
                    obj = varin;
                    if isfield(obj.config, 'src')
                        fname = obj.config.src;
                    elseif isfield(obj.config, 'name')
                        fname = [mcInstrumentHandler.getConfigFolder() class(obj) filesep obj.config.name '.mat'];
                    else
                        if ismethod(obj, 'name')
                            fname = [mcInstrumentHandler.getConfigFolder() class(obj) filesep obj.name() '.mat'];
                        else
                            fname = [mcInstrumentHandler.getConfigFolder() class(obj) filesep 'config.mat'];
                        end
                    end
                case 2
                    obj = varin{1};
                    fname = [mcInstrumentHandler.getConfigFolder() class(obj) filesep varin{2}];
            end
            
%             obj
%             isprop(obj, 'f')
            
            if isprop(obj, 'f')     % If this savable class has a figure....   %&& isfield(obj.config, 'Position') % If this savable class has a figure and cares about position,
                obj.config.Position = obj.f.Position;   % Then save the position in the config.
            end
            
            obj.makeClassFolder();

            config = obj.config;        %#ok
            config.ver = mcInstrumentHandler.version();
%             config

            save(fname, 'config');
        end
        
        function saveGUI_Callback(obj, ~, ~)
            obj.makeClassFolder();
            [FileName, PathName] = uiputfile('*.mat', 'Save Config As', [mcInstrumentHandler.getConfigFolder() class(obj) filesep 'config.mat']);
            if FileName ~= 0
                config = obj.config;    %#ok
                save([PathName FileName], 'config');
            end
        end
        
%         function interpretConfig(obj, config)
%             if ischar(config)
%                 obj.load(config);
%             elseif isstruct(config)
%                 obj.config = config;
%             end
%         end
        
%         function load(obj, fname)
%             if ~exist(fname, 'file')   % If the file initially doesn't exist, try looking in the class's path.
%                 fname = [mcInstrumentHandler.getConfigFolder() class(obj) filesep fname];
%             end
%             
%             if exist(fname, 'file')
%                 config2 = load(fname);
%                 obj.config = config2.config;
%                 obj.config.src = fname;
%             else
%                 warning([class(obj) '.load(fname): The file "' fname '" given to load does not exist.']);
%             end
%         end
%         function loadGUI_Callback(obj, ~, ~)
% %             questdlg('Config loading not fully implemented... Sorry.', 'Config Loading Not Implemented', 'Okay', 'Okay');
%             if true
%                 obj.makeClassFolder();
%                 [FileName, PathName] = uigetfile('*.mat', 'Load Config', [mcInstrumentHandler.getConfigFolder() class(obj)]);
%                 obj.load([PathName FileName]);
% %                 if FileName ~= 0
% %                     config2 = load([PathName FileName]);
% %                     obj.config = config2.config;
% %                     obj.config.src = [PathName FileName];
% %                 end
%             end
%         end
        function loadGUI_Callback(obj, ~, ~)
%             questdlg('Config loading not fully implemented... Sorry.', 'Config Loading Not Implemented', 'Okay', 'Okay');
%             if true
            obj.makeClassFolder();
            [FileName, PathName] = uigetfile('*.mat', ['Load Config For ' class(obj)], [mcInstrumentHandler.getConfigFolder() class(obj)]);

            config2 = load([PathName FileName]);    % Load the new config.
            c = config2.config;                     %#ok
            
%             c
%             
%             [class(obj) '(c)']

            eval([class(obj) '(c)']);               % Make new object
%             end
        end
    end
end




