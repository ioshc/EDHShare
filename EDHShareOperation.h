//
//  EDHShareOperation.h
//  EDHShare
//
//  Created by eden on 2017/6/21.
//  Copyright © 2017年 Eden. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "EDHShareContent.h"
#import "EDHShare.h"

@interface EDHShareOperation : NSOperation

@property (nonatomic, readonly) EDHShareContent *shareContent;//分享的内容
@property (nonatomic, readonly) EDHShareChannel channel;//分享渠道
@property (nonatomic, readonly) EDHShareCompletionBlock completionHandler;//分享完成后的回调

- (instancetype)initWithShareContent:(EDHShareContent*)content
                             channel:(EDHShareChannel)channel
                          completion:(EDHShareCompletionBlock)completion;

///等待几秒后结束此操作，传0立即结束此操作
- (void)finishAfterSeconds:(NSInteger)seconds state:(EDHShareResponseState)state;

@end
