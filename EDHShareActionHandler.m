//
//  EDHShareActionHandler.m
//  EDHShare
//
//  Created by eden on 2017/6/15.
//  Copyright © 2017年 Eden. All rights reserved.
//

#import "EDHShareActionHandler.h"
#import "EDHShareOperation.h"

#import "AppDelegate.h"
#import <objc/runtime.h>

#import <MessageUI/MessageUI.h>
#import "WXApi.h"
#import "WeiboSDK.h"

#define kWeiboRedirectURI    @"http://sns.whalecloud.com/sina2/callback"

static NSOperationQueue *_concurrentQueue;//操作队列
static UIWindow *_shareWindow;//用于展示share相关的VC，比如弹出短信分享界面
static BOOL _isWaitingForResp;//是否正在等待回调，当收到AppWillEnterForeground通知时开始，收到AppDidBecomeActive后结束

@implementation EDHShareActionHandler

#pragma mark - Hook AppDelegate openURL Method

+ (void)initialize {
    if (self == [EDHShareActionHandler class]) {
        _concurrentQueue = [[NSOperationQueue alloc] init];
        _concurrentQueue.maxConcurrentOperationCount = 1;

        //iOS9以前
        Method iOS8OriginalMethod = class_getInstanceMethod([AppDelegate class],
                                                            @selector(application:openURL:sourceApplication:annotation:));
        Method iOS8HookMethod = class_getClassMethod([self class],
                                                     @selector(EDHShare_application:openURL:sourceApplication:annotation:));
        [self p_hookAppDelegateOpenURLMethod:iOS8OriginalMethod withHookedMethod:iOS8HookMethod];

        //iOS9及iOS9以后
        Method iOS9OriginalMethod = class_getInstanceMethod([AppDelegate class],
                                                            @selector(application:openURL:options:));
        Method iOS9HookMethod = class_getClassMethod([self class],
                                                     @selector(EDHShare_application:openURL:options:));
        [self p_hookAppDelegateOpenURLMethod:iOS9OriginalMethod withHookedMethod:iOS9HookMethod];
    }
}

+ (void)p_hookAppDelegateOpenURLMethod:(Method)originalMethod withHookedMethod:(Method)hookedMethod {

    //由于AppDelegate没有EDHShare_application方法，所以后面调用时会Crash，
    //所以在此处为AppDelegate添加EDHShare_application方法
    class_addMethod([AppDelegate class],
                    method_getName(hookedMethod),
                    method_getImplementation(originalMethod),
                    method_getTypeEncoding(originalMethod));

    method_exchangeImplementations(originalMethod, hookedMethod);
}

//iOS9以前
+ (BOOL)EDHShare_application:(UIApplication *)app openURL:(NSURL *)url sourceApplication:(NSString *)sourceApplication annotation:(id)annotation {

    [EDHShareActionHandler p_handleURL:url];

    //此时的self其实是AppDelegate对象
    return [self EDHShare_application:app openURL:url sourceApplication:sourceApplication annotation:annotation];
}

//iOS9及iOS9以后
+ (BOOL)EDHShare_application:(UIApplication *)app openURL:(NSURL *)url options:(NSDictionary<UIApplicationOpenURLOptionsKey, id> *)options {

    [EDHShareActionHandler p_handleURL:url];

    //此时的self其实是AppDelegate对象
    return [self EDHShare_application:app openURL:url options:options];
}

+ (void)p_handleURL:(NSURL*)url {

    if ([url.scheme hasPrefix:@"wx"]) {
        [WXApi handleOpenURL:url delegate:(id)self];
    }

    if ([url.scheme hasPrefix:@"wb"]) {
        [WeiboSDK handleOpenURL:url delegate:(id)self];
    }
}

#pragma mark - Register

+ (void)registerWechatWithAppId:(NSString*)appid {
    [WXApi registerApp:appid];
}

+ (void)registerWeiboWithAppId:(NSString*)appid {
    [WeiboSDK registerApp:appid];
}

#pragma mark - Share Function

+ (void)shareWithContent:(EDHShareContent*)content
                 channel:(EDHShareChannel)channel
              completion:(EDHShareCompletionBlock)completion {

    if (_isWaitingForResp) {
        //如果正在等待回调，则忽略此次分享请求
        return;
    }

    EDHShareOperation *operation = [[EDHShareOperation alloc] initWithShareContent:content
                                                                           channel:channel
                                                                        completion:completion];
    [_concurrentQueue addOperation:operation];

    [self p_manageAppDelegateNotifications];
}

+ (void)p_handleShareResponseWithState:(EDHShareResponseState)state {

    //由于openURL函数在appDidBecomeActivie之前调用，若此时立即结束此操作，会立即启动下一个操作，
    //这样会导致调起第三方App失败，顾在此延迟1秒
    EDHShareOperation *operation = [self p_currentExecutingOperation];
    [operation finishAfterSeconds:1 state:state];
}

#pragma mark - Share To Wechat

//分享到 微信好友
+ (BOOL)p_shareToWechatFriendWithContent:(EDHShareContent*)content {
    return [self p_shareToWechatWithContent:content scene:WXSceneSession];
}

//分享到微信朋友圈
+ (BOOL)p_shareToWechatTimelineWithContent:(EDHShareContent*)content {
    return [self p_shareToWechatWithContent:content scene:WXSceneTimeline];
}

//分享到 微信好友／微信朋友圈
+ (BOOL)p_shareToWechatWithContent:(EDHShareContent*)content scene:(int)scene {

    if (![WXApi isWXAppInstalled]) {
        [self p_handleShareResponseWithState:EDHShareResponseStateAppNotInstalled];
        return NO;
    }

    if (![WXApi isWXAppSupportApi]) {
        [self p_handleShareResponseWithState:EDHShareResponseStateAppNotSupportApi];
        return NO;
    }

    WXMediaMessage *message = [WXMediaMessage message];
    message.title = content.title;
    message.description = content.content;
    [message setThumbImage:[self p_appIcon]];//分享图片,大小不能超过32K

    WXWebpageObject *webObj = [WXWebpageObject object];
    webObj.webpageUrl = content.pageUrl;
    message.mediaObject = webObj;

    SendMessageToWXReq *request = [[SendMessageToWXReq alloc] init];
    request.bText = NO;//发送多媒体消息
    request.message = message;
    request.scene = scene;

    BOOL flag = [WXApi sendReq:request];
    if (!flag) {
        //由于微信调用失败，不会执行回调，顾此处直接将结果回调给调用者
        [self p_handleShareResponseWithState:EDHShareResponseStateFail];
    }

    return flag;
}

//微信请求的回调
+ (void)onResp:(BaseResp *)resp {

    if ([resp isKindOfClass:[SendMessageToWXResp class]]) {

        EDHShareResponseState state = EDHShareResponseStateFail;
        switch (resp.errCode) {
            case WXSuccess:
                state = EDHShareResponseStateSuccess;
                break;
            case WXErrCodeUserCancel:
                state = EDHShareResponseStateCancel;
                break;
            default:
                break;
        }

        [self p_handleShareResponseWithState:state];
    }
}

#pragma mark - Share to SMS

//分享到短信
+ (BOOL)p_shareToSMSWithContent:(EDHShareContent*)content {

    if(![MFMessageComposeViewController canSendText]) {
        [self p_handleShareResponseWithState:EDHShareResponseStateNotSupport];
        return NO;
    }

    dispatch_async(dispatch_get_main_queue(), ^{

        //构造分享内容
        NSString *pageUrlUTF8 = [content.pageUrl stringByRemovingPercentEncoding];

        NSString *message = content.content;
        if (!message) {
            message = pageUrlUTF8;
        } else {
            message = [message stringByAppendingFormat:@" %@",pageUrlUTF8];
        }

        //调起系统短信界面
        MFMessageComposeViewController * controller = [[MFMessageComposeViewController alloc] init];
        controller.body = message;
        controller.messageComposeDelegate = (id)self;

        //如果创建临时的window来展示短信界面，会由于window超出作用域后被销毁导致显示不出来的问题，顾此处使用全局变量来
        //保存window
        if (!_shareWindow) {
            _shareWindow = [[UIWindow alloc] initWithFrame:[UIScreen mainScreen].bounds];
            [_shareWindow setBackgroundColor:[UIColor clearColor]];
            _shareWindow.rootViewController = [[UIViewController alloc] init];
            [_shareWindow makeKeyAndVisible];
        }

        [_shareWindow.rootViewController presentViewController:controller
                                                   animated:YES
                                                 completion:nil];
    });

    return YES;
}

//分享到短信的回调
+ (void)messageComposeViewController:(MFMessageComposeViewController *)controller didFinishWithResult:(MessageComposeResult)result {

    [controller dismissViewControllerAnimated:YES completion:^{
        //FIXME:由于目前只有SMSVC才通过_shareWindow展示出来，顾当SMSVC消失时，同时将_shareWindow销毁
        _shareWindow = nil;
        [[(AppDelegate*)[UIApplication sharedApplication].delegate window] makeKeyAndVisible];
    }];

    EDHShareResponseState state = EDHShareResponseStateFail;
    switch (result) {
        case MessageComposeResultSent:
            state = EDHShareResponseStateSuccess;
            break;
        case MessageComposeResultCancelled:
            state = EDHShareResponseStateCancel;
            break;
        default:
            break;
    }
    [self p_handleShareResponseWithState:state];
}

#pragma mark - Share to Weibo

//分享到微博
+ (BOOL)p_shareToWeiboWithContent:(EDHShareContent*)content isShareInApp:(void(^)(BOOL isShareInApp))isShareInApp {

    if (isShareInApp) {
        isShareInApp([WeiboSDK isWeiboAppInstalled]);
    }

    WBAuthorizeRequest *authReq = [WBAuthorizeRequest request];
    authReq.redirectURI = kWeiboRedirectURI;
    authReq.scope = @"all";

    //由于url中的titile字段包含中文，如果直接分享给微博，微博不能将之识别问url有效部分，本可通过转码实现，但是微博限制
    //字数为140个汉字，转码后很可能会超限，导致分享失败，顾最终解决方案是trim掉url中的中文部分，再分享到微博
    NSArray *urlComponents = [content.pageUrl componentsSeparatedByString:@"&"];
    NSMutableArray *mutArray = [urlComponents mutableCopy];
    [urlComponents enumerateObjectsUsingBlock:^(NSString *obj, NSUInteger idx, BOOL * _Nonnull stop) {
        if ([obj hasPrefix:@"title="]) {
            [mutArray replaceObjectAtIndex:idx withObject:@"title="];
        }
    }];
    NSString *chineseTrimmedUrl = [mutArray componentsJoinedByString:@"&"];

    WBMessageObject *message = [WBMessageObject message];
    message.text = [NSString stringWithFormat:@"【%@】 %@",content.title,chineseTrimmedUrl];

    WBImageObject *image = [WBImageObject object];
    image.imageData = UIImagePNGRepresentation([self p_appIcon]);
    message.imageObject = image;

    WBSendMessageToWeiboRequest *req = [WBSendMessageToWeiboRequest requestWithMessage:message
                                                                              authInfo:authReq
                                                                          access_token:nil];
    req.shouldOpenWeiboAppInstallPageIfNotInstalled = NO;
    BOOL flag = [WeiboSDK sendRequest:req];
    if (!flag) {
        //由于微博调用失败，不会执行回调，顾此处直接将结果回调给调用者
        [self p_handleShareResponseWithState:EDHShareResponseStateFail];
    }

    return flag;
}

+ (void)didReceiveWeiboRequest:(WBBaseRequest *)request {
    //TODO:由于微博的delete非optional，顾此处做空实现
}

//分享到微博的回调
+ (void)didReceiveWeiboResponse:(WBBaseResponse *)response {

    EDHShareResponseState state = EDHShareResponseStateFail;
    switch (response.statusCode) {
        case WeiboSDKResponseStatusCodeSuccess:
            state = EDHShareResponseStateSuccess;
            break;
        case WeiboSDKResponseStatusCodeUserCancel:
            state = EDHShareResponseStateCancel;
            break;
        default:
            break;
    }
    [self p_handleShareResponseWithState:state];
}

#pragma mark - Functions

+ (UIImage*)p_appIcon {
    return [UIImage imageNamed:@"share_app_icon"];
}

+ (EDHShareOperation*)p_currentExecutingOperation {

    EDHShareOperation *operation = nil;
    for (EDHShareOperation *obj in [_concurrentQueue operations]) {
        if ([obj isExecuting]) {
            operation = obj;
            break;
        }
    }

    return operation;
}

#pragma mark - Notificaiotns

+ (void)p_manageAppDelegateNotifications {

    if ([_concurrentQueue operations].count > 0) {
        [self p_registerAppDelegateNotifications];
    } else {
        [[NSNotificationCenter defaultCenter] removeObserver:self];
    }
}

+ (void)p_registerAppDelegateNotifications {
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(p_handleAppWillEnterForegroundNotification:)
                                                 name:UIApplicationWillEnterForegroundNotification
                                               object:nil];

    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(p_handleAppDidBecomeActiveNotification:)
                                                 name:UIApplicationDidBecomeActiveNotification
                                               object:nil];
}

+ (void)p_handleAppWillEnterForegroundNotification:(NSNotification*)notification {
    _isWaitingForResp = YES;
}

+ (void)p_handleAppDidBecomeActiveNotification:(NSNotification*)notification {
    _isWaitingForResp = NO;
}

@end
