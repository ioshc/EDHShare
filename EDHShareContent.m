//
//  EDHShareContent.m
//  EDHShare
//
//  Created by eden on 2017/6/15.
//  Copyright © 2017年 Eden. All rights reserved.
//

#import "EDHShareContent.h"

@interface EDHShareContent()

@property (nonatomic) EDHShareContentType type;

@end

@implementation EDHShareContent

- (instancetype)initWithTitle:(NSString *)title
                      content:(NSString *)content
                       imgUrl:(NSString *)imgUrl
                      pageUrl:(NSString *)pageUrl {

    self = [super init];
    if (self) {
        self.title = title;
        self.content = content;
        self.imgUrl = imgUrl;
        self.pageUrl = pageUrl;
        self.type = EDHShareContentTypeWebPage;
    }
    return self;
}

- (instancetype)initWithImage:(UIImage *)image {

    if (!image) {
        return nil;
    }

    self = [super init];
    if (self) {
        self.image = image;
        self.type = EDHShareContentTypeImage;
    }
    return self;
}

@end
