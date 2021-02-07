classdef mcProcessedData < handle
% mcProcessedData contains, as the name might suggest, a processed version
% of the N-dimensional data stored in a mcData structure. The data can be 1D (plot) or 2D
% (colormap) (and maybe eventually 3D). The parent mcData structure is
% referenced in 'parent'. The data that is processed is 'data'. The
% parameters that define the proccessing procedure is defined in 'params'.
%
% Syntax:
%   pd = mcProcessedData(parent)            % Proccess parent data (mcData) with default settings
%   pd = mcProcessedData(parent, params)    % Proccess parent data (mcData) with settings defined by 'params'
%
% Status: Mostly finished, but has no clue what to do when data is not numeric (3D not done also). params not currently used,
%   but probably will be when RGB is implemented.
% Update 12/21: Revising; above is no longer accurate.

    properties
        parent = [];        % Parent mcData class.
        viewer = [];        % Parent(ish) mcViewer class.
        
        listener = [];      % Listens to changes in parent.
        
        input = 1;          % Input to proccess...
    end
    properties (SetObservable)
        data = NaN;
    end
    
    methods
        function pd = mcProcessedData(varin)
            if nargin == 1
                pd.parent = varin;
            elseif nargin == 2
                pd.parent = varin{1};
            end
            
            prop = findprop(pd.parent, 'd');
            pd.listener.d = event.proplistener(pd.parent, prop, 'PostSet', @pd.parentChanged_Callback);
            prop2 = findprop(pd.parent, 'r');
            pd.listener.r = event.proplistener(pd.parent, prop2, 'PostSet', @pd.parentChanged_Callback);
        end
        
        function m = min(pd)
            m = min(min(min(pd.data)));
        end
        function M = max(pd)
            M = max(max(max(pd.data)));
        end
        
        function parentChanged_Callback(pd, ~, ~)
            pd.process();
        end
        
        function process(pd)
%             pd.parent.r == pd
%             pd
%             pd.parent.dataViewer.r
            if (pd.parent.dataViewer.isRGB || pd.parent.dataViewer.r == pd) && pd.parent.dataViewer.shouldPlot
                switch pd.parent.r.plotMode
                    case {0, 'histogram'}
                        % Do nothing.
                        pd.parent.dataViewer.plotData_Callback(0,0);
                    case {1, '1D'}
                        selTypeX =    	pd.parent.r.l.type(pd.parent.r.l.layer == 1);

                        if ~(selTypeX == 0 || selTypeX == pd.input)
                            error('mcProcessedData.proccess(): mcDataViewer should prevent this from happening')
                        end

                        relevant =      pd.parent.r.l.type == 0 | pd.parent.r.l.type == pd.input;

                        nums =          1:length(pd.parent.r.l.layer);
                        nums(relevant)= 1:sum(relevant);                        % This is neccessary if there are multiple inputs.
                        toMean =        relevant & pd.parent.r.l.layer == 2;

                        d = pd.parent.d.data{pd.input};

                        for ii = nums(toMean)
                            d = nanmean(d, ii);
                        end

                        final = relevant & pd.parent.r.l.lengths ~= 1 & pd.parent.r.l.layer ~= 2;   % If relevant and not singleton or meaned.

                        d = squeeze(d); % Remove singleton dimensions (whether natural or meaned).

                        nums =          1:length(final);
                        axisXindex = nums(pd.parent.r.l.layer(final) == 1);

                        pd.data = d( getIndex(pd.parent.r.l.lengths(final), pd.parent.r.l.layer(final) - 2, axisXindex) );
                    case {2, '2D'}
                        selTypeX =    	pd.parent.r.l.type(pd.parent.r.l.layer == 1);
                        selTypeY =    	pd.parent.r.l.type(pd.parent.r.l.layer == 2);
                        
%                         selTypeX =    	pd.parent.r.l.type(pd.parent.r.l.layer == 1)
%                         selTypeY =    	pd.parent.r.l.type(pd.parent.r.l.layer == 2)
%                         in = pd.input
%                         len = pd.parent.r.l.lengths
%                         l = pd.parent.r.l.layer
%                         t = pd.parent.r.l.type

                        if isempty(selTypeX) || isempty(selTypeY)
                            warning('mcProcessedData(): Layer has not updated properly...');
                            return;
                        end

%                         tx = selTypeX == 0 || selTypeX == pd.input
%                         ty = selTypeY == 0 || selTypeY == pd.input

                        if ~(selTypeX == 0 || selTypeX == pd.input) || ~(selTypeY == 0 || selTypeY == pd.input)
                            error('mcProcessedData.proccess(): mcDataViewer should prevent this from happening')
                        end

                        relevant =      pd.parent.r.l.type == 0 | pd.parent.r.l.type == pd.input;

                        nums =          1:length(pd.parent.r.l.layer);
                        nums(relevant)= 1:sum(relevant);                    % This is neccessary if there are multiple inputs.
                        
                        toMean =        relevant & pd.parent.r.l.layer == 3;

                        d = pd.parent.d.data{pd.input};

                        for ii = nums(toMean)
                            d = nanmean(d, ii);
                        end

                        final = relevant & pd.parent.r.l.lengths ~= 1 & pd.parent.r.l.layer ~= 3;   % If relevant and not singleton or meaned.

                        d = squeeze(d); % Remove singleton dimensions (whether natural or meaned).

                        nums =          1:length(final);
                        
                        axisXindex = nums(pd.parent.r.l.layer(final) == 1);
                        axisYindex = nums(pd.parent.r.l.layer(final) == 2);

                        pd.data = d( getIndex(pd.parent.r.l.lengths(final), pd.parent.r.l.layer(final) - 3, axisXindex, axisYindex) );
                    case {3, '3D'}
                        error('3D NotImplemented');
                    otherwise
                        error('Plotmode not recognized...');
                end
            end
        end
    end
end




