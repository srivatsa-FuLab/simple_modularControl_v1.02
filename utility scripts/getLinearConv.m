function config = getLinearConv(config, intRange, extRange)
% getLinearConv Sets int2extConv and ext2intConv in config.kind to the appropriate linear relationships to map between intRange
% and extRange.

    if ~all(size(intRange) == [1 2]) && ~all(size(intRange) == [2 1])
        error(['getLinearConv(): Unexpected size of intRange; is ' size(intRange) ' but must be [1 2] or [2 1]']);
    end
    if ~all(size(extRange) == [1 2]) && ~all(size(extRange) == [2 1])
        error(['getLinearConv(): Unexpected size of intRange; is ' size(extRange) ' but must be [1 2] or [2 1]']);
    end
    
    if diff(intRange) == 0
        error('getLinearConv(): intRange cannot have zero range.');
    end
    if diff(extRange) == 0
        error('getLinearConv(): extRange cannot have zero range.');
    end
    
    config.kind.intRange =      intRange;
    config.kind.int2extConv =   @(x)((x - intRange(1))*diff(extRange)/diff(intRange) + extRange(1));
    config.kind.ext2intConv =   @(x)((x - extRange(1))*diff(intRange)/diff(extRange) + intRange(1));
end

