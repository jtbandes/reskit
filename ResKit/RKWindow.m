//
//  RKWindow.m
//  ResKit
//
//  Created by Jacob Bandes-Storch on 12/24/09.
//  Copyright 2009 Jacob Bandes-Storch. All rights reserved.
//

#import "RKWindow.h"
#import "RKWindowManager.h"

@implementation RKWindow

@synthesize windowManager;

- (id)initWithFrame:(CGRect)frame {
	if (self = [super initWithFrame:frame]) {
		// Force multi-touch
		self.multipleTouchEnabled = YES;
	}
	return self;
}

// Forward touch events to the delegate (window manager) via responder chain
- (UIResponder *)nextResponder {
	return windowManager;
}

//- (void) touchesBegan:(NSSet *)touches withEvent:(UIEvent *)event {
//	NSLog(@"Touches began %@", touches);
//}

// Forward touch events to the delegate (window manager)
//- (void)sendEvent:(UIEvent *)event {
//	[delegate resKitWindow:self
//		   didReceiveEvent:event];
//}

@end
