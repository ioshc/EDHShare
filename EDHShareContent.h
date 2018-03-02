//
//  EDHShareContent.h
//  EDHShare
//
//  Created by eden on 2017/6/15.
//  Copyright © 2017年 Eden. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface EDHShareContent : NSObject

@property (nonatomic, copy) NSString *title;//分享信息标题
@property (nonatomic, copy) NSString *content;//分享信息描述
@property (nonatomic, copy) NSString *imgUrl;//分享图片url地址
@property (nonatomic, copy) NSString *pageUrl;//分享链接url地址

- (instancetype)initWithTitle:(NSString *)title
                      content:(NSString *)content
                       imgUrl:(NSString *)imgUrl
                      pageUrl:(NSString *)pageUrl;
@end
