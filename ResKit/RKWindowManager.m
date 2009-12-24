//
//  RKWindowManager.m
//  ResKit
//
//  Created by Jacob Bandes-Storch on 12/24/09.
//  Copyright 2009 Jacob Bandes-Storch. All rights reserved.
//

#import <CoreGraphics/CoreGraphics.h>
#import "RKWindowManager.h"

#define RKLog NSLog

// Private methods
@interface RKWindowManager ( )
- (void)repositionWindow;
@end


@implementation RKWindowManager

@synthesize scaleFactor, simulatedSize;
static RKWindowManager *sharedWindowManager = nil;

#pragma mark -
#pragma mark Setup

- (void)initialize {
	// Only allow one initialization
	if (initialized) {
		[NSException raise:NSInternalInconsistencyException
					format:
		 @"ResKit window manager %@ has already been initialized; it can only be initialized once", self];
	}
	initialized = YES;
	
	// Initialize ResKit
	appWindow = [[[UIApplication sharedApplication] keyWindow] retain];
	// TODO: [insert magic here]
	[self repositionWindow];
}

- (void)setScaleFactor:(CGFloat)sf {
	// Assert initialized
	if (!initialized) {
		[NSException raise:NSInternalInconsistencyException
					format:
		 @"ResKit window manager %@ has not been initialized; it must be initialized before use", self];
	}
	// Normal setter
	scaleFactor = sf;
	
	[self repositionWindow];
}

- (void)setSimulatedSize:(CGSize)ss {
	// Assert initialized
	if (!initialized) {
		[NSException raise:NSInternalInconsistencyException
					format:
		 @"ResKit window manager %@ has not been initialized; it must be initialized before use", self];
	}
	// Normal setter
	simulatedSize = ss;
	
	[self repositionWindow];
}

- (void)repositionWindow {
	// Resize window
	CGRect bounds = appWindow.bounds;
	bounds.size = simulatedSize;
	appWindow.bounds = bounds;
	
	// Readjust scale
	appWindow.transform = CGAffineTransformMakeScale(scaleFactor, scaleFactor);
	
	// TODO: adjust window position
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
            return sharedWindowManager;  // assignment and return on first allocation
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
