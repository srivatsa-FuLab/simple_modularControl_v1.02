classdef mcgScope < mcGUI
    % Template to explain how to make a custom mcGUI (unfinished).
    properties
        objects = []
    end
    
    methods (Static)
        function config = defaultConfig()
            config = mcgScope.ScopeConfig();
        end       
        config = ScopeConfig();
    end
    
    methods
        function gui = mcgScope(varin)
            switch nargin
                case 0
                    gui.load();                             % Attempt to load a previous config from configs/computername/classname/config.mat
                    
                    if isempty(gui.config)                  % If the file did not exist or the loading failed...
                        gui.config = gui.defaultConfig()   % ...then use the defaultConfig() as a backup.
                    end
                case 1
                    gui.config = varin;
            end
            
            gui.buildGUI();
        end       
        Callbacks(gui, ~, ~, cbName) 
        setupObjects(gui)
    end
end

