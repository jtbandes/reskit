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
		
		touchOrigins = [[NSMutableDictionary alloc] init];
	}
	return self;
}


#pragma mark -
#pragma mark Setup

- (void)observeValueForKeyPath:(NSString *)keyPath
					  ofObject:(id)object
						change:(NSDictionary *)change
					   context:(void *)context {
	if (object == self) {
		// Assert initialization before properties can be changed
		if (!initialized) {
			[NSException raise:NSInternalInconsistencyException
						format:@"Attempt to change %@ before initializing ResKit window manager %@", keyPath, self];
		}
		
		// Adjust display based on new property values
		[self repositionWindow];
	}
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
	appWindow.windowLevel = UIWindowLevelAlert;
	// Create the window which is used to intercept touches
	resKitWindow = [[RKWindow alloc] initWithFrame:[UIScreen mainScreen].bounds];
	resKitWindow.windowManager = self;
	//resKitWindow.windowLevel = UIWindowLevelAlert;
	resKitWindow.backgroundColor = [UIColor blackColor]; // This allows touches outside the app window
	[resKitWindow makeKeyAndVisible];
	[appWindow removeFromSuperview];
	
	// It appears that the window's initial frame
	// isn't actually [UIScreen mainScreen].applicationFrame, it's the full bounds...
	
	// TODO: support initializing in landscape
	
	// Start with the device's normal size
	scaleFactor = 1.0;
	simulatedSize = [UIScreen mainScreen].bounds.size;
	
	// TODO: [insert more magic here]
	
	[self repositionWindow];
}

#pragma mark -
#pragma mark Event handling

- (void)touchesBegan:(NSSet *)touches withEvent:(UIEvent *)event {
	for (UITouch *touch in touches) {
		[touchOrigins setObject:[NSValue valueWithCGPoint:[touch locationInView:nil]]
						 forKey:[NSValue valueWithNonretainedObject:touch]];
	}
	if ([touchOrigins count] != 2) zooming = NO;
}

- (void)touchesMoved:(NSSet *)touches
		   withEvent:(UIEvent *)event {
	if ([touchOrigins count] == 2) {
		NSArray *ta = [[event allTouches] allObjects];
		UITouch *t1 = [ta objectAtIndex:0];
		UITouch *t2 = [ta objectAtIndex:1];
		CGPoint t1o = [[touchOrigins objectForKey:[NSValue valueWithNonretainedObject:t1]] CGPointValue];
		CGPoint t2o = [[touchOrigins objectForKey:[NSValue valueWithNonretainedObject:t2]] CGPointValue];
		CGPoint t1p = [t1 locationInView:nil];
		CGPoint t2p = [t2 locationInView:nil];
		
		// Calculate the current and original distance between touches
		CGFloat ox = t2o.x - t1o.x;
		CGFloat oy = t2o.y - t1o.y;
		CGFloat originalDistance = sqrt(ox*ox + oy*oy);
		
		CGFloat px = t2p.x - t1p.x;
		CGFloat py = t2p.y - t1p.y;
		CGFloat newDistance = sqrt(px*px + py*py);
		
		if (abs(newDistance - originalDistance) > 10 && !zooming) {
			zooming = YES;
			zoomStartScale = scaleFactor;
			// Reset origins for smooth transition into zooming
			[touchOrigins setObject:[NSValue valueWithCGPoint:[t1 locationInView:nil]]
							 forKey:[NSValue valueWithNonretainedObject:t1]];
			[touchOrigins setObject:[NSValue valueWithCGPoint:[t2 locationInView:nil]]
							 forKey:[NSValue valueWithNonretainedObject:t2]];
		} else if (zooming) {
			CGFloat scale = zoomStartScale * newDistance / originalDistance;
			if (scale > 1) scale = 1;
			if (scale < 0.05) scale = 0.05;
			self.scaleFactor = scale;
			return;
		}
	}
	UITouch *t = [touches anyObject];
	CGPoint center = appWindow.center;
	CGPoint loc = [t locationInView:nil];
	CGPoint prevLoc = [t previousLocationInView:nil];
	center.x += loc.x - prevLoc.x;
	center.y += loc.y - prevLoc.y;
//	// Limit to edges
//	if (center.x > appWindow.bounds.size.width*scaleFactor/2) center.x = appWindow.bounds.size.width*scaleFactor/2;
//	if (center.x < resKitWindow.bounds.size.width - appWindow.bounds.size.width*scaleFactor/2)
//		center.x = resKitWindow.bounds.size.width - appWindow.bounds.size.width*scaleFactor/2;
//	if (center.y > appWindow.bounds.size.height*scaleFactor/2) center.y = appWindow.bounds.size.height*scaleFactor/2;
//	if (center.y < resKitWindow.bounds.size.height - appWindow.bounds.size.height*scaleFactor/2)
//		center.y = resKitWindow.bounds.size.height - appWindow.bounds.size.height*scaleFactor/2;
	appWindow.center = center;
}

- (void)touchesEnded:(NSSet *)touches withEvent:(UIEvent *)event {
	for (UITouch *touch in touches) {
		[touchOrigins removeObjectForKey:[NSValue valueWithNonretainedObject:touch]];
	}
	if ([touchOrigins count] != 2) zooming = NO;
}
- (void)touchesCancelled:(NSSet *)touches withEvent:(UIEvent *)event {
	for (UITouch *touch in touches) {
		[touchOrigins removeObjectForKey:[NSValue valueWithNonretainedObject:touch]];
	}
	if ([touchOrigins count] != 2) zooming = NO;
}

- (void)repositionWindow {
	
	[UIView beginAnimations:nil context:NULL]; // A nice transition
	
	// Resize window
	CGRect bounds = appWindow.bounds;
	bounds.size = simulatedSize;
	appWindow.bounds = bounds;
	
	// Changing the return values from UIScreen fixes the app's autorotation
	[[UIScreen mainScreen] setValue:[NSValue valueWithCGRect:appWindow.bounds]
							 forKey:@"_bounds"];
	
	// Readjust scale
	appWindow.transform = CGAffineTransformMakeScale(scaleFactor, scaleFactor);
	
	[UIView commitAnimations];
}

- (void)dealloc {
	// We won't actually get deallocated (singleton), but it's good practice...
	[appWindow release];
	[touchOrigins release];
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
