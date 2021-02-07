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
	* @mcaDAQ	DAQ output devices
	
		*       mcaDAQ.m		Wrapper __[Do not modify!]__
		*       piezoConfig.m		Piezo driver
		*       galvoConfig.m		Galvo driver
		*       analogConfig.m 		[template]
		*       digitalConfig.m		[template]	
	
	* @mciDAQ	DAQ input devices
	
		*       mciDAQ.m		Wrapper __[Do not modify!]__
		*       counterConfig.m		Counter input driver
		*       digitalConfig.m		[template]
		*       voltageConfig.m		[template]
		
	* @mcaMicro
		*       mcaMicro.m		Wrapper __[Do not modify!]__
		*       microConfig.m		Micrometer driver

	* extra					other unused device drivers and configurations


* configs		During runtime, a GUI configuration is created and stored in this folder
* core			__[Do not modify!]__
* mcJoystick		Joystick functionality
* mcVideo		Interface to microscope live camera
* user_data		Your data can be organized here
* utility scripts 	Additional scripts that are used by the package such as peakfinder, etc.
</pre>

## How it works
![alt text](https://github.com/srivatsa-FuLab/simple_modularControl_v1.02/blob/main/how_it_works.png?raw=true)

* The instrument `driver` defines how the physical instrument data (eg. in V) can be converted to digital data and vice versa.
* The instrument `wrapper` defines how the digital data is converted to a containerized mc_object and vice versa.
	* For instruments that need to talk via the DAQ, the daq wrapper also takes care of multiple device synchronization (eg. synchronize counter, voltage output to piezos for a 2-D confocal scan)
* The mc_object contains data and all the information required for user interactivity through the GUI

![alt text](https://github.com/srivatsa-FuLab/simple_modularControl_v1.02/blob/main/how_it_works_gui.png?raw=true)


## How to configure a new microscope
WIP
