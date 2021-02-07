function [char, magn, str] = getMagn(num)
% getMagn returns the character corresponding to the magnitude (rounded to nearest 3) of num. Also returned is magn, the
%   calculated magnitude of num. It also returns the number in '###.## c' form where c is the character corresponding to the
%   magnitude.
% Status: Finished and commented.

    if ~isnumeric(num)                      % If a number was not given, return N/A values
        warning('getMagn(): Expected numeric input');
        
        char = '';
        magn = NaN;
        str = '###.## ';
        
        return;
    end

    if num == 0                             % log10 can't handle zero, so a special case...
        char = '';
        magn = 1;
        str = '0.00 ';
        return;
    elseif num > 0
        m = ceil((log10(num) - 2)/3);       % Each magnitude has its range in (.1, 100].
    else
        m = ceil((log10(-num) - 2)/3);      % log10 can't handle negative numbers, so a special case...
    end

    chars = 'YZEPTGMk munpfazy';            % https://en.wikipedia.org/wiki/Order_of_magnitude#Uses
    
    if m > 8                                % Make sure that m is in range (even though this probably won't be an issue)
        m = 8;
    end
    if m < -8
        m = -8;
    end

    char = chars(9-m);
    if char == ' '
        char = '';
    end

    magn = 1000^(-m);
    
    str = [num2str(num*magn, '%.2f') ' ' char];
end