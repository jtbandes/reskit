//
//  RKWindow.h
//  ResKit
//
//  Created by Jacob Bandes-Storch on 12/24/09.
//  Copyright 2009 Jacob Bandes-Storch. All rights reserved.
//

#import <UIKit/UIKit.h>

@class RKWindowManager;

@interface RKWindow : UIWindow {
	RKWindowManager *windowManager;
}
@property (nonatomic, assign) RKWindowManager *windowManager;

@end
