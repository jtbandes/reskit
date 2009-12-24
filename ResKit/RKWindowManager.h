//
//  RKWindowManager.h
//  ResKit
//
//  Created by Jacob Bandes-Storch on 12/24/09.
//  Copyright 2009 Jacob Bandes-Storch. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface RKWindowManager : NSObject {
	CGFloat scaleFactor;
	CGSize simulatedSize;
	
	UIWindow *resWindow;
	UIWindow *appWindow;
	BOOL initialized;
}
@property (nonatomic) CGFloat scaleFactor;
@property (nonatomic) CGSize simulatedSize;

// Returns the shared window manager instance
+ (RKWindowManager *)sharedManager;
// Initialize the window manager (must be called before using)
- (void)initialize;

@end
