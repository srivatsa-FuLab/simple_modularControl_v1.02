# `Simple modularControl`
This a simplified fork of the modularControl code. The goal here is to get your microscope up and running with minimum effort. New instruments can be easily configured and the GUI can be reconfigured as required. By design most of the back-end code is hidden from the end user, yet all the functionality of modularControl is retained.   

## Package structure:

<pre>
* mcScope.m		`This is the main function that runs the package`

* @mcgScope
	*       mcgScope.m			Wrapper __[Do not modify!]__
	*       ScopeConfig.m			The GUI elements are defined here (Galvo scan, Piezo scan, optimize, etc.)
	*       Callbacks.m			Define what action the GUI elements perform
	*       setupObjects.m			Ensure the GUI can interface with the instruments


* mcInstruments
	*   	@mcaDAQ				DAQ output devices
		*       mcaDAQ.m		Wrapper __[Do not modify!]__
		*       piezoConfig.m		Piezo driver
		*       galvoConfig.m		Galvo driver
		*       analogConfig.m 		[template]
		*       digitalConfig.m		[template]	
		
	*		@mcaMicro
		*       mcaMicro.m		Wrapper __[Do not modify!]__
		*       microConfig.m		Micrometer driver

	*   	@mciDAQ				DAQ input devices
		*       mciDAQ.m		Wrapper __[Do not modify!]__
		*       counterConfig.m		Counter input driver
		*       digitalConfig.m		[template]
		*       voltageConfig.m		[template]

	* extra					other unused device drivers and configurations


* configs		During runtime, a GUI configuration is created and stored in this folder
* core			__[Do not modify!]__
* mcJoystick		Joystick functionality
* mcVideo		Interface to microscope live camera
* user_data		Your data can be organized here
* utility scripts 	Additional scripts that are used by the package such as peakfinder, etc.
</pre>

## How to configure a new microscope
WIP
