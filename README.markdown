# ResKit
A library for testing resolution-independent iPhone OS applications.

ResKit simulates varying device screen sizes by resizing and moving your application's main window. It supports scaling down the simulated device so more of the screen can be seen at once.

## Installation
To use ResKit, you must:

- Build the ResKit target which will create `libResKit.a`.
- Include `libResKit.a` and `RKWindowManager.h` in your project (also include the images `reskit-bezel.png` and `reskit-home.png` if you want to use the fake bezel).
- Initialize the ResKit window manager , and set the desired simulated screen size (see example below).

For example, to start ResKit with an 800x600 screen at 50% zoom:

    - (void)applicationDidFinishLaunching:(UIApplication *)application {
	    // ...
        [[RKWindowManager sharedManager] initialize];
        [RKWindowManager sharedManager].simulatedSize = CGSizeMake(800, 600);
        [RKWindowManager sharedManager].scaleFactor = 0.5;
    }

## Usage
After ResKit is initialized, it will take over the application's main window and place it in a simulated device at the specified screen size. To move this device around and scale it, put the application into "ResKit mode" by tapping with three fingers (on the simulator, click in the very upper left corner of the screen, just below the status bar). Then use one finger to move the device, two to zoom, and another three-finger tap to return to the normal mode where you can interact with your application.

## "It Broke"
If something strange happens, it's entirely possible you found a bug in ResKit. ResKit makes use of various tricks and hacks to get UIKit working properly in a transformed and repositioned window. If you do find a bug, please [report it](reskit/issues) with all the necessary information to reproduce it.
