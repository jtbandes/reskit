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
		
		//scrollView.contentSize = simulatedSize;
		
		// Adjust display based on new property values
		[self repositionWindow];
	}// else if (object == scrollView) {
//		[self repositionWindow];
//	}
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
	
	// Start with the device's normal size
	scaleFactor = 1.0;
	simulatedSize = [UIScreen mainScreen].bounds.size;
	
	
//	scrollView = [[UIScrollView alloc] initWithFrame:resKitWindow.bounds];
//	scrollView.multipleTouchEnabled = YES;
//	scrollView.backgroundColor = [UIColor blueColor];
//	scrollView.minimumZoomScale = 0.1;
//	//scrollView.maximumZoomScale = 2;
//	scrollView.alwaysBounceHorizontal = YES;
//	scrollView.alwaysBounceVertical = YES;
//	scrollView.bouncesZoom = YES;
//	scrollView.contentSize = simulatedSize;
//	[scrollView addObserver:self
//				 forKeyPath:@"contentOffset"
//					options:0
//					context:NULL];
//	[scrollView addObserver:self
//				 forKeyPath:@"zoomScale"
//					options:0
//					context:NULL];
//	[appWindow addSubview:scrollView];
	
	// TODO: [insert magic here]
	[self repositionWindow];
}

#pragma mark -
#pragma mark Event handling

//- (void)resKitWindow:(RKWindow *)window
//	 didReceiveEvent:(UIEvent *)event {
//	if (event.type == UIEventTypeTouches) {
//		NSMutableSet *began = [NSMutableSet set];
//		NSMutableSet *moved = [NSMutableSet set];
//		NSMutableSet *ended = [NSMutableSet set];
//		NSMutableSet *cancelled = [NSMutableSet set];
//		for (UITouch *t in [event allTouches]) {
//			switch (t.phase) {
//				case UITouchPhaseBegan: [began addObject:t]; break;
//				case UITouchPhaseMoved: [moved addObject:t]; break;
//				case UITouchPhaseEnded: [ended addObject:t]; break;
//				case UITouchPhaseCancelled: [cancelled addObject:t]; break;
//				default: break;
//			}
//		}
//		UITouch *t = [moved anyObject];
//		CGPoint center = appWindow.center;
//		CGPoint loc = [t locationInView:nil];
//		CGPoint prevLoc = [t previousLocationInView:nil];
//		center.x += loc.x - prevLoc.x;
//		center.y += loc.y - prevLoc.y;
//		appWindow.center = center;
//	}
//	
//	[appWindow sendEvent:event];
//}

- (void)touchesBegan:(NSSet *)touches withEvent:(UIEvent *)event {
	NSLog(@"Began %d", [[event allTouches] count]);
	for (UITouch *touch in touches) {
		[touchOrigins setObject:[NSValue valueWithCGPoint:[touch locationInView:nil]]
						 forKey:[NSValue valueWithNonretainedObject:touch]];
	}
}

- (void)touchesMoved:(NSSet *)touches
		   withEvent:(UIEvent *)event {
	if ([[event allTouches] count] == 2) {
		
	}
	UITouch *t = [touches anyObject];
	CGPoint center = appWindow.center;
	CGPoint loc = [t locationInView:nil];
	CGPoint prevLoc = [t previousLocationInView:nil];
	center.x += loc.x - prevLoc.x;
	center.y += loc.y - prevLoc.y;
	appWindow.center = center;
}

- (void)touchesEnded:(NSSet *)touches withEvent:(UIEvent *)event {
	for (UITouch *touch in touches) {
		[touchOrigins removeObjectForKey:[NSValue valueWithNonretainedObject:touch]];
	}
}
- (void)touchesCancelled:(NSSet *)touches withEvent:(UIEvent *)event {
	for (UITouch *touch in touches) {
		[touchOrigins removeObjectForKey:[NSValue valueWithNonretainedObject:touch]];
	}
}

- (void)repositionWindow {
	
//	appWindow.center = CGPointMake(resKitWindow.bounds.size.width/2+10 - scrollView.contentOffset.x,
//								   resKitWindow.bounds.size.height/2 - scrollView.contentOffset.y);
//	appWindow.transform = CGAffineTransformMakeScale(scrollView.zoomScale, scrollView.zoomScale);
	
	[UIView beginAnimations:nil context:NULL]; // A nice transition
	
	//scrollView.contentSize = simulatedSize;
	
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
	[touchOrigins release];
	//[scrollView release];
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
