classdef mciPLE < mcInput
% mciPLE takes one PLE scan when .measure() is called. Use mcData to take many PLE scans (e.g. mciPLE vs Time). Use mcePLE for
% automated PLE scans (taking spectrum first and aligning the laser with the ZPL in the spectrum).

    methods (Static)
        % Neccessary extra vars:
        %  - axes.red
        %  - axes.green
        %  - counter
        %  - xMin
        %  - xMax
        %  - upPixels
        %  - upTime
        %  - downTime
        
        function config = defaultConfig()
            config = mciPLE.PLEConfig(0, 3, 240, 10, 1);
        end
        function config = PLEConfig(xMin, xMax, upPixels, upTime, downTime)
            config.class = 'mciPLE';
            
            config.name = 'PLE with NFLaser';

            config.kind.kind =          'PLE';
            config.kind.name =          'PLE with NFLaser';
            config.kind.extUnits =      'photons / bin';          % 'External' units.
            config.kind.shouldNormalize = true;             % If this variable is flagged, the measurement is subtracted from the previous and is divided by the time spent on a pixel. Not that this is done outside the measurement currently in mcData (individual calls to .measure() will not have this behavior currently)
            
%             config.axes.red =       mcaNFLaser();
            
%             greenConfig =           mcaDAQ.digitalConfig(); 
%             greenConfig.dev =       'Dev1';
%             greenConfig.chn =       'Port0/Line1';
%             config.axes.green =     mcaDAQ(greenConfig);

%             greenConfig =           mcaDAQ.analogConfig(); 
%             greenConfig.chn =       'ao3';
%             config.axes.green =     mcaDAQ(greenConfig);

            config.axes.red =       mcaDAQ.redConfig();
            config.axes.green =     mcaDAQ.greenConfig();
            
            config.counter =        mciDAQ.counterConfig();
            
%             xMin
%             xMax
            
            % Error checks on xMin and xMax:
            if xMin > xMax
                temp = xMin;
                xMin = xMax;
                xMax = temp;
                warning('mciPLE.PLEConfig(): xMin > xMax! Switching them.');
            end
            
            if xMin == xMax
                error('mciPLE.PLEConfig(): xMin == xMax! Cannot scan over zero range.');
            end
            
            m = min(config.axes.red.kind.intRange);
            M = max(config.axes.red.kind.intRange);
            
            if m > xMin
                xMin = m;
                warning('mciPLE.PLEConfig(): xMin below range of red freq axis.')
            end
            if M < xMax
                xMax = M;
                warning('mciPLE.PLEConfig(): xMax above range of red freq axis.')
            end
            
            if m > xMax
                error('mciPLE.PLEConfig(): xMax out of range');
            end
            if M < xMin
                error('mciPLE.PLEConfig(): xMin out of range');
            end
            
            config.xMin =       xMin;
            config.xMax =       xMax;
            
            % Error checks on upTime and downTime
            if upTime == 0
                error('mciPLE.PLEConfig(): upTime is zero! We will never get there on time...');
            elseif upTime < 0
                upTime = -upTime;
            end
            if downTime == 0
                error('mciPLE.PLEConfig(): downTime is zero! We will never get there on time...');
            elseif downTime < 0
                downTime = -downTime;
            end
            
            config.upTime =    upTime;
            config.downTime =  downTime;
            
            config.upPixels =   upPixels;
            config.downPixels = round(upPixels*downTime/upTime);
            
%             s = upPixels + config.downPixels
            config.kind.sizeInput =    [upPixels + config.downPixels, 1];
%             config.kind
            

            disp('Please note that 16 scans will be taken at each pixel (undocumented feature)');
            config.scansPerBin = 16;        % Bins per scan
            b = config.scansPerBin;
            config.output = [[linspace(xMin, xMax, b*upPixels) linspace(xMax, xMin, b*config.downPixels + 1)]' [zeros(1, b*upPixels) ones(1, b*config.downPixels) 0]'];    % One extra point for diff'ing.
            config.xaxis =  linspace(xMin, xMax + (xMax - xMin)*config.downPixels/upPixels, upPixels + config.downPixels);  % x Axis with fake units

        end
    end
    
    methods
        function I = mciPLE(varin)
            I.extra = {'xMin', 'xMax', 'upPixels', 'upTime'};
            if nargin == 0
                I.construct(I.defaultConfig());
            else
                I.construct(varin);
            end
            I = mcInstrumentHandler.register(I);
        end
        
%         function axes_ = getInputAxes(I)
%             axes_ = {I.config.xaxis};
%         end
    end
    
    % These methods overwrite the empty methods defined in mcInput. mcInput will use these. The capitalized methods are used in
    %   more-complex methods defined in mcInput.
    methods
        function scans = getInputScans(I)
            scans = {I.config.xaxis};
        end
        
        function units = getInputScanUnits(~)
            units = {'V'};
        end
        
        % EQ
        function tf = Eq(I, b)  % Check if a foriegn object (b) is equal to this input object (a).
            tf = strcmpi(I.config.axes.red.name,    b.config.axes.red.name) && ... % ...then check if all of the other variables are the same.
                 strcmpi(I.config.axes.green.name,  b.config.axes.green.name) && ...
                 I.config.xMin == b.config.xMin && ...
                 I.config.xMax == b.config.xMax && ...
                 I.config.upPixels ==   b.config.upPixels && ...
                 I.config.downPixels == b.config.downPixels && ...
                 I.config.upTime ==     b.config.upTime && ...
                 I.config.downTime ==   b.config.downTime;
        end
        
        % NAME
        function str = NameShort(I)
            str = [I.config.name ' (' num2str(I.config.upPixels) ' pix and '  num2str(I.config.upTime) ' sec up; '  num2str(I.config.downTime) ' sec down; from '  num2str(I.config.xMin) ' to '  num2str(I.config.xMax) ' V)'];
        end
        function str = NameVerb(I)
            str = I.NameShort();
            %[I.config.name ' (with red laser ' I.config.axes.red.name() ' and green laser ' I.config.axes.green.name() ')'];
        end
        
        % OPEN/CLOSE
        function Open(I)
%             I.config.axes.red.open();
            I.s = daq.createSession('ni');
            
            c = mciDAQ(I.config.counter);
            c.addToSession(I.s);
            
            r = mcaDAQ(I.config.axes.red);
            r.addToSession(I.s);
            g = mcaDAQ(I.config.axes.green);
            g.addToSession(I.s);
            
            if ~isfield(I.config, 'scansPerBin')
                I.config.scansPerBin = 1;
            end
            
%             r = I.config.scansPerBin*I.config.upPixels/I.config.upTime;
            I.s.Rate = I.config.scansPerBin*I.config.upPixels/I.config.upTime;
        end
        function Close(I)
%             I.config.axes.red.close();
                
%                 %reset lasers
%                 upscan = [[0]' [0]']; 
%                 I.s.queueOutputData(upscan);
%                 [d, t] = startForeground(I.s);  % Fix timing?
                
            release(I.s);
        end
        
        % MEASURE
        function data = MeasureEmulation(I, ~)
%             I.config.upPixels
%             I.config.downPixels
            data = [3+rand(I.config.upPixels, 1); 10+2*rand(I.config.downPixels, 1)];
%             size(data)
%             t = I.config.upTime + I.config.downTime
            pause(I.config.upTime + I.config.downTime);
        end
        function data = Measure(I, ~)
            
         b = I.config.scansPerBin;
         
            %Run the forward scan
                upscan = [[linspace(I.config.xMin, I.config.xMax, b*I.config.upPixels+1) ]' [zeros(1, b*I.config.upPixels+1)]'];    % One extra point for diff'ing.
                I.s.queueOutputData(upscan);
                [d, t] = startForeground(I.s);  % Fix timing?


               % data1 = (diff(d)./diff(t))'; %cts/s
                data1 = diff(d)'; %raw photon numbers

                l = length(data1);

                %data = zeros(1, I.config.upPixels + I.config.downPixels);
                data = zeros(1, I.config.upPixels);

                for ii = 1:I.config.scansPerBin
                    data = data + data1(ii:I.config.scansPerBin:l);
                end
            
            %Check if the data shows a PLE line
            
                ple_mean = mean(data);
                if (I.config.xMax-I.config.xMin) < 2 
                    %threshold for fine scan
                    ple_thresh = 12; %was 3.5*ple_mean
                else
                    %threshold for coarse scan
                    ple_thresh =45;%2.2*ple_mean; %was 2.5
                end
            
%                 %unconditional green repump
%                  green = ones(1, b*I.config.downPixels);
                
                %Conditional green repump
                [m,i]=max(data);
                up_volts=linspace(I.config.xMin, I.config.xMax, I.config.upPixels);
                
                if m>ple_thresh
                    fprintf('Found line \t Peak=%d Pos=%1.2fV \n',m, up_volts(i))
                    green = zeros(1, b*I.config.downPixels);
                else
%                     if (I.config.xMax-I.config.xMin) <2.5
%                         coin_flip = (randi(4)>3);
%                         %fprintf('Coin flip = %d \n', coin_flip);
%                         green = ones(1, b*I.config.downPixels)*coin_flip; %coin flip                       
%                     else
%                         coin_flip = (randi(3)>1);
%                         green = ones(1, b*I.config.downPixels)*coin_flip; %coin flip   
                        green = ones(1, b*I.config.downPixels); %coin flip
% %                     end
                end
                
            I.Close %weird issue with daq fixed temporarily with reset            
            I.Open
            
            God = mcaDAQ( mcaDAQ.greenOD2Config());
            
            %run the backscan
                downscan = [[linspace(I.config.xMax, I.config.xMin, b*I.config.downPixels + 1)]' [green 0]'];    % One extra point for diff'ing.
                I.s.queueOutputData(downscan);
                
                %switch the green OD
%                 God.goto(1);
%                 pause(0.1)
%                 God.goto(0);
                
                [d, t] = startForeground(I.s);  % Fix timing?

                data2 = diff(d)'; %raw photon numbers

                l = length(data2);

                %data = zeros(1, I.config.upPixels + I.config.downPixels);
                data_down = [zeros(1, I.config.downPixels)];

                for ii = 1:I.config.scansPerBin
                    data_down = data_down + data2(ii:I.config.scansPerBin:l);
                end
            
            %make output array
                data = [data data_down];
                data(I.config.upPixels + 1) = NaN;
            
            %switch the green OD
%                 God.goto(1);
%                 pause(0.1)
%                 God.goto(0);
                
            %clean up  
            I.close();  % Inefficient, but otherwise mciPLE never gives the counter up...
            
%             %%------------------------------------------------
%             %PID Stabilization code
%             %Srivatsa 2/18/2019
%             
%             %User paramters-----------------------------------
%             %k_StarkTune=30;
%             %PID parameters
%             Kp = 0.8;             %Proportional constant
%             Ki = Kp/500;          %Integral constant
%             Kd = Kp/10;           %Derivative constant
%             volt_resp = 100;  %Calculated from PLE data (applied bias votage per 10GHz shift)
%             
%             %Starting voltage
%             initial_voltage = 15; 
%             %-------------------------------------------------
%             
%             %First find the PLE peak
%             [peak_curr, ~]=find_ple_peak(I.config.xaxis, data(1:I.config.upPixels));
%             
%             %Check if peak is found
%             if (~isnan(peak_curr))
%                 
%                 %Read previous peak from file
%                 ple_file        = csvread('C:\Users\Tomasz\Desktop\stark_ple_2019\ple_peak_fit.csv');
%                % peak_prev       = ple_file(1,end);
%                 currentVoltage  = ple_file(2,end);
%                 integral        = ple_file(3,end);
%                 derivative      = ple_file(4,end);
%                 
%                 scans           = size(ple_file(1,:),2);
%                 
%                 %Initialize voltage source
%                 volts = mcaDAQ(mcaDAQ.PIE616Config());
%                     
%                 %Feedback Loop
%                 if scans==1
%                         %Goto initial voltage
%                         currentVoltage = initial_voltage;
%                         error = 0;
%                         integral = 0;
%                         derivative = 0;
%                         
%                 elseif scans==2 
%                         %Only proportional control
%                         initialPeak = ple_file(1,1);
%                         
%                         %calculate error (delta_lambda)
%                         error = initialPeak-peak_curr;                        
%                         
%                         integral = 0;
%                         derivative = 0;
%                         
%                 elseif scans>2    
%                         %Calculate all PID terms
%                         
%                         initialPeak = ple_file(1,1);
%                         
%                         %calculate error (delta_lambda)
%                         error = initialPeak-peak_curr;
%                         
%                         %Integral term
%                         oldVoltage = ple_file(2,end-1);
%                         dV = abs(currentVoltage-oldVoltage);
%                         integral = integral + error*dV;  
%                         
%                         %Derivative term
%                         if dV>0
%                             derivative = (error - old_error)/dV; 
%                         else
%                             derivative=0;
%                         end
% 
%                         
%                 end
%                 
%                 %Calculate New voltage
%                 pixToCor=(Kp*error + Ki*integral + Kd*derivative);
%                 newVoltage = currentVoltage + pixToCor*volt_resp;
% 
%                 %Goto new voltage
%                 volts.goto(newVoltage);
%   
%                 
% %                     V_new=V_prev+k_StarkTune*(peak_curr-peak_prev);
% %                     volts = mcaDAQ(mcaDAQ.PIE616Config());
% %                     volts.goto(V_new);
% %                     
% %                 else
% %                     V_new=V_prev;
% %                 end
%  
% 
%                 %Update 
%                 fprintf('Old Bias = %2.2f \t New Bias = %2.2f\n',currentVoltage, newVoltage);
%                 
%                 %Always write current peak to file
%                 csvwrite('C:\Users\Tomasz\Desktop\stark_ple_2019\ple_peak_fit.csv',[ple_file,[peak_curr; newVoltage; integral; derivative]]); 
%             end
        end
    end
end




