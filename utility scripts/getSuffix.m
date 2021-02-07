function str = getSuffix(num)
% getSuffix returns the (rounded) number followed by the appropriate {'st', 'nd', 'rd', 'th'}. Does not work for complex numbers.

    num =   round(num);
    n =     abs(num);

    if (n >= 11 && n <= 13)
        str = [num2str(num) 'th'];
        return;
    end

    switch mod(n, 10)
        case 1
            str = [num2str(num) 'st'];
        case 2
            str = [num2str(num) 'nd'];
        case 3
            str = [num2str(num) 'rd'];
        otherwise
            str = [num2str(num) 'th'];
    end
end




