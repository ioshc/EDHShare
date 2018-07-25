//
//  EDHShareContent.h
//  EDHShare
//
//  Created by eden on 2017/6/15.
//  Copyright © 2017年 Eden. All rights reserved.
//

#import <Foundation/Foundation.h>

/**
 分享内容的类型

 - EDHShareContentTypeWebPage: 分享一个网页
 - EDHShareContentTypeImage: 分享一张图片
 */
typedef NS_ENUM(NSUInteger, EDHShareContentType) {
    EDHShareContentTypeWebPage,
    EDHShareContentTypeImage,
};

@interface EDHShareContent : NSObject

@property (nonatomic, copy) NSString *title;//分享信息标题
@property (nonatomic, copy) NSString *content;//分享信息描述
@property (nonatomic, copy) NSString *imgUrl;//分享图片url地址
@property (nonatomic, copy) NSString *pageUrl;//分享链接url地址

@property (nonatomic, strong) UIImage *image;//分享的图片，大小不能超过10M

@property (nonatomic, readonly) EDHShareContentType type;//分享内容类型

/**
 创建一个网页分享内容对象，

 @param title 分享信息标题
 @param content 分享信息标题
 @param imgUrl 分享信息标题
 @param pageUrl 分享链接url地址
 @return 新的分享内容对象
 */
- (instancetype)initWithTitle:(NSString *)title
                      content:(NSString *)content
                       imgUrl:(NSString *)imgUrl
                      pageUrl:(NSString *)pageUrl;

- (instancetype)initWithImage:(UIImage *)image;

@end
