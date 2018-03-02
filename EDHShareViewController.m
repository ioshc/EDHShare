//
//  EDHShareViewController.m
//  EDHShare
//
//  Created by eden on 2017/6/15.
//  Copyright © 2017年 Eden. All rights reserved.
//

#import "EDHShareViewController.h"
#import "EDHShareActionHandler.h"
#import "EDHShareItemCell.h"

#import "UIViewController+Transition.h"

static NSString *shareItemCell = @"EDHShareItemCell";

@interface EDHShareViewController ()<
    UICollectionViewDataSource,
    UICollectionViewDelegate
>

@property (nonatomic, weak) IBOutlet UICollectionView *collectionView;
@property (nonatomic, weak) IBOutlet NSLayoutConstraint *collectionViewHeightConstraint;

@property (nonatomic, strong) NSArray *channels;
@property (nonatomic, strong) EDHShareContent *shareContent;

@end

@implementation EDHShareViewController

#pragma mark - Life Cycle

+ (void)showOnHostVC:(UIViewController*)hostVC
    withShareContent:(EDHShareContent*)shareContent
       shareChannels:(NSArray<NSNumber*>*)channels {

    if (!hostVC || !shareContent || channels.count == 0) {
        return;
    }

    EDHShareViewController *shareVC = [[EDHShareViewController alloc] initWithNibName:@"EDHShareViewController"
                                                                               bundle:nil];
    shareVC.channels = channels;
    shareVC.shareContent = shareContent;

    [hostVC edh_presentOverCurrentContextViewController:shareVC
                                               animated:YES
                                             completion:nil];
}

- (void)viewDidLoad {
    [super viewDidLoad];

    [self p_setupColletionView];
}

- (void)p_setupColletionView {

    const NSInteger maxCountOfItemsPerLine = 4;
    const CGFloat lineHeight = 100.0f;

    //计算collectionView的高度
    NSInteger lineCount = (_channels.count / maxCountOfItemsPerLine);
    if ((_channels.count % maxCountOfItemsPerLine) != 0) {
        //不能被maxCountOfItemsPerLine整除，则表示还需要增加一行
        lineCount++;
    }
    _collectionViewHeightConstraint.constant = lineCount * lineHeight;

    UICollectionViewFlowLayout *layout = [[UICollectionViewFlowLayout alloc] init];
    layout.itemSize = CGSizeMake((SSCSCREEN_WIDTH / MIN(maxCountOfItemsPerLine,_channels.count)) - 0.1,
                                 lineHeight);
    layout.minimumLineSpacing = 0;
    layout.minimumInteritemSpacing = 0;
    _collectionView.collectionViewLayout = layout;

    [_collectionView registerNib:[UINib nibWithNibName:shareItemCell bundle:nil]
      forCellWithReuseIdentifier:shareItemCell];
}

#pragma mark - UICollectionViewDataSource

- (NSInteger)collectionView:(UICollectionView *)collectionView numberOfItemsInSection:(NSInteger)section {
    return _channels.count;
}

- (UICollectionViewCell *)collectionView:(UICollectionView *)collectionView cellForItemAtIndexPath:(NSIndexPath *)indexPath {

    EDHShareItemCell *cell = [collectionView dequeueReusableCellWithReuseIdentifier:shareItemCell
                                                                       forIndexPath:indexPath];
    [self p_setupCell:cell withChannel:[_channels[indexPath.row] integerValue]];
    return cell;
}

- (void)p_setupCell:(EDHShareItemCell*)cell withChannel:(EDHShareChannel)channel {

    NSString *title = nil;
    UIImage *image = nil;
    switch (channel) {
        case EDHShareChannelWechatFriend:
            title = @"微信";
            image = [UIImage imageNamed:@"share_icon_wechat_friend"];
            break;
        case EDHShareChannelWechatTimeline:
            title = @"微信朋友圈";
            image = [UIImage imageNamed:@"share_icon_wechat_timeline"];
            break;
        case EDHShareChannelSMS:
            title = @"短信";
            image = [UIImage imageNamed:@"share_icon_sms"];
            break;
        case EDHShareChannelWeibo:
            title = @"微博";
            image = [UIImage imageNamed:@"share_icon_weibo"];
            break;
        default:
            break;
    }

    cell.titleLabel.text = title;
    cell.iconImgView.image = image;
}

#pragma mark - UICollectionViewDelegate

///iphoneX底部留空
- (void)scrollViewDidChangeAdjustedContentInset:(UIScrollView *)scrollView {
    if (@available(iOS 11.0, *)) {
        _collectionViewHeightConstraint.constant += scrollView.adjustedContentInset.bottom;
    }
}

- (void)collectionView:(UICollectionView *)collectionView didSelectItemAtIndexPath:(NSIndexPath *)indexPath {
    [collectionView deselectItemAtIndexPath:indexPath animated:YES];

    [EDHShareActionHandler shareWithContent:self.shareContent
                                    channel:[_channels[indexPath.row] integerValue]
                                 completion:^(EDHShareResponseState state) {
                                     switch (state) {
                                         case EDHShareResponseStateSuccess:
                                             [self.view showToastMessage:@"分享成功～"];
                                             break;
                                         case EDHShareResponseStateCancel:
                                             [self.view showToastMessage:@"用户取消分享～"];
                                             break;
                                         case EDHShareResponseStateUserAbandon:
                                             //不做任何提示
                                             break;
                                         case EDHShareResponseStateAppNotInstalled:
                                             [self.view showToastMessage:@"未安装客户端～"];
                                             break;
                                         default:
                                             [self.view showToastMessage:@"分享失败～"];
                                             break;
                                     }
                                 }];
}

#pragma mark - Dismiss

- (void)touchesBegan:(NSSet<UITouch *> *)touches withEvent:(UIEvent *)event {
    [self dismissViewControllerAnimated:YES completion:nil];
}

#pragma mark - Functions

+ (NSArray*)allSupportedChannels {
    return @[@(EDHShareChannelWechatFriend),
             @(EDHShareChannelWechatTimeline),
             @(EDHShareChannelWeibo),
             @(EDHShareChannelSMS)];
}

@end
