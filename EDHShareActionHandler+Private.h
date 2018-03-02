//
//  EDHShareActionHandler+Private.h
//  EDHShare
//
//  Created by eden on 2017/6/21.
//  Copyright © 2017年 Eden. All rights reserved.
//

@interface EDHShareActionHandler(Private)

///分享到微信好友
+ (BOOL)p_shareToWechatFriendWithContent:(EDHShareContent*)content;

///分享到微信朋友圈
+ (BOOL)p_shareToWechatTimelineWithContent:(EDHShareContent*)content;

///分享到SMS
+ (BOOL)p_shareToSMSWithContent:(EDHShareContent*)content;

/**
 分享到微博

 @param content 分享的内容
 @param isShareInApp 是否在app中分享（微博支持H5和app内分享，此block用于告知调用者是否在app内分享，YES表示在app内分享）
 @return 调用SDK是否成功
 */
+ (BOOL)p_shareToWeiboWithContent:(EDHShareContent*)content isShareInApp:(void(^)(BOOL isShareInApp))isShareInApp;

@end
