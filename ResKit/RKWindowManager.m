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

#import <objc/runtime.h>
void MethodSwizzle(Class c, SEL orig, SEL new) {
    Method origMethod = class_getInstanceMethod(c, orig);
    Method newMethod = class_getInstanceMethod(c, new);
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



@implementation UIApplication (ResKitEventHandling)
- (void)resKit_sendEvent:(UIEvent *)event {
	// Forward the event to the window manager
	if (![[RKWindowManager sharedManager] application:(UIApplication *)self
									  didReceiveEvent:event]) {
		[self resKit_sendEvent:event]; // Call original implementation
	}
}
@end

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
	
	// Initialize ResKit
	appWindow = [[[UIApplication sharedApplication] keyWindow] retain]; // The main application window being tested
	appWindow.windowLevel = UIWindowLevelAlert;
	// Create the window which is used to intercept touches
	resKitWindow = [[RKWindow alloc] initWithFrame:[UIScreen mainScreen].bounds];
	resKitWindow.windowManager = self;
	//resKitWindow.windowLevel = UIWindowLevelAlert;
	resKitWindow.backgroundColor = [UIColor blackColor]; // This allows touches outside the app window
	[resKitWindow makeKeyAndVisible];
	
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
		BOOL sendTouches = NO;
		for (UITouch *t in [event allTouches]) {
			if (t.window == resKitWindow) {
				sendTouches = YES;
				break;
			}
		}
		
		// Zooming or touching the ResKit window
		if ([[event allTouches] count] == 2 || sendTouches) {
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
		CGPoint t1p = [resKitWindow convertPoint:[t1 locationInView:nil]
									  fromWindow:t1.window];
		CGPoint t2p = [resKitWindow convertPoint:[t2 locationInView:nil]
									  fromWindow:t2.window];
		
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
			[touchOrigins setObject:[NSValue valueWithCGPoint:t1p]
							 forKey:[NSValue valueWithNonretainedObject:t1]];
			[touchOrigins setObject:[NSValue valueWithCGPoint:t2p]
							 forKey:[NSValue valueWithNonretainedObject:t2]];
		} else if (zooming) {
			CGFloat scale = zoomStartScale * newDistance / originalDistance;
			if (scale > 1) scale = 1;
			if (scale < 0.05) scale = 0.05;
			self.scaleFactor = scale;
		}
		return;
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
	self.deviceCenter = center;
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
