//
//  EDHShare.h
//  EDHShare
//
//  Created by eden on 2017/6/21.
//  Copyright © 2017年 Eden. All rights reserved.
//

#ifndef EDHShare_h
#define EDHShare_h

//分享渠道
typedef NS_ENUM(NSUInteger, EDHShareChannel) {
    EDHShareChannelWechatFriend     = 1,//微信好友
    EDHShareChannelWechatTimeline   = 2,//微信朋友圈
    EDHShareChannelSMS              = 3,//短信
    EDHShareChannelWeibo            = 4,//新浪微博
};

//分享状态
typedef NS_ENUM(NSUInteger, EDHShareResponseState) {
    EDHShareResponseStateSuccess                = 0,//成功
    EDHShareResponseStateFail                   = 1,//失败
    EDHShareResponseStateCancel                 = 2,//取消
    EDHShareResponseStateAppNotInstalled        = 3,//未安装客户端
    EDHShareResponseStateAppNotSupportApi       = 4,//客户端不支持OpenApi
    EDHShareResponseStateUserAbandon            = 5,//掉起第三方应用分享后，用户放弃操作，直接返回app
    EDHShareResponseStateNotSupport             = 6,//不支持该方式
};

//分享完成后回调block，参数为分享状态
typedef void(^EDHShareCompletionBlock)(EDHShareResponseState state);

#endif /* EDHShare_h */
