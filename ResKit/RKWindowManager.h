//
//	RKWindowManager.h
//	ResKit
//
//	Created by Jacob Bandes-Storch on 12/24/09.
//	Copyright 2009 Jacob Bandes-Storch. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface RKWindowManager : UIResponder {
	CGFloat scaleFactor;
	CGSize simulatedSize;
	CGPoint deviceCenter;
	
	UIWindow *resKitWindow;
	UIWindow *appWindow;
	BOOL initialized;
	NSMutableDictionary *touchOrigins;
	BOOL zooming;
	CGFloat zoomStartScale;
	UIImageView *bezelView;
}
@property (nonatomic) CGFloat scaleFactor;
@property (nonatomic) CGPoint deviceCenter;
@property (nonatomic) CGSize simulatedSize;

// Returns the shared window manager instance
+ (RKWindowManager *)sharedManager;
// Initialize the window manager (must be called before using the manager)
- (void)initialize;

@end
