%Old princeton spectrometer
%Talk via python matlab handshake (via. network file drop)

function config = pyWinSpecConfig()
	config.class =              'mciSpectrum';
	
	config.name =               'Spectrometer';

	config.kind.kind =          'pyWinSpectrum';
	config.kind.name =          'Default Spectrum Input';
	config.kind.extUnits =      'cts';                  % 'External' units.
	config.kind.normalize =     false;                  % Should we normalize?
	config.kind.sizeInput =     [1 512];                 % This input returns a vector, not a number...
	
	config.triggerfile =        'Z:\Winspec\matlabfile.txt';
	config.datafile =           'Z:\spec.SPE';
end