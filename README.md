# `Simple modularControl`
---

This a streamlined fork of the modularControl code. The goal here is to get your microscope up and running with minimum effort. New instruments can be easily configured and the GUI can be reconfigured as required. By design most of the back-end code is hidden from the end user, yet all the functionality of modularControl is retained.   

## Quick Links

- [Package summary](#package-summary)
- [How it works](#how-it-works)
- [Configure your microscope](#how-to-configure-your-new-microscope)
	- [Device driver](#1-write-a-driver-for-your-device)
	- [Instrument Wrapper](#2-Write-a-wrapper-for-your-driver)
	- [Initialization](#3-instrument-initialization)
	- [User Interface](#4-user-interface)
- [DAQ functions]()
- [Video]()
- [Utilities]()


---
&nbsp;
## Package summary:
A summary of the structure of this package with brief folder and file descriptors

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


---
&nbsp;
## How it works:

Here is how the default configuration can be described in blocks

![alt text](https://github.com/srivatsa-FuLab/simple_modularControl_v1.02/blob/main/how_it_works.png?raw=true)

* The instrument `driver` defines how the physical instrument data (eg. in V) can be converted to digital data and vice versa.
* The instrument `wrapper` defines how the digital data is converted to a containerized `mc_object` and vice versa.
	* For instruments that need to talk via the DAQ, the daq wrapper also takes care of multiple device synchronization (eg. synchronize counter, voltage output to piezos for a 2-D confocal scan)
* The `mc_object` contains data and all the information required for user interactivity through the GUI (eg. type of input; say x-axis, integration time, etc.)

&nbsp;

Here is how the GUI can be described in blocks

<img src="https://github.com/srivatsa-FuLab/simple_modularControl_v1.02/blob/main/how_it_works_gui.png?raw=true" width="550" height="400">

* When the GUI is started, `setupObjects.m` is exectued and all the `mc_objects` are initialized (for all connected devices). Communication channels are established and the instruments are set to their default state (defined in their respective drivers).
* Next, the user facing UI elements defined in `ScopeConfig.m` are executed and the GUI goes into standby-mode awaiting a user interaction event (i.e. a GUI callback).
* When a UI element is triggered either by a mouse click or keypress event, the callback function for that specific UI elemnt (defined in `Callbacks.m`) is executed. This callback function can be a predefined function such as confocal scan or your very own custom function __(ensure your function is in the matlab path)__.

---
&nbsp;
## How to configure your new microscope:

To build a custom GUI for your microscope, follow these steps in order

<!--- ---------------------------------------------------------------------------------------------------------- --->
&nbsp;
### _**<ins>1. Write a driver for your device</ins>**_

A driver function defines the translation of commands from the GUI into a form that can be interpreted by your device. You can think of this as the physcial hardware abstraction layer of the package.
	
* Figure out what devices are connected to your microscope (eg. Piezos, Galvos, spectrometer, etc.).
* Understand how to talk to these devices. Always check the manual or refer to the example code. Matlab instrument control app or NI-Max is a good place to test instrument control. 
* Encapsulate device communication protocol into a driver function (there are templates and some less commonly used device drivers under `mcInstruments->extras`).

__The wrapper function will use the hardware protocol defined in the driver to communicate with your device. This makes it simple to reconfigure the GUI in case the devices are disconnected and reconnnected to a different hardware port.__

 **<ins>More details on parameters defined within the included drivers:</ins>**

_For your reference (it is always a good ideal to keep your code readable!)_\
`config.kind.kind` the programatic name of the device (i.e. type of interface, physical device identifier, etc.)\
`config.kind.name` the explanatory name of the device (i.e. manufacturer, model number, etc.)

_Common Parameters_\
These paramters are device agnostic

* In a `mcAxis` type driver [i.e. for bi-directional communication; Input and Output thru DAQ]\
`config.kind.intUnits` a string representing the units that the axis uses internally (e.g. for piezos, this is volts)\
`config.kind.extUnits` a string representing the units that the user should use (e.g. for piezos, this is microns)\
`config.kind.int2extConv` conversion from internal to external units (e.g. for piezos, 0V maps to -25um, 10V maps to 25um)\
`config.kind.ext2intConv` conversion from external to internal units, this should be the inverse of `int2extConv`\
`config.kind.intRange` the range of the axis in external units (this is generated using the conversions)\
`config.kind.extRange` the range of the axis in external units (this is generated from `intRange` using the conversions)\
`config.kind.base` the value (in internal units) that the axis should seek at startup

* In a `mcInput` type driver [i.e. for Input only; eg. counter input through DAQ]\
`config.kind.extUnits` the appropriate units (no internal units are neccessary here)\
`config.kind.shouldNormalize` whether or not the measurement should be divided by the time taken to measure\
`config.kind.sizeInput` the expected size of the input (this allows other parts of the program to allocate space for the `mcInput` before the measurement has been taken for numbers, this is set to `[1 1]`; for a vector like a spectrum, this could be [512 1]).
	 
_Device specific Parameters_\
These parameters are utilized by your wrapper to figure out the hardware communication channel

* For a DAQ device\
`config.dev` a string that identifies the DAQ. Check NI-MAX for the identifier (deafult is 'Dev1' can vary if you have usbDAQ or multiple DAQs)\
`config.chn` a string that identifies the DAQ channel (eg. for analog output on daq channel-0 use 'ao0')\
`config.type` a string defining the type of DAQ channel (eg. for voltage ouput use 'Voltage')

* For a USB device (eg. newport micrometer)\
`config.port` a string that identifies the USB serial port for the micrometer controller (eg.'COM4')\
`config.addr` a string required by the newport usb controller in case multiple micrometers are connected a single usb controller (default '1')

* For a custom device\
You may have to define new parmaters for your device. See `mcInstruments->extras` for ideas.

&nbsp;

>__Note:__ The physical hardware uses *internal* units whereas the user uses *external* units. For instance, a piezo uses Volts *internally* but microns *externally*. The *external* units are defined via the anonymous function `config.kind.int2extConv` and its inverse `config.kind.ext2intConv`. For instance, for the piezos that we use in the diamond room, we convert between a 0 to 10 V range and a -25 to 25 um range. Thus,
>
>	config.kind.int2extConv =   @(x)(5.*(5 - x));\
>	config.kind.ext2intConv =   @(x)((25 - x)./5);
>
>Keep in mind that the *internal* `mcObject` variables `a.x` and `a.xt` --- the current and target positions --- use *internal* units. The *external* current and target positions can be found via `a.getX()` and `a.getXt()`.


<!--- ---------------------------------------------------------------------------------------------------------- --->
&nbsp;
### _**<ins>2. Write a wrapper for your driver</ins>**_

A wrapper is a class that utilizes the driver function to perform all communication with the device and converts runtime data into an `mc_object` container. The driver functions from step#1 are inherited as a static method within the wrapper class definition.
>__Note:__ If you are using a pre-existing wrapper, please ensure that your new driver is registered as a static method within the wrapper. Refer to comments inside the example wrappers for more details.

See below for a outline of a wrapper with a brief description of the methods (this example uses `mcaDAQ.m` which is a wrapper for the DAQ input/output instrument):
&nbsp;

```matlab
classdef mcaDAQ < mcAxis 
% Make sure that the folder name is @class_name. This folder should only contain the specific instrument driver + wrapper
% There are additional methods inherited from mcAxis that generally do not need to be modified by the user 

    methods (Static)    
   	% Here you need to register your driver functions defined in step #1
   	% There are two devices connected to the DAQ
        mc_object = piezoConfig(); %<- register the piezo driver with the wrapper
        mc_object = galvoConfig(); %<- register the galvo driver with the wrapper     
    
    methods ()  
        function Open(mc_object)  	%<- Open a communication channel with the DAQ.	
        function Close(mc_object)	%<- Close the communication channel with the DAQ.
        function Goto(mc_object, x)     %<- Communicate with the device; send x

        % EXTRA
	% This is only required for DAQ wrappers
	% required to synchronize data acquisition between multiple devices connected to the DAQ   
        function addToSession(mc_object, s)	    
```

__*WIP*__

<!--- ---------------------------------------------------------------------------------------------------------- --->
&nbsp;
### _**<ins>3. Initialization</ins>**_ 

Configure all the devices in `core->mcUserInput.m`.\
Here you can define mutiple devices that utilize the same driver and wrapper (eg. X and Y axis micrometers; X,Y and Z axis piezos; where each axis is essentially an independent device with a different hardware address/port)\ 
Add device mc_object initialization to `setupObjects.m`. This utilizes all the devices and parameters defined in `mcUserInput.m`.

<!--- ---------------------------------------------------------------------------------------------------------- --->
&nbsp;
### _**<ins>4. User interface</ins>**_ 

Add instrument elements to the UI in `ScopeConfig.m`.\
Define the actions performed by the new UI elements in `Callbacks.m`
