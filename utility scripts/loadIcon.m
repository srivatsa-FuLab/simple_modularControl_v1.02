function CData = loadIcon(file)
    [CData, ~, ~] = imread(fullfile('icons', file));    % Use mcInsturmentHandler's knowledge of the modularControl directory.
end




