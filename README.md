# `Simple modularControl`
This a streamlined fork of the modularControl code. The goal here is to get your microscope up and running with minimum effort. New instruments can be easily configured and the GUI can be reconfigured as required. By design most of the back-end code is hidden from the end user, yet all the functionality of modularControl is retained.   

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

## How it works:

Here is how the default configuration can be described in blocks
![alt text](https://github.com/srivatsa-FuLab/simple_modularControl_v1.02/blob/main/how_it_works.png?raw=true)

* The instrument `driver` defines how the physical instrument data (eg. in V) can be converted to digital data and vice versa.
* The instrument `wrapper` defines how the digital data is converted to a containerized `mc_object` and vice versa.
	* For instruments that need to talk via the DAQ, the daq wrapper also takes care of multiple device synchronization (eg. synchronize counter, voltage output to piezos for a 2-D confocal scan)
* The `mc_object` contains data and all the information required for user interactivity through the GUI (eg. type of input; say x-axis, integration time, etc.)

Here is how the GUI can be described in blocks

<img src="https://github.com/srivatsa-FuLab/simple_modularControl_v1.02/blob/main/how_it_works_gui.png?raw=true" width="600" height="400">


## How to configure a new microscope:

To build a custom GUI for your microscope, follow these steps in order

#### 1. Write a driver for your device
A driver function defines the translation of commands from the GUI into a form that can be interpreted by your device. You can think of this as the physcial hardware abstraction layer of the package.
	
* Figure out what devices are connected to your microscope (eg. Piezos, Galvos, spectrometer, etc.).
* Understand how to talk to these devices. Always check the manual or refer to the example code. Matlab instrument control app or NI-Max is a good place to test instrument control. 
* Encapsulate device communication into a driver function (there are templates and some less commonly used device drivers under `mcInstruments->extras`).

<pre>
More details on parameters defined within the included drivers:

__For your reference (it is always a good ideal to keep your code readable!)__
`config.kind.kind`, the programatic name of the kind (i.e. type of interface, physical device identifier, etc.)
`config.kind.name`, the explanatory name of the kind (i.e. manufacturer, model number, etc.)

__Common Parameters__
Device agnostic

* In a `mcAxis` type driver [i.e. for bi-directional communication; Input and Output thru DAQ]
`config.kind.intUnits` a string representing the units that the axis uses internally (e.g. for piezos, this is volts)
`config.kind.extUnits` a string representing the units that the user should use (e.g. for piezos, this is microns)
`config.kind.int2extConv` conversion from internal to external units (e.g. for piezos, 0V maps to -25um, 10V maps to 25um)
`config.kind.ext2intConv` conversion from external to internal units, this should be the inverse of `int2extConv'
`config.kind.intRange` the range of the axis in external units (this is generated using the conversions)
`config.kind.extRange` the range of the axis in external units (this is generated from `intRange` using the conversions)
`config.kind.base` the value (in internal units) that the axis should seek at startup

* In a `mcInput` type driver [i.e. for Input only; eg. counter input through DAQ]
`config.kind.extUnits` the appropriate units (no internal units are neccessary here)
`config.kind.shouldNormalize` whether or not the measurement should be divided by the time taken to measure 
	(e.g. where absolute counts are meaningless unless the time taken to collect is present)
`config.kind.sizeInput` the expected size of the input
	(this allows other parts of the program to allocate space for the `mcInput` before the measurement has been
	 taken for numbers, this is set to `[1 1]`; for a vector like a spectrum, this could be [512 1]).
	 
__Devie specific Parameters__
These parameters are utilized by your wrapper to figure out the hardware communication channel

* For a DAQ device
`config.dev` a string that identifies the DAQ. Check NI-MAX for the identifier if you have multiple DAQs (deafult is 'Dev1')
`config.chn` a string that identifies the DAQ channel (eg. for analog output on daq channel-0 use 'ao0')
`config.type` a string defining the type of DAQ channel (eg. for voltage ouput use 'Voltage')

* For a USB device (eg. newport micrometer)
`config.port` a string that identifies the USB serial port for the micrometer controller (eg.'COM4')
`config.addr` a string required by the newport usb controller to account for multiple micrometers connected to a single usb controller (default '1')

* For a custom device
You may have to define new parmaters for your device. See `mcInstruments->extras` for ideas.

</pre>

>__Note:__ The physical hardware uses *internal* units whereas the user uses *external* units. For instance, a piezo uses Volts *internally* but microns *externally*. The *external* units are defined via the anonymous function `config.kind.int2extConv` and its inverse `config.kind.ext2intConv`. For instance, for the piezos that we use in the diamond room, we convert between a 0 to 10 V range and a -25 to 25 um range. Thus,
>
>	config.kind.int2extConv =   @(x)(5.*(5 - x));
>	config.kind.ext2intConv =   @(x)((25 - x)./5);
>
>It should be noted that the *internal* `mcObject` variables `a.x` and `a.xt` --- the current and target positions --- use *internal* units. The *external* current and target positions can be found via `a.getX()` and `a.getXt()`.

#### 2. Write a wrapper for your driver
A wrapper is a class that utilizes the driver function to perform all communication with the device and converts runtime data into an `mc_object` container. The driver functions from step-(1) are inherited as a static method within the wrapper class definition.
>__Note:__ If you are using a pre-existing wrapper, please ensure that your new driver is registered as a static method within the wrapper. Refer to comments inside the example wrappers for more details.

----
WIP
#### 3. Add device mc_object initialization to setupObjects

#### 4. Add instrument elements to the UI (ScopeConfig.m)

#### 5. Define the actions performed by the new UI elements
