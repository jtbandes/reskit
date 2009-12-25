//
//	RKWindowManager.h
//	ResKit
//
//	Created by Jacob Bandes-Storch on 12/24/09.
//	Copyright 2009 Jacob Bandes-Storch. All rights reserved.
//

#import <UIKit/UIKit.h>

@class RKWindow;

@interface RKWindowManager : UIResponder {
	CGFloat scaleFactor;
	CGSize simulatedSize;
	
	RKWindow *resKitWindow;
	UIWindow *appWindow;
	BOOL initialized;
	NSMutableDictionary *touchOrigins;
	UIScrollView *scrollView;
}
@property (nonatomic) CGFloat scaleFactor;
@property (nonatomic) CGSize simulatedSize;

// Returns the shared window manager instance
+ (RKWindowManager *)sharedManager;
// Initialize the window manager (must be called before using the manager)
- (void)initialize;

@end
