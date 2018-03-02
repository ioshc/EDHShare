//
//  UIViewController+Transition.h
//  Transition
//
//  Created by eden on 2017/5/27.
//  Copyright © 2017年 Eden. All rights reserved.
//

#import <UIKit/UIKit.h>

#pragma mark -
#pragma mark - UIViewController(ShowInHostVC)

@interface UIViewController(ShowInHostVC)

/**
 在寄主VC上展示新的VC，开启转场动画；如果寄主VC在nav栈中，则将新的VC push到nav栈顶，否则model出新的VC
 注意：函数内部会调用edh_instanceForShowsInHostVC函数创建新的VC实例，edh_instanceForShowsInHostVC的默认实现是init，
 如果想通过此函数展示的VC需要进行不同的初始化方法，请重写edh_instanceForShowsInHostVC函数，返回自定义的实例

 @param hostVC 用于展示新VC的主VC
 @return 被展示出来的VC实例
 */
+ (instancetype _Nonnull )edh_showInVC:(UIViewController*_Nonnull)hostVC;

/**
 在寄主VC上展示新的VC，开启转场动画；如果寄主VC在nav栈中，则将新的VC push到nav栈顶，否则model出新的VC
 可通过block配置待展示的VC
 注意：函数内部会调用edh_instanceForShowsInHostVC函数创建新的VC实例，edh_instanceForShowsInHostVC的默认实现是init，
 如果想通过此函数展示的VC需要进行不同的初始化方法，请重写edh_instanceForShowsInHostVC函数，返回自定义的实例

 @param hostVC 用于展示新VC的主VC
 @param block 是否展示转场动画
 */
+ (instancetype _Nonnull )edh_showInVC:(UIViewController*_Nonnull)hostVC
                           configBlock:(void(^_Nullable)(__kindof UIViewController* _Nonnull vc))block;

/**
 在寄主VC上展示新的VC，可指定是否展示转场动画；如果寄主VC在nav栈中，则将新的VC push到nav栈顶，否则model出新的VC
 可通过block配置待展示的VC
 注意：函数内部会调用edh_instanceForShowsInHostVC函数创建新的VC实例，edh_instanceForShowsInHostVC的默认实现是init，
 如果想通过此函数展示的VC需要进行不同的初始化方法，请重写edh_instanceForShowsInHostVC函数，返回自定义的实例

 @param hostVC 用于展示新VC的主VC
 @param animated 是否展示转场动画
 @param block 是否展示转场动画
 */
+ (instancetype _Nonnull )edh_showInVC:(UIViewController*_Nonnull)hostVC
                              animated:(BOOL)animated
                           configBlock:(void(^_Nullable)(__kindof UIViewController* _Nonnull vc))block;


/**
 使用edh_showInVC函数展示的VC会调用此函数创建其实例，默认实现是init，需要进行不同的初始化方法，请重写该函数，返回自定义的实例

 @return 创建好的VC实例
 */
+ (instancetype _Nonnull )edh_instanceForShowsInHostVC;

/**
 消失当前VC
 */
- (void)edh_dismissWithCompletion: (void (^ __nullable)(void))completion;

@end



#pragma mark - 
#pragma mark - UIViewController (PresentationOverCurrentContext)

@interface UIViewController (PresentationOverCurrentContext)

@property (nonatomic, assign) BOOL isPresentingOverCurrentContext;


/**
 在当前VC上展示新的VC（非全屏情况下可漏出下面的视图），类似AlertController的效果

 @param viewController 需要展示的VC
 @param animated 是否显示转场动画
 @param completion 显示完成后的回调
 */
- (void)edh_presentOverCurrentContextViewController:(UIViewController* _Nonnull)viewController
                                           animated:(BOOL)animated
                                         completion:(void (^ __nullable)(void))completion;

@end



#pragma mark -
#pragma mark - UIViewController (Present)

@interface UIViewController (Present)

/**
 在寄主VC上展示新的VC（并将VC放在nav栈中）

 @param hostVC 寄主VC
 @param animated 是否显示转场动画
 @param completion 显示完成回调
 */
- (void)edh_presentingAsRootNavInVC:(UIViewController*_Nonnull)hostVC
                           animated:(BOOL)animated
                         completion:(void (^ __nullable)(void))completion;

@end
