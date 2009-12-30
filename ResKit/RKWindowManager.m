//
//	RKWindowManager.m
//	ResKit
//
//	Created by Jacob Bandes-Storch on 12/24/09.
//	Copyright 2009 Jacob Bandes-Storch. All rights reserved.
//

#import <CoreGraphics/CoreGraphics.h>
#import "RKWindowManager.h"
#import "UIKit-Private.h"

#define RKLog NSLog

#import <objc/runtime.h>
void MethodSwizzle(Class c, SEL orig, SEL new) {
    Method origMethod = class_getInstanceMethod(c, orig);
    Method newMethod = class_getInstanceMethod(c, new);
	if (!origMethod) {
		NSLog(@"WARNING: Attempting to swizzle nonexistant method -[%@ %@]", c, NSStringFromSelector(orig));
	}
    if(class_addMethod(c, orig, method_getImplementation(newMethod), method_getTypeEncoding(newMethod))) {
		class_replaceMethod(c, new, method_getImplementation(origMethod), method_getTypeEncoding(origMethod));
	} else {
		method_exchangeImplementations(origMethod, newMethod);
	}
}


// Private methods
@interface RKWindowManager ( )
- (void)repositionWindow;
- (BOOL)application:(UIApplication *)application
	didReceiveEvent:(UIEvent *)event;
@end

#pragma mark -
#pragma mark UIKit hacks

@implementation UIApplication (ResKitHacks)
- (void)resKit_sendEvent:(UIEvent *)event {
	// Forward the event to the window manager
	if (![[RKWindowManager sharedManager] application:(UIApplication *)self
									  didReceiveEvent:event]) {
		[self resKit_sendEvent:event]; // Call original implementation
	}
}
@end

@implementation UIWindowController (ResKitHacks)
- (CGPoint)resKit_originForViewController:(id)arg1 orientation:(int)arg2 fullScreenLayout:(BOOL)arg3 {
	CGPoint ret = [self resKit_originForViewController:arg1 orientation:arg2 fullScreenLayout:arg3];
	ret = CGPointMake(0, [UIApplication sharedApplication].statusBarFrame.size.height);
	return ret;
}
@end

@implementation UIWindow (ResKitHacks)
- (CGRect)resKit_frame {
	// Report the frame being the same as the bounds (disregarding the transform)
	return [self bounds];
}
@end

#pragma mark -
#pragma mark Window manager

@implementation RKWindowManager

@synthesize scaleFactor, simulatedSize, deviceCenter;
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
		[self addObserver:self
			   forKeyPath:@"deviceCenter"
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
	
	// Swizzle out the application's sendEvent: method so we can capture touches
	MethodSwizzle([[UIApplication sharedApplication] class], @selector(sendEvent:), @selector(resKit_sendEvent:));
	
	// Perform some specific hacks/fixes
	MethodSwizzle([UIWindowController class], // Fix fullscreen transitions
				  @selector(_originForViewController:orientation:fullScreenLayout:),
				  @selector(resKit_originForViewController:orientation:fullScreenLayout:));
	MethodSwizzle([UIWindow class], // Fix landscape transitions
				  @selector(frame),
				  @selector(resKit_frame));
	
	// Initialize ResKit
	appWindow = [[[UIApplication sharedApplication] keyWindow] retain]; // The main application window being tested
	//appWindow.windowLevel = (UIWindowLevelNormal + UIWindowLevelAlert) / 2.0; // In between normal and alert, so alerts aren't covered
	
	// Create the window which is used to intercept touches
	resKitWindow = [[UIWindow alloc] initWithFrame:[UIScreen mainScreen].bounds];
	resKitWindow.multipleTouchEnabled = YES;
	resKitWindow.backgroundColor = [UIColor blackColor]; // This allows touches outside the app window
	[resKitWindow makeKeyAndVisible];
	
	[appWindow makeKeyAndVisible]; // Put the application window back on top
	
	UIImage *bezel = [[UIImage imageNamed:@"reskit-bezel.png"] stretchableImageWithLeftCapWidth:165 topCapHeight:130];
	if (bezel) {
		bezelView = [[UIImageView alloc] initWithImage:bezel];
		[resKitWindow addSubview:bezelView];
		UIImage *homeButton = [UIImage imageNamed:@"reskit-home.png"];
		if (homeButton) {
			UIImageView *homeButtonView = [[UIImageView alloc] initWithImage:homeButton];
			homeButtonView.center = CGPointMake(bezelView.bounds.size.width/2,
												bezelView.bounds.size.height - 70);
			homeButtonView.autoresizingMask = UIViewAutoresizingFlexibleLeftMargin|UIViewAutoresizingFlexibleRightMargin|UIViewAutoresizingFlexibleTopMargin;
			[bezelView addSubview:homeButtonView];
		}
	}
	
	// It appears that the window's initial frame
	// isn't actually [UIScreen mainScreen].applicationFrame, it's the full bounds...
	
	// TODO: support initializing in landscape
	
	// Start with the device's normal size
	scaleFactor = 1.0;
	simulatedSize = [UIScreen mainScreen].bounds.size;
	deviceCenter = appWindow.center;
	
	// TODO: [insert more magic here]
	
	[self repositionWindow];
}

#pragma mark -
#pragma mark Event handling

- (BOOL)application:(UIApplication *)application
	didReceiveEvent:(UIEvent *)event {
	
	if (event.type == UIEventTypeTouches) {
		
#if TARGET_IPHONE_SIMULATOR
		// Allow top-left hot corner enabling for simulator
		for (UITouch *t in [event allTouches]) {
			if (t.phase == UITouchPhaseBegan) {
				CGPoint loc = [resKitWindow convertPoint:[t locationInView:nil]
											  fromWindow:t.window];
				loc.y -= [UIApplication sharedApplication].statusBarFrame.size.height;
				
				if (sqrt(loc.x*loc.x + loc.y*loc.y) < 10) { // 10px away from upper left
					resKitMode = !resKitMode;
					return YES;
				}
			}
		}
#endif
		
		BOOL sendTouches = NO;
		for (UITouch *t in [event allTouches]) {
			if (t.window == resKitWindow) {
				sendTouches = YES;
				break;
			}
			if (resKitMode) {
				// Force all events into the ResKit window, to make dragging work properly
				// FML
				UIView *targetView = [resKitWindow hitTest:[resKitWindow convertPoint:[t locationInView:nil]
																		   fromWindow:t.window]
												 withEvent:nil];
				[t setValue:[NSValue valueWithCGPoint:[resKitWindow convertPoint:[t locationInView:nil]
																	  fromWindow:t.window]]
					 forKey:@"_locationInWindow"];
				[t setValue:[NSValue valueWithCGPoint:[resKitWindow convertPoint:[t previousLocationInView:nil]
																	  fromWindow:t.window]]
					 forKey:@"_previousLocationInWindow"];
				[t setValue:resKitWindow forKey:@"_window"];
				[t setValue:targetView forKey:@"_view"];
			}
		}
		
		// Zooming or touching the ResKit window
		if ([[event allTouches] count] == 3 || sendTouches || resKitMode) {
			NSMutableSet *b = [NSMutableSet set];
			NSMutableSet *m = [NSMutableSet set];
			NSMutableSet *e = [NSMutableSet set];
			NSMutableSet *c = [NSMutableSet set];
			
			for (UITouch *t in [event allTouches]) {
				switch (t.phase) {
					case UITouchPhaseBegan: [b addObject:t]; break;
					case UITouchPhaseMoved: [m addObject:t]; break;
					case UITouchPhaseEnded: [e addObject:t]; break;
					case UITouchPhaseCancelled: [c addObject:t]; break;
					default: break;
				}
			}
			
			// Cancel all existing touches and resend touchesBegan
			if ([b count] > 0) {
				[touchOrigins removeAllObjects];
				numTouches = 0;
				[self touchesBegan:[event allTouches] withEvent:event];
			} else if ([m count] > 0) [self touchesMoved:m withEvent:event];
			if ([e count] > 0) [self touchesEnded:e withEvent:event];
			if ([c count] > 0) [self touchesCancelled:c withEvent:event];
			
			return YES;
		}
	}
	return NO; // call default implementation
}

- (void)touchesBegan:(NSSet *)touches withEvent:(UIEvent *)event {
	for (UITouch *touch in touches) {
		[touchOrigins setObject:[NSValue valueWithCGPoint:[resKitWindow convertPoint:[touch locationInView:nil]
																		  fromWindow:touch.window]]
						 forKey:[NSValue valueWithNonretainedObject:touch]];
		numTouches++;
	}
	if ([touchOrigins count] != 2) zooming = NO;
	if (numTouches == 3) {
		resKitMode = !resKitMode;
		[touchOrigins removeAllObjects];
		numTouches = 0;
		NSLog(@"ResKit mode %d", resKitMode);
	}
}

- (void)touchesMoved:(NSSet *)touches
		   withEvent:(UIEvent *)event {
	if (resKitMode) {
		NSArray *ta = [[event allTouches] allObjects];
		
		// Compute the original and current centroids (averages) of and total distances between touches
		// This should allow scaling/translation with any number of touches, not just 2
		
		CGPoint prevCentroid = CGPointZero;
		CGPoint centroid = CGPointZero;
		
		CGFloat origDistance = 0;
		CGFloat newDistance = 0;
		
		NSUInteger numActiveTouches = [ta count];
		NSUInteger i = 0;
		UITouch *prevTouch = nil;
		CGPoint prevTouchOrig = CGPointZero;
		CGPoint prevTouchNew = CGPointZero;
		
		for (UITouch *t in ta) {
			CGPoint orig = [[touchOrigins objectForKey:[NSValue valueWithNonretainedObject:t]] CGPointValue];
			CGPoint prev = [resKitWindow convertPoint:[t previousLocationInView:nil]
										   fromWindow:t.window];
			CGPoint new = [resKitWindow convertPoint:[t locationInView:nil]
										  fromWindow:t.window];
			
			// Centroids (position)
			prevCentroid.x += prev.x;
			prevCentroid.y += prev.y;
			centroid.x += new.x;
			centroid.y += new.y;
			
			// Distances (zoom)
			if (prevTouch) {
				CGFloat odx = orig.x - prevTouchOrig.x;
				CGFloat ody = orig.y - prevTouchOrig.y;
				origDistance += sqrt(odx*odx + ody*ody);
				
				CGFloat dx = new.x - prevTouchNew.x;
				CGFloat dy = new.y - prevTouchNew.y;
				newDistance += sqrt(dx*dx + dy*dy);
			}
			prevTouchOrig = orig;
			prevTouchNew = new;
			prevTouch = t;
			
			i++;
		}
		prevCentroid.x /= numActiveTouches;
		prevCentroid.y /= numActiveTouches;
		centroid.x /= numActiveTouches;
		centroid.y /= numActiveTouches;
		
		if ([touchOrigins count] == 2) {
			if (abs(newDistance - origDistance) > 50 && !zooming) {
				zooming = YES;
				zoomStartScale = scaleFactor;
				// Reset origins for smooth transition into zooming
				for (UITouch *t in ta) {
					CGPoint pos = [resKitWindow convertPoint:[t locationInView:nil]
												  fromWindow:t.window];
					[touchOrigins setObject:[NSValue valueWithCGPoint:pos]
									 forKey:[NSValue valueWithNonretainedObject:t]];
				}
			} else if (zooming) {
				CGFloat scale = zoomStartScale * newDistance / origDistance;
				if (scale > 1) scale = 1;
				if (scale < 0.05) scale = 0.05;
				self.scaleFactor = scale;
			}
		}
		
		CGPoint center = deviceCenter;
		center.x += centroid.x - prevCentroid.x;
		center.y += centroid.y - prevCentroid.y;
		//	// Limit to edges
		//	if (center.x > appWindow.bounds.size.width*scaleFactor/2) center.x = appWindow.bounds.size.width*scaleFactor/2;
		//	if (center.x < resKitWindow.bounds.size.width - appWindow.bounds.size.width*scaleFactor/2)
		//		center.x = resKitWindow.bounds.size.width - appWindow.bounds.size.width*scaleFactor/2;
		//	if (center.y > appWindow.bounds.size.height*scaleFactor/2) center.y = appWindow.bounds.size.height*scaleFactor/2;
		//	if (center.y < resKitWindow.bounds.size.height - appWindow.bounds.size.height*scaleFactor/2)
		//		center.y = resKitWindow.bounds.size.height - appWindow.bounds.size.height*scaleFactor/2;
		self.deviceCenter = center;
	}
}

- (void)touchesEnded:(NSSet *)touches withEvent:(UIEvent *)event {
	BOOL doubleTap = YES;
	for (UITouch *touch in touches) {
		[touchOrigins removeObjectForKey:[NSValue valueWithNonretainedObject:touch]];
		
		if (touch.tapCount != 2) {
			doubleTap = NO;
		}
	}
	if (resKitMode && [touches count] == [[event allTouches] count] &&
		numTouches == 1 && doubleTap) { // Double tap to center
		[UIView beginAnimations:nil context:NULL];
		self.deviceCenter = CGPointMake(resKitWindow.bounds.size.width/2, resKitWindow.bounds.size.height/2);
		[UIView commitAnimations];
	}
	if ([touchOrigins count] != 2) zooming = NO; // End zooming
	
	if ([touches count] == [[event allTouches] count]) numTouches = 0; // Touch sequence finished
}
- (void)touchesCancelled:(NSSet *)touches withEvent:(UIEvent *)event {
	for (UITouch *touch in touches) {
		[touchOrigins removeObjectForKey:[NSValue valueWithNonretainedObject:touch]];
	}
	if ([touchOrigins count] != 2) zooming = NO;
	
	if ([touches count] == [[event allTouches] count]) numTouches = 0; // Touch sequence finished
}

- (void)repositionWindow {
	//[UIView beginAnimations:nil context:NULL]; // A nice transition
	
	// Resize window
	CGRect bounds = appWindow.bounds;
	bounds.size = simulatedSize;
	appWindow.bounds = bounds;
	bezelView.bounds = CGRectMake(0, 0,
								  appWindow.bounds.size.width+67,
								  appWindow.bounds.size.height+249);
	
	// Changing the return values from UIScreen fixes the app's autorotation
	[[UIScreen mainScreen] setValue:[NSValue valueWithCGRect:appWindow.bounds]
							 forKey:@"_bounds"];
	
	// Readjust scale
	appWindow.transform = CGAffineTransformMakeScale(scaleFactor, scaleFactor);
	bezelView.transform = appWindow.transform;
	
	// Reposition window and bezel
	appWindow.center = deviceCenter;
	bezelView.center = CGPointMake(deviceCenter.x-2*scaleFactor,
								   deviceCenter.y-8*scaleFactor);
	
	//[UIView commitAnimations];
}

- (void)dealloc {
	// We won't actually get deallocated (singleton), but it's good practice...
	[appWindow release];
	[touchOrigins release];
	[bezelView release];
	[resKitWindow release];
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
