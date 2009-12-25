//
//	RKWindowManager.m
//	ResKit
//
//	Created by Jacob Bandes-Storch on 12/24/09.
//	Copyright 2009 Jacob Bandes-Storch. All rights reserved.
//

#import <CoreGraphics/CoreGraphics.h>
#import "RKWindowManager.h"
#import "RKWindow.h"

#define RKLog NSLog

// Private methods
@interface RKWindowManager ( )
- (void)repositionWindow;
@end


@implementation RKWindowManager

@synthesize scaleFactor, simulatedSize;
static RKWindowManager *sharedWindowManager = nil;

- (id)init {
	if (self = [super init]) {
		// Observe changes to assert 
		[self addObserver:self
			   forKeyPath:@"scaleFactor"
				  options:0
				  context:NULL];
		[self addObserver:self
			   forKeyPath:@"simulatedSize"
				  options:0
				  context:NULL];
	}
	return self;
}


#pragma mark -
#pragma mark Setup

- (void)observeValueForKeyPath:(NSString *)keyPath
					  ofObject:(id)object
						change:(NSDictionary *)change
					   context:(void *)context {
	// Assert initialization before properties can be changed
	if (!initialized) {
		[NSException raise:NSInternalInconsistencyException
					format:@"Attempt to change %@ before initializing ResKit window manager %@", keyPath, self];
	}
	
	// Adjust display based on new property values
	[self repositionWindow];
}

- (void)initialize {
	// Only allow one initialization
	if (initialized) {
		[NSException raise:NSInternalInconsistencyException
					format:@"ResKit window manager %@ has already been initialized", self];
	}
	initialized = YES;
	
	// Initialize ResKit
	appWindow = [[[UIApplication sharedApplication] keyWindow] retain]; // The main application window being tested
	// Create the window which is used to intercept touches
	resKitWindow = [[RKWindow alloc] initWithFrame:[UIScreen mainScreen].bounds];
	[resKitWindow makeKeyAndVisible];
	
	// It appears that the window's initial frame
	// isn't actually [UIScreen mainScreen].applicationFrame, it's the full bounds...
	
	// Start with the device's normal size
	scaleFactor = 1.0;
	simulatedSize = [UIScreen mainScreen].bounds.size;
	
	// TODO: [insert magic here]
	[self repositionWindow];
}

- (void)repositionWindow {
	[UIView beginAnimations:nil context:NULL]; // A nice transition
	
	// Resize window
	CGRect bounds = appWindow.bounds;
	bounds.size = simulatedSize;
	appWindow.bounds = bounds;
	
	// Readjust scale
	appWindow.transform = CGAffineTransformMakeScale(scaleFactor, scaleFactor);
	
	// TODO: adjust window position
	
	[UIView commitAnimations];
}

- (void)dealloc {
	// We won't actually get deallocated (singleton), but it's good practice...
	[appWindow release];
	[super dealloc];
}

#pragma mark -
#pragma mark Singleton pattern methods

+ (RKWindowManager *)sharedManager {
	@synchronized(self) {
		if (sharedWindowManager == nil) {
			[[self alloc] init]; // assignment not done here
		}
	}
	return sharedWindowManager;
}
+ (id)allocWithZone:(NSZone *)zone {
	@synchronized(self) {
		if (sharedWindowManager == nil) {
			sharedWindowManager = [super allocWithZone:zone];
			return sharedWindowManager;	 // assignment and return on first allocation
		}
	}
	return nil; //on subsequent allocation attempts return nil
}
- (id)copyWithZone:(NSZone *)zone { return self; }
- (id)retain { return self; }
- (NSUInteger)retainCount {
	return NSUIntegerMax;  //denotes an object that cannot be released
}
- (void)release { /* do nothing */ }
- (id)autorelease { return self; }

@end
