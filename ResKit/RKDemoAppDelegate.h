//
//  RKDemoAppDelegate.h
//  ResKit
//
//  Created by Jacob Bandes-Storch on 12/24/09.
//  Copyright 2009 Jacob Bandes-Storch. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface RKDemoAppDelegate : NSObject <UIApplicationDelegate> {
	UIWindow *window;
	UIViewController *mainViewController;
}
@property (nonatomic, retain) IBOutlet UIWindow *window;
@property (nonatomic, retain) IBOutlet UIViewController *mainViewController;

@end
