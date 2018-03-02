//
//  EDHShareContent.m
//  EDHShare
//
//  Created by eden on 2017/6/15.
//  Copyright © 2017年 Eden. All rights reserved.
//

#import "EDHShareContent.h"

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
    }
    return self;
}

@end
