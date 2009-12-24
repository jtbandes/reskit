//
//  RKWindowManager.m
//  ResKit
//
//  Created by Jacob Bandes-Storch on 12/24/09.
//  Copyright 2009 Jacob Bandes-Storch. All rights reserved.
//

#import "RKWindowManager.h"

@implementation RKWindowManager

static RKWindowManager *sharedWindowManager = nil;

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
            return sharedWindowManager;  // assignment and return on first allocation
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
