function index = getIndex(varargin)
% getIndex returns a matrix that, when used as an argument for a matrix of
%   dimension lengths, will return a 1D or 2D (or soon 3D) slice of that
%   matrix in along the x line (1D) or in the x y plane (2D) which passes
%   through the coordinate specified by layer.
%
% Syntax:
%   - getIndex(lengths, layer, x)           % 1D
%   - getIndex(lengths, layer, x, y)        % 2D
%   - getIndex(lengths, layer, x, y, z)     % 3D (will finish sometime (probably never))
%
% Status: Function finished. Math and reasoning under-explained. Could use
%   better examples.
%
% Future: Make this work with implicit addition (new to 2016b) instead of repmat...
%
% 2D example:
%   We want to get a 2D slice of an ND matrix with dimensions lengths 
%   (e.g. lengths = [3 4 5] ==> a 3 x 4 x 5 matrix.  This 2D slice will be
%   in the x-y plane where x is the xth dimension and y is the yth
%   dimenstion (e.g. x=1,y=2 ==> slice in 1-2 plane). Layer fixes the
%   position of the slice in the other dimensions; the returned slice
%   will always pass through the point layer in ND space (note that the
%   xth and yth components of layer do not matter, of course).


    mode = nargin;
    
    if mode < 3
        error('getIndex: Not enough inputs');
    end

    if length(varargin{1}) ~= length(varargin{2})
        error('getIndex: layer should be the same length as lengths.');
    end
    
%     if sum(lengths < layer | layer > 1)
%         error('layer should be bounded by lengths.');
%     end

%     for ii = 1:mode
%         varargin{ii}
%     end
    
    if length(varargin{1}) < mode - 2
        error('getIndex: Cannot find a ND slice of a MD matrix where M < N');
    end

    indexWeight = getIndexWeight(varargin{1});

    switch mode
        case 3
            lengths =   varargin{1};
            layer =     varargin{2};
            x =         varargin{3};
            
            lx = lengths(x);            % The length of the vector that we will return.
            nums = 1:length(lengths);
            
            % First term is a vector with spacing appropriate for the line
            % we are trying to make. Second term offsets this vector to
            % correspond to the layer that we desire.
            index = (1:indexWeight(x):lx*indexWeight(x)) + (indexWeight * ((layer - 1).* (nums ~= x))');
        case 4
            lengths =   varargin{1};
            layer =     varargin{2};
            x =         varargin{3};
            y =         varargin{4};
            
            lx = lengths(x);
            ly = lengths(y);

            indexSize = lx*ly;          % The number of elements in the matrix that we will return.

            repWeight = indexWeight(x) - indexWeight(y)*ly;

            nums = 1:length(lengths);
            offset = indexWeight * ((layer - 1).* (nums ~= x & nums ~= y))';

            index = reshape(1:indexWeight(y):indexSize*indexWeight(y), ly, lx) + repmat(repWeight*(0:(lx-1)) + offset, ly, 1);
        case 5
%             lengths =   varin{1};
%             layer =     varin{2};
%             x =         varin{3};
%             y =         varin{4};
%             z =         varin{5};
            error('getIndex: 3D NotImplemented');
        otherwise
            error('getIndex: Number of arguments not recognized');
    end
end

function indexWeight = getIndexWeight(lengths)
    l = length(lengths);
    
    indexWeight = ones(1, l);
    
    for ii = 2:l
        indexWeight(ii:end) = indexWeight(ii:end)*lengths(ii-1);
    end
end

