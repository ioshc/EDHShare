//
//  EDHShareOperation.m
//  EDHShare
//
//  Created by eden on 2017/6/21.
//  Copyright © 2017年 Eden. All rights reserved.
//

#import "EDHShareOperation.h"
#import "EDHShareActionHandler.h"
#import "EDHShareActionHandler+Private.h"

@interface EDHShareOperation() {
    BOOL _isFinished;//是否完成的标志
    BOOL _isExecuting;//是否正在执行的标志
}

@property (nonatomic, strong) EDHShareContent *shareContent;
@property (nonatomic) EDHShareChannel channel;
@property (nonatomic, copy) EDHShareCompletionBlock completionHandler;
@property (nonatomic) EDHShareResponseState respState;

@end

@implementation EDHShareOperation

- (instancetype)initWithShareContent:(EDHShareContent*)content
                             channel:(EDHShareChannel)channel
                          completion:(EDHShareCompletionBlock)completion {

    EDHShareOperation *operation = [[EDHShareOperation alloc] init];
    operation.shareContent = content;
    operation.channel = channel;
    operation.completionHandler = completion;
    operation.respState = EDHShareResponseStateFail;

    return operation;
}

#pragma mark - Override

- (BOOL)isAsynchronous {
    return YES;
}

- (void)start {

    if ([self isCancelled]) {
        [self finishWithState:EDHShareResponseStateCancel];
        return;
    }

    if ([self isExecuting]) {
        return;
    }

    [self willChangeValueForKey:@"isExecuting"];
    _isExecuting = YES;
    [self didChangeValueForKey:@"isExecuting"];

    dispatch_async(dispatch_get_main_queue(), ^{
        switch (self.channel) {
            case EDHShareChannelWechatFriend:
                [self p_registerAppDidBecomeActiveNotification];
                [EDHShareActionHandler p_shareToWechatFriendWithContent:self.shareContent];
                break;
            case EDHShareChannelWechatTimeline:
                [self p_registerAppDidBecomeActiveNotification];
                [EDHShareActionHandler p_shareToWechatTimelineWithContent:self.shareContent];
                break;
            case EDHShareChannelSMS:
                [EDHShareActionHandler p_shareToSMSWithContent:self.shareContent];
                break;
            case EDHShareChannelWeibo:
                [EDHShareActionHandler p_shareToWeiboWithContent:self.shareContent
                                                    isShareInApp:^(BOOL isShareInApp) {
                                                        if (isShareInApp) {
                                                            [self p_registerAppDidBecomeActiveNotification];
                                                        }
                                                    }];
                break;
        }
    });
}

- (BOOL)isFinished {
    return _isFinished;
}

- (BOOL)isExecuting {
    return _isExecuting;
}

#pragma mark - Finish

- (void)finishWithState:(EDHShareResponseState)state {

    if ([self isFinished]) {
        return;
    }

    [[NSNotificationCenter defaultCenter] removeObserver:self];

    if ([self isCancelled]) {
        state = EDHShareResponseStateCancel;
    }

    //回调
    if (self.completionHandler) {
        self.completionHandler(state);
    }

    //修改Operation的状态为完成状态
    [self willChangeValueForKey:@"isExecuting"];
    [self willChangeValueForKey:@"isFinished"];
    _isExecuting = NO;
    _isFinished = YES;
    [self didChangeValueForKey:@"isExecuting"];
    [self didChangeValueForKey:@"isFinished"];
}

- (void)finishAfterSeconds:(NSInteger)seconds state:(EDHShareResponseState)state {

    //已经完成则移除通知，防止收到通知后认为用户是放弃这次操作
    [[NSNotificationCenter defaultCenter] removeObserver:self];

    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(seconds * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        [self finishWithState:state];
    });
}

#pragma mark - Notificaiotns

- (void)p_registerAppDidBecomeActiveNotification {
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(p_handleAppDidBecomeActiveNotification:)
                                                 name:UIApplicationDidBecomeActiveNotification
                                               object:nil];
}

- (void)p_handleAppDidBecomeActiveNotification:(NSNotification*)notification {

    if (![self isExecuting]) {
        return;
    }

    if ([self isCancelled]) {
        [self finishWithState:EDHShareResponseStateCancel];
        return;
    }

    [self finishWithState:EDHShareResponseStateUserAbandon];
}

@end
