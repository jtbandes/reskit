# ResKit
A library for testing resolution-independent iPhone OS applications.

## Usage
To use ResKit, you must:

- Include libResKit.a in your application.
- Initialize the ResKit window manager.
- Set the desired simulated screen size.

For example, to start ResKit with an 800x600 screen at 50% zoom:

    - (void)applicationDidFinishLaunching:(UIApplication *)application {
	    // ...
        [[RKWindowManager sharedManager] initialize];
        [RKWindowManager sharedManager].simulatedSize = CGSizeMake(800, 600);
        [RKWindowManager sharedManager].scaleFactor = 0.5;
    }
