function x = interpretNeSpectrum(varargin)
% interpretNeSpectrum calculates the conversion between pixels and nanometers based on a Ne spectrum. It tries to match the
% provided spectrum with the expected Ne spectrum (peak positions and relative heights).
%
% Syntax:
% 
% interpretNeSpectrum(spectrum)                 %
% interpretNeSpectrum('spectrum.mat')           % 
% interpretNeSpectrum('spectrum.SPE')           %
%
% interpretNeSpectrum(oneOfTheAbove, outputNM)  % optional switch to output Hz (false) vs the default nm (true)
%
% Status: Not fully debugged. Not sure what will happen if a peak is missing.
    
    % These values are approximations from the OceanOptics documentation.
    peaksNe = [ %341.790, NaN;
                %342.391, NaN;
                %503.135, NaN;
                %503.775, NaN;
                %540.056, NaN;
                %576.441, NaN;
                %582.015, NaN;
                585.249, 3700;
                588.189, 2500;
                594.483, 4000;
                597.553, 1000;
                602.999, 1300;
                607.433, 3500;
                609.616, 5800;
                %612.884, NaN;
                614.306, 8900;
                616.359, 3500;
                621.728, 2800;
                626.649, 6200;
                630.479, 2000;
                633.442, 7500;
                638.299, 11700;
                640.225, 15500;
                650.653, 10300;
                653.288, 4200;
                659.895, 4500;
                667.828, 8100;
                671.704, 5500;
                692.947, 6200;
                703.241, 15500;
                717.394, 1100;
                724.512, 9700;
                743.890, 2000;
%                 747.244, NaN;
%                 748.887, NaN; % Too close; average of these is next
                748, 500;
%                 753.577, NaN;
%                 754.404, NaN; % Too close; average of these is next
                754, 500];
%                 1117.752, NaN;
%                 1152.275, NaN];
    
    lorentzian = @(a, b, c, d, x)( d + a./((c*(x-b)).^2 + 1));

    switch nargin
        case 1
            spectrum = varargin{1};
            outputNM = true;
        case 2
            spectrum = varargin{1};
            outputNM = varargin{2};
        otherwise
            error('interpretNeSpectrum(): Number of arguments not understood')
    end
    
    if ischar(spectrum) % If spectrum is a filename,
        switch lower(spectrum(end-2:end))
            case 'mat'
                temp = load(spectrum);
                spectrum = temp.spectrum;       % Guess! fix this!
            case 'spe'
                spectrum = readSPE(spectrum);
            otherwise
                error('interpretNeSpectrum(): Filetype not .SPE or .mat')
        end
    end
    
    spectrum = double(spectrum);
    spectrumlen = length(spectrum);
        
    minprom = min(100, max(spectrum)/10);
    
    % Do rough peakfinding with findpeaks.
    [peaks, locs, ~] = findpeaks( spectrum, 1:spectrumlen, 'MinPeakWidth', 4, 'MinPeakProm', minprom);     % Should ignore cosmic rays
      
    numLocs = length(locs);
                            
%     % Break up the spectrum into regions
%     regionEdges = [0   floor(.5*(locs(1:end-1) + locs(2:end)))    spectrumlen];
%     
%     for ii = 1:numLocs   % For each region 'centered' on each peak...
%         region = (regionEdges(ii) + 1):regionEdges(ii+1)
%         
%         fitobject = fit(region', spectrum(region)', lorentzian, 'Lower',[0, -Inf, 0, 0], 'StartPoint',[peaks(ii) locs(ii) wids(ii) 0])
%         
%         plot(fitobject);
%                     % ...do fine peakfinding with lorentz fitting.
%     end

    numPossible = max(size(peaksNe)) - numLocs;
    possibilities = zeros(1, numPossible);
    
    locsNorm =  (locs - min(locs))/(max(locs) - min(locs));
    peaks = peaks/max(peaks);

    for ii = 1:numPossible
        toMatchLocs =   peaksNe(ii:ii+numLocs-1, 1)' - peaksNe(ii, 1);
        toMatchPeaks =  peaksNe(ii:ii+numLocs-1, 2)';
        
        if ii > 1 && (peaksNe(ii-1, 1) - peaksNe(ii, 1))/(max(toMatchLocs) - min(toMatchLocs)) > (1 - min(locs))/(max(locs) - min(locs))
            possibilities(ii) = possibilities(ii) + 1;
        end
        
        if ii < numPossible && (peaksNe(ii+numLocs, 1) - peaksNe(ii+numLocs-1, 1))/(max(toMatchLocs) - min(toMatchLocs)) < (512 - min(locs))/(max(locs) - min(locs))
            possibilities(ii) = possibilities(ii) + 1;
        end
        
        toMatchLocs =   (toMatchLocs - min(toMatchLocs))/(max(toMatchLocs) - min(toMatchLocs));
        toMatchPeaks =  toMatchPeaks/max(toMatchPeaks);
        
        possibilities(ii) = possibilities(ii) + sum((locsNorm - toMatchLocs).^2) + sum((peaks - toMatchPeaks).^2)/2;
    end
    
    bestFit = find(possibilities == min(possibilities));
    bestMatchLocs = peaksNe(bestFit:bestFit+numLocs-1, 1);
%     bestPeaks = peaksNe(2, ii:ii+numLocs-1);
    
    fitobject = fit(locs', bestMatchLocs, 'poly1');
    
    fitPlot = zeros(1, 512);
    x = fitobject(1:512)';
    
    if ~outputNM
        x = 3e8./(x*1e-9);
    end
    
    for ii = bestFit:bestFit+numLocs-1
        fitPlot = fitPlot + lorentzian(peaksNe(ii, 2), peaksNe(ii, 1), 5, 10, x);
    end
    
%     hold on
%     plot(x, fitPlot);
%     plot(x, spectrum);
end

