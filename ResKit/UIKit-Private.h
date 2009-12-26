#import <UIKit/UIKit.h>

@class UITransitionView;

@interface UIWindowController : NSObject
{
    UITransitionView *_transitionView;
    UIWindow *_window;
    int _currentTransition;
    id _target;
    SEL _didEndSelector;
    UIViewController *_fromViewController;
    UIViewController *_toViewController;
    struct CGPoint _beginOriginForToView;
    struct CGPoint _endOriginForToView;
}

+ (id)windowControllerForWindow:(id)arg1;
+ (void)windowWillBeDeallocated:(id)arg1;
- (void)dealloc;
- (struct CGPoint)_originForViewController:(id)arg1 orientation:(int)arg2 fullScreenLayout:(BOOL)arg3;
- (struct CGSize)_flipSize:(struct CGSize)arg1;
- (struct CGRect)_boundsForViewController:(id)arg1 orientation:(int)arg2 fullScreenLayout:(BOOL)arg3;
- (struct CGAffineTransform)_rotationTransformForInterfaceOrientation:(int)arg1;
- (void)_prepareKeyboardForTransition:(int)arg1 fromView:(id)arg2;
- (void)_transplantView:(id)arg1 toSuperview:(id)arg2 atIndex:(unsigned int)arg3;
- (void)transition:(int)arg1 fromViewController:(id)arg2 toViewController:(id)arg3 target:(id)arg4 didEndSelector:(SEL)arg5;
- (void)transitionViewDidComplete:(id)arg1 fromView:(id)arg2 toView:(id)arg3;
- (double)durationForTransition:(int)arg1;
- (struct CGPoint)_adjustOrigin:(struct CGPoint)arg1 givenOtherOrigin:(struct CGPoint)arg2 forTransition:(int)arg3;
- (struct CGPoint)transitionView:(id)arg1 endOriginForFromView:(id)arg2 forTransition:(int)arg3 defaultOrigin:(struct CGPoint)arg4;
- (struct CGPoint)transitionView:(id)arg1 beginOriginForToView:(id)arg2 forTransition:(int)arg3 defaultOrigin:(struct CGPoint)arg4;
- (struct CGPoint)transitionView:(id)arg1 endOriginForToView:(id)arg2 forTransition:(int)arg3 defaultOrigin:(struct CGPoint)arg4;
- (id)window;
- (void)setWindow:(id)arg1;

@end
