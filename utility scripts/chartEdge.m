function chartEdge(input, waypoints)
%chartEdge follows the edge of something (presumably diamond), droppping waypoints as it goes.
% Status: Unfinished. Just an idea.

%     axesZ.focus();

%     if input.config.kind.sizeInput
%         
%     end

    r = 10;
    n = 20;

    d = zeros(1, n);
    
    ii = 1;
    
    for ang = linspace(0, 2*pi, n)
        axesX.goto(r*cos(ang));
        axesY.goto(r*sin(ang));
        d(ii) = input.measure();
    end

end

