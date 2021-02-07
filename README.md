# `modularControl`

## To Run:
* Add `modularControl` (and subfolders) to MATLAB path.
* Run the desired function or initialize the desired class.
 * e.g. in the diamond room, run `mcDiamond`.

## Pronunciation
Most classes are prefixed with `mc` to avoid clashes with other functions. This `mc` is *obviously* pronounced `m`, `c` (`em-see`); not `Mc` (`mic`) as in `McDonalds`.

## Modularity
`modularControl` is, as the name suggests, intended to be a modular and versitile solution to data acquisition in MATLAB.

#### Background
There are two concepts that we first must introduce: behavior and identity.

* Behavior defines how something should behave, while 
* Identity separates objects of the same behavior.

In analogy, behavior is like the profession of a person, while identity separates persons of the same profession. For instance, Dr. John behaves the same as Dr. Smith because they are both medical doctors, but does not have the same identity. Dr. John would not behave or be the same as Mr. Doe, a businessman.

#### In `modularControl`
The behavior of each `mc<Classname>` is defined by the logic in the functions of the class. The identity, however is defined by what is given to the constructor of the class, which creates an object `obj` based on the provided identity:

* `obj = mc<Classname>()`,			no identity given, defaults to `obj = mc<Classname>(mc<Classname>.defaultConfig())` where `defaultConfig()` is a `static` function that returns the default config struct (see below);
* `obj = mc<Classname>(config)`,		uses the identity of the struct `config`. Fields of `config` might include `config.name` (i.e. the name of the identity), etc;
* `obj = mc<Classname>('config.mat')`,	uses the identity contained in the MATLAB file `'config.mat'` (may be buggy)

Often there are other `static` functions such as `mc<Classname>.defaultConfig()` (e.g. `mcaDAQ.piezoConfig()`) which conveniently define identity (in the form of a returned `config` struct) so that the user does not have to correctly assemble a `config` struct every time. Differences between `config`s amount to simple differences in identity. For instance, `config.chn` for a `mcaDAQ` object, the DAQ channel that the object is connected to, could be `'ao0'`, `'ao1'`, and so on.

This separation of behavior and identity means that this code is inherently modular. `mcAxis` is a class that generalizes the behavior of a 1D parameter space. The main function in `mcAxis` is `.goto(x)`, which tells the axis to goto that particular `x` value. This function can be used on a variety of real objects that behave like a 1D parameter space: linear motion for piezos, wavelength for a tunable frequency laser, etc.

## What's Up With `mca`, `mci`, etc?:
There are several parent classes that spawn a number of daughter subclasses in modular control. For clarity and organization, the daughter subclasses take the first three letters of the parent class as the prefix of thier classnames. The following is a list of classes that spawn daughters:

Class               | This Class Abstractifies...  | Subclass Prefix | Example Subclass     |
--------------------|--------------|-----------------|-----------------------|
`mcAxis`			| ...1D parameter spaces | `mca` | `mcaDAQ`|
`mcInput`			| ...measurement         | `mci` | `mciDAQ`|
`mcGUI`			| ...MATLAB GUIs | `mcg` | `mcgDiamond`|

Why was this done? Different code must be executed to interact with different devices. Attempting to contain the behavior of every axis inside a single `mcAxis` class became difficult as the number of necessary behaviors increased. The `switch` statement to deal with the different behaviors became unmanagably long. But, for compatability and *modularity* it was important to have all interactions be done through common classes and functions. Hence, `mcAxis`, `mcInput`, etc spawn a set of subclass `mca`s, `mci`s, etc that define the specific functionality. These subclasses, to reduce clutter, are stored in the subfolders of `modularControl` labeled by parent name.

How is this done? Each parent function calls (after error-checking, etc) a capitalized version of that parent function. 
Each custom subclass must 'fill in' functionality via that capitalized version.
For instance, `mciDAQ` must define `.Measure()` which is called by `.measure()`, the method that the user calls. `.measure()` is defined in the `mcInput` superclass, along with an empty version of `.Measure()`, which is 'filled in' by the subclass `mciDAQ`. Most parents have a `mc[]Template` to help with filling in the functionality; just replace the double-starred (`**`) lines.

## What's Up With `config.kind` In `mcAxes` and `mcInputs`:
`config.kind` is a rather-ambiguous structure in every `mcAxis` and `mcInput`. It was put in for organizational purposes. It contains the following fields:

#### In Both `mcAxis` and `mcInput`:
* `config.kind.kind`, the programatic name of the kind (sorry, this was due to C++ habits);
* `config.kind.name`, the explanatory name of the kind (e.g. for a later user);

#### In `mcAxis`, Specifically:
* `config.kind.intUnits`, a string representing the units that the axis uses internally (e.g. for piezos, this is volts);
* `config.kind.extUnits`, a string representing the units that the user should use (e.g. for piezos, this is microns);
* `config.kind.int2extConv`, conversion from internal to external units (e.g. for piezos, 0V maps to -25um, 10V maps to 25um);
* `config.kind.ext2intConv`, conversion from external to internal units, this should be the inverse of `int2extConv`, but is currently not error checked (check randomly in the future?);
* `config.kind.intRange`, the range of the axis in external units (this is generated using the conversions);
* `config.kind.extRange`, the range of the axis in external units (this is generated from `intRange` using the conversions);
* `config.kind.base`,	the value (in internal units) that the axis should seek at startup;

#### In `mcInput`, Specifically:
* `config.kind.extUnits`, the appropriate units (no internal units are neccessary here);
* `config.kind.shouldNormalize`, whether or not the measurement should be divided by the time taken to measure (e.g. where absolute counts are meaningless unless the time taken to collect is present; this is currently only used with `mciDAQ` devices);
* `config.kind.sizeInput`, the expected size of the input (this allows other parts of the program to allocate space for the `mcInput` before the measurement has been taken; for numbers, this is set to `[1 1]`; for a vector like a spectrum, this could be [512 1]).

It is meant to unify mcInstruments of similar, but not identical identity. For instance, all MadCity Labs piezos have the same `config.kind` because they all have the same range and convert between units with the same conversions. The only difference is the special variables (`dev` and `chn` in this case).

#### A Note About Internal vs External Units...
The physical hardware uses *internal* units whereas the user uses *external* units. For instance, a piezo uses Volts *internally* but microns *externally*. The *external* units are defined via the anonymous function `config.kind.int2extConv` and its inverse `config.kind.ext2intConv`. For instance, for the piezos that we use in the diamond room, we convert between a 0 to 10 V range and a -25 to 25 um range. Thus,

	config.kind.int2extConv =   @(x)(5.*(5 - x));
	config.kind.ext2intConv =   @(x)((25 - x)./5);

It should be noted that the *internal* `mcAxis` variables `a.x` and `a.xt` --- the current and target positions --- use *internal* units. The *external* current and target positions can be found via `a.getX()` and `a.getXt()`.

## Example
Suppose that we want to do an XY scan on the counter with the X piezo and the Y micrometer.

 1. Load the piezo:
  1. Let `configP = mcaDAQ.piezoConfig()`. This gives us the default configuration for a MadCity Piezo.
  2. By default, `configP.dev` and `configP.chn` are set to `'Dev1'` and `'ao0'`, respectively. Change these if neccessary. For instance, set `configP.chn = 'ao1'` to access the piezo on the 2nd DAQ channel.
  3. Set `configP.name` to a descriptive name in order to keep track of this axis later. e.g. `configP.name = 'Piezo X'`
  4. Set `piezo = mcaDAQ(configP)` which gives us a `mcaDAQ` object with the desired `config`. 
   1. Note that access to object pointed by `piezo` is not limited by access to the variable `piezo`. Every time an axis is initialized, it is registered with `mcInstrumentHandler` for access via the rest of the program.
   2. Note also that letting `piezo2 = mcaDAQ(configP)` will not make a new object. Instead, this will merely set `piezo2 = piezo`. `mcInstrumentHandler` makes sure there are no duplicate axes.
 2. Load the micrometer:
  1. Let `configM = mcaMicro.microConfig()`. This gives us the default configuration for a Newport Micrometer.
  2. By default, `configM.port` is set to the USB port `'COM6'`. Change this if neccessary. For instance, set `configM.port = 'COM7'` to access the micrometer connected to USB port `'COM7'`.
  3. Set `configM.name` to a descriptive name. e.g. `configP.name = 'Micro Y'`
  4. Set `micro = mcaMicro(configM)` which gives us a `mcaMicro` object with the desired `config`.
 3. Load the counter:
  1. Let `configI = mciDAQ.counterConfig()`.
  2. By default, `configI.dev` and `configI.chn` are set to `'Dev1'` and `'ctr1'`, respectively. Change these if neccessary. For instance, set `configI.chn = 'ctr2'` to access the 2nd counter channel.
  3. Set `configI.name` to a descriptive name. e.g. `configI.name = 'Counter'`
  4. Set `count = mciDAQ(configI)` which gives us a `mciDAQ` object with the desired `config`.
 4. Note that the last three steps can be streamlined by a startup script. `mcDiamond` serves this purpose for the diamond microscope and load all of the pertinant axes and inputs.
 5. Suppose that we want to do a 11x11 pixel scan from 10um to 20um with the x piezo and 20um to 30um with the y micrometer. We will use `mcData`.
  1. Set `axes_ = {piezo, micro}`. This gives `mcData` the axes we want to scan over. Note that it is also sufficient to set `axes_ = {configP, configM}` as long as `configP.class = 'mcaDAQ'` and `configM.class = 'mcaMicro'`. If you want to really be obscene, `axes_ = {piezo, configM}` is also valid.
  2. Set `scans = {linspace(10, 20, 11), linspace(20, 30, 11)}`. These vectors contain all of the points that we will scan over, with the `i`th index of this cell array corresponding to the axis of the `i`th index of the cell array `axes_`. Note that one can input pretty crazy vectors whose entries are not-neccessarily equally spaced (although this is not reccommended because the 2D imaging method assumes equal spacing; the 1D imaging method, however, should display correctly).
  3. Set `inputs = {count}`. This gives `mcData` the input that we want to measure at each point of the scan. Note specifically that more `mcInput`s can be added as additional entries of the cell array (naturally). As with axes, using the `config` instead of the `mcInput` object is sufficient.
  4. Set `integrationTime = [time]` to the time `time` (in seconds) that we want to spend at each point. `time = .09` sounds reasonable for ~1 second X scans.
  5. Now call `data = mcData(axes_, scans, inputs, integrationTime)`. This gives an `mcData` object that is ready to scan.
 6. To scan, either
  1. Acquire in the command line with `data.aquire()` (typo, I know...). Note that this provides no visual input about the progress of the scan. It also blocks the MATLAB command line. The resulting data can be accessed afterward in `data.d.data`. This will be a cell array with one entry (corresponding to the one input). This one entry will be a 11x11 numeric matrix with the `ij`th index corresponding to the result at pixel `[i, j]`, i.e. the point `[scans{1}(i), scans{2}(j)]` um.
  2. Acquire the data visually with `mcDataViewer`. Use `viewer = mcDataViewer(data)`.
 7. The function `mcScan` is a GUI which makes a `mcData` structure without having to go through the command line as in step 5. Run `mcScan` and simply select the appropriate axes/scans/etc using edit boxes and dropdown lists.

In all, we have

~~~MATLAB
% 1. Load the piezo
configP = mcaDAQ.piezoConfig();		% Make the piezo config.
configP.chn = 'ao1';
configP.name = 'Piezo X';
piezo = mcaDAQ(configP);			% Make the piezo object.
 
% 2. Load the micrometer
configM = mcaMicro.microConfig();	% Make the micrometer config.
configM.port = 'COM7';
configM.name = 'Micro Y';
micro = mcaMicro(configM);			% Make the micrometer object.
 
% 3. Load the counter
configI = mciDAQ.counterConfig();
configI.chn = 'ctr2';
configI.name = 'Counter';
count = mciDAQ(configI);

% 5. Setup the mcData structure (which will aquire the data)
axes_ = {piezo, micro};
scans = {linspace(10, 20, 11), linspace(20, 30, 11)};
inputs = {count};
integrationTime = [.09];
data = mcData(axes_, scans, inputs, integrationTime);

% 6.1. Aquire the data programmatically
data.aquire();
disp(data.d.data);					% Print the data in the console.

% 6.2. Aquire the data via GUI
data.reset();							% Reset the previous aquisition.
viewer = mcDataViewer(data);

~~~

## Future (Incomplete List)

### High Priority:

- [x] Make sure loading and saving configs/data is functional.
- [ ] Make sure that `mcData` works in all situations (e.g. different configurations of axes and inputs).
- [ ] Polish `mcExperiment` stuff.
- [ ] Commenting!

### Low Priority:

- [ ] 3D and Scatter modes for `mcDataViewer`.
- [ ] Sine scan on all `mcAxes` (useful for alignment).
- [x] Fix current_position updating in mcWaypoints (currently disabled for performance).
- [ ] Streamline the grid-creation process.
- [ ] Fix cross-platform UI issues, especially in `mcScan` and `mcData` (`uitabgroup` issues).
- [ ] Make tabbing in `mcUserInput` go to the next textbox, instead of button.
- [ ] Make sure the `mcAxis` and `mcInput` error-check properly.
- [x] Make `mcAxis` recognize `NaN` as the 'don't do anything' base.
- [ ] Finish `uicontrol` registration to turn off controls when the assigned axis is in use.
- [ ] Add exposure adjustment(/etc) controls to `mcVideo`.
- [ ] Properly debug (e.g. PID loop settings) image feedback in `mcVideo`.
- [ ] Make a GUI for loaded instruments (`uitable`?).
- [ ] Add ungrouped axis controls to `mcUserInput`.
- [ ] Fix mcData return to position when unpausing scan.








