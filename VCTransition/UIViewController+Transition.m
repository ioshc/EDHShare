//
//  UIViewController+Transition.m
//  Transition
//
//  Created by eden on 2017/5/27.
//  Copyright © 2017年 Eden. All rights reserved.
//

#import "UIViewController+Transition.h"
#import <objc/runtime.h>

#pragma mark -
#pragma mark - UIViewController(ShowInHostVC)

@implementation UIViewController(ShowInHostVC)

+ (instancetype _Nonnull )edh_showInVC:(UIViewController*_Nonnull)hostVC {
    return [self edh_showInVC:hostVC animated:YES configBlock:nil];
}

+ (instancetype _Nonnull )edh_showInVC:(UIViewController*)hostVC
                           configBlock:(void(^)(__kindof UIViewController* vc))block {
    return [self edh_showInVC:hostVC animated:YES configBlock:block];
}

+ (instancetype)edh_showInVC:(UIViewController*)hostVC
                    animated:(BOOL)animated
                 configBlock:(void(^)(__kindof UIViewController *vc))block {

    //Create
    UIViewController *vc = [self edh_instanceForShowsInHostVC];

    if (!hostVC) {
        return vc;
    }

    //Config
    if (block) {
        block(vc);
    }

    //Show
    if (hostVC.navigationController) {
        [hostVC.navigationController pushViewController:vc animated:animated];
    } else {
        [vc edh_presentingAsRootNavInVC:hostVC animated:animated completion:nil];
    }

    //此处默认新的VC的导航栏不隐藏
    vc.navigationController.navigationBarHidden = NO;

    return vc;
}

+ (instancetype)edh_instanceForShowsInHostVC {
    return [[self alloc] init];
}

- (void)edh_dismissWithCompletion: (void (^ __nullable)(void))completion {

    if (self.navigationController.viewControllers.count > 1) {
        [self.navigationController popViewControllerAnimated:YES];

        if (completion) {
            dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.25 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
                completion();
            });
        }
    } else {
        [self dismissViewControllerAnimated:YES completion:completion];
    }
}

@end




#pragma mark -
#pragma mark - UIViewController (PresentationOverCurrentContext)

static char isPresentingOverCurrentContextKey;
static char backLayerKey;

#define PresentationOverCurrentContextBackLayerName @"PresentationOverCurrentContextBackLayer"

@implementation UIViewController (PresentationOverCurrentContext)

+(void)load
{
    Method methodOld = class_getInstanceMethod(self,
                                               @selector(dismissViewControllerAnimated:completion:));
    Method customDismissMethod = class_getInstanceMethod(self,
                                                         @selector(customDismissViewControllerAnimated:completion:));

    method_exchangeImplementations(methodOld, customDismissMethod);
}

- (void)edh_presentOverCurrentContextViewController:(UIViewController* _Nonnull)viewController
                                           animated:(BOOL)animated
                                         completion:(void (^ __nullable)(void))completion
{
    [viewController setIsPresentingOverCurrentContext:YES];

    viewController.providesPresentationContextTransitionStyle = YES;
    viewController.definesPresentationContext = YES;
    viewController.modalPresentationStyle = UIModalPresentationOverCurrentContext;
    viewController.view.backgroundColor = [UIColor clearColor];

    CALayer *backLayer = [[CALayer alloc] init];
    backLayer.frame = CGRectMake(0, -SSCSCREEN_HEIGHT, SSCSCREEN_WIDTH, SSCSCREEN_HEIGHT * 2);
    backLayer.name  = PresentationOverCurrentContextBackLayerName;
    backLayer.backgroundColor = [UIColor colorWithWhite:0 alpha:0.4].CGColor;

    objc_setAssociatedObject(viewController, &backLayerKey, backLayer, OBJC_ASSOCIATION_RETAIN);

    [viewController.view.layer insertSublayer:backLayer atIndex:0];

    [self presentViewController:viewController animated:animated completion:completion];
}

-(void)setIsPresentingOverCurrentContext:(BOOL)isPresentingOverCurrentContext
{
    objc_setAssociatedObject(self,
                             &isPresentingOverCurrentContextKey,
                             @(isPresentingOverCurrentContext),
                             OBJC_ASSOCIATION_RETAIN);
}

- (BOOL)isPresentingOverCurrentContext
{
    return [objc_getAssociatedObject(self, &isPresentingOverCurrentContextKey) boolValue];
}

- (CALayer*)backLayer
{
    return objc_getAssociatedObject(self, &backLayerKey);
}

-(void)customDismissViewControllerAnimated:(BOOL)flag completion:(void (^)(void))completion
{
    if (flag) {
        if (self.isPresentingOverCurrentContext) {
            CALayer *backLayer = [self backLayer];
            CABasicAnimation *animation = [CABasicAnimation animationWithKeyPath:@"opacity"];
            animation.fromValue = @(backLayer.opacity);
            animation.toValue = @(0);
            animation.duration = 0.25;
            animation.removedOnCompletion = NO;
            animation.fillMode = kCAFillModeForwards;
            animation.delegate = (id)self;

            [backLayer addAnimation:animation forKey:@"Fade Out Animation"];
        }
    } else {
        if (self.isPresentingOverCurrentContext) {
            [self p_removeBackLayer];
        }
    }

    [self customDismissViewControllerAnimated:flag completion:completion];
}

#pragma mark - CAAnimation Delegate

- (void)animationDidStop:(CAAnimation *)anim finished:(BOOL)flag
{
    [self p_removeBackLayer];
}

#pragma mark - Private

- (void)p_removeBackLayer
{
    CALayer *backLayer = [self backLayer];
    [backLayer removeFromSuperlayer];
}

@end



#pragma mark -
#pragma mark - UIViewController (Present)

@implementation UIViewController (Present)

- (void)edh_presentingAsRootNavInVC:(UIViewController*_Nonnull)hostVC
                           animated:(BOOL)animated
                         completion:(void (^ __nullable)(void))completion {
    if (!hostVC) {
        return;
    }

    UINavigationController *nav = [[UINavigationController alloc] initWithRootViewController:self];

    UIButton *button = [UIButton buttonWithType:UIButtonTypeCustom];
    [button setImage:[UIImage imageNamed:@"comon_nav_back"]
            forState:UIControlStateNormal];
    [button addTarget:self
               action:@selector(onDismissButtonClicked:)
     forControlEvents:UIControlEventTouchUpInside];
    [button sizeToFit];
    UIBarButtonItem *buttonItem = [[UIBarButtonItem alloc] initWithCustomView:button];
    self.navigationItem.leftBarButtonItem = buttonItem;

    [hostVC presentViewController:nav animated:animated completion:completion];
}

#pragma mark - Button Action

- (void)onDismissButtonClicked:(UIButton*)sender {
    [self edh_dismissWithCompletion:nil];
}

@end

