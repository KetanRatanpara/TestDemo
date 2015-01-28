//
//  WebImageHelper.h
//  TestDemo
//
//  Created by Ketan on 28/01/15.
//  Copyright (c) 2015 Ketan. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>

@interface WebImageHelper : NSObject

@property (strong, nonatomic) NSMutableDictionary *dicCaches;

+ (instancetype)sharedManager;

- (void)loadImageWithStrUrl:(NSString *)strUrl
               forImageView:(UIImageView *)imageView
                  queueName:(char *)queueName
          completionHandler:(void (^)(UIImage *image, NSError *error))handler;

- (void)createWebImageHelperCachesDirectory;

- (void)emptyWebImageHelperCachesDirectory;

@end

@interface NSString (DDXML)

- (NSString *)getMD5;

@end
