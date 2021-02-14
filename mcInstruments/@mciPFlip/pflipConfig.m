%Example for making a virtual device by combining two hardware devices
%Here the flip mirror connected via DAQ is combined with the GPIB Newport powermeter

function config = pflipConfig()
	config.class = 'mciPFlip';
	
	config.name = 'Powermeter';
	
	config.power =  mciNIGPIB();
	
	flipConfig =        mcaDAQ.digitalConfig();
	flipConfig.chn = 	'Port0/Line1';
	flipConfig.name = 	'Flip Mirror';
	config.flip =       mcaDAQ(flipConfig);

	config.kind.kind =          'mciPFlip';
	config.kind.name =          'Interjecting Powermeter';
	config.kind.extUnits =      config.power.config.kind.extUnits; % 'External' units.
	config.kind.shouldNormalize = false;                    % If this variable is flagged, the measurement is subtracted from the previous and is divided by the time spent on a pixel. Not that this is done outside the measurement currently in mcData (individual calls to .measure() will not have this behavior currently)
	config.kind.sizeInput =     config.power.config.kind.sizeInput;
end