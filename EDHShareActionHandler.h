//
//  EDHShareActionHandler.h
//  EDHShare
//
//  Created by eden on 2017/6/15.
//  Copyright © 2017年 Eden. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "EDHShareContent.h"
#import "EDHShare.h"

@interface EDHShareActionHandler : NSObject

///注册微信
+ (void)registerWechatWithAppId:(NSString*)appid;

///注册微博
+ (void)registerWeiboWithAppId:(NSString*)appid;

/**
 分享内容到指定平台，同步返回调用结果，分享结果通过block异步返回

 @param content 分享的内容
 @param channel 分享渠道
 @param completion 分享完成后异步回调block
 */
+ (void)shareWithContent:(EDHShareContent*)content
                 channel:(EDHShareChannel)channel
              completion:(EDHShareCompletionBlock)completion;

@end
