//
//  EDHShareViewController.h
//  EDHShare
//
//  Created by eden on 2017/6/15.
//  Copyright © 2017年 Eden. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "EDHShareContent.h"
#import "EDHShare.h"

@interface EDHShareViewController : UIViewController

/**
 在指定VC上面弹出分享VC

 @param hostVC 用于呈现分享VC的寄主VC
 @param shareContent 分享的内容
 @param channels 分享的渠道
 */
+ (void)showOnHostVC:(UIViewController*)hostVC
    withShareContent:(EDHShareContent*)shareContent
       shareChannels:(NSArray<NSNumber*>*)channels;

//所有支持的分享渠道
+ (NSArray*)allSupportedChannels;

@end
