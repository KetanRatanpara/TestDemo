//
//  WebImageHelper.m
//  TestDemo
//
//  Created by Ketan on 28/01/15.
//  Copyright (c) 2015 Ketan. All rights reserved.
//

#import "WebImageHelper.h"
#import <CommonCrypto/CommonDigest.h>

@implementation WebImageHelper

+ (instancetype)sharedManager
{
    static WebImageHelper *sharedWebImageHelperManager = nil;
    
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        sharedWebImageHelperManager = [[self alloc] init];
    });
    
    return sharedWebImageHelperManager;
}

- (instancetype)init
{
    if (self = [super init])
        self.dicCaches = [NSMutableDictionary new];
    
    return self;
}

- (void)loadImageWithStrUrl:(NSString *)strUrl
               forImageView:(UIImageView *)imageView
                  queueName:(char *)queueName
          completionHandler:(void (^)(UIImage *image, NSError *error))handler
{
    __weak UIImageView *weakImageView = imageView;
    strUrl = (strUrl && (![strUrl isEqual:[NSNull null]])) ? strUrl : @"";
    NSURL *url = [NSURL URLWithString:strUrl];
    
    if (!url || !url.scheme || !url.host)
    {
        [self setImage:[UIImage imageNamed:strUrl] ofImageView:weakImageView];
        if (handler)
            handler([UIImage imageNamed:strUrl], nil);
        return;
    }
    
    weakImageView.image = nil;
    UIImage *cachedImage = [self getCachedImageForStrUrl:strUrl];
    
    if (cachedImage)
    {
        [self setImage:cachedImage ofImageView:weakImageView];
        if (handler)
            handler(cachedImage, nil);
        return;
    }
    
    __block UIActivityIndicatorView *activityIndicator = [[UIActivityIndicatorView alloc]
                                                          initWithActivityIndicatorStyle:
                                                          UIActivityIndicatorViewStyleWhite];
    activityIndicator.center = CGPointMake(weakImageView.bounds.size.width / 2,
                                           weakImageView.bounds.size.height / 2);
    activityIndicator.color = [UIColor colorWithRed:0.88 green:0.88 blue:0.88 alpha:1];
    [activityIndicator startAnimating];
    [activityIndicator setHidesWhenStopped:YES];
    [weakImageView addSubview:activityIndicator];
    
    NSMutableURLRequest *request = [[NSMutableURLRequest alloc] initWithURL:url];
    [request addValue:@"image/*" forHTTPHeaderField:@"Accept"];
    
    [NSURLConnection sendAsynchronousRequest:request
                                       queue:[NSOperationQueue new]
                           completionHandler:^(NSURLResponse *res, NSData *imgData, NSError *err) {
                               dispatch_async(dispatch_get_main_queue(), ^{
                                   UIImage *image = nil;
                                   if (imgData && !err)
                                   {
                                       image = [UIImage imageWithData:imgData];
                                       [self createCacheOfImage:image forStrUrl:strUrl];
                                   }
                                   
                                   [self setImage:image ofImageView:weakImageView];
                                   [activityIndicator stopAnimating];
                                   [activityIndicator removeFromSuperview];
                                   activityIndicator = nil;
                                   
                                   if (handler)
                                       handler(image, err);
                               });
                           }];
}

- (UIImage *)getCachedImageForStrUrl:(NSString *)strUrl
{
    NSString *strKey = [strUrl getMD5];
    UIImage *image = [self.dicCaches objectForKey:strKey];
    
    if (!image)
    {
        NSString *imagePath = [[self getWebImageHelperCachesDirectoryPath]
                               stringByAppendingPathComponent:[NSString stringWithFormat:@"%@.png",
                                                               strKey]];
        
        if ([[NSFileManager defaultManager] fileExistsAtPath:imagePath])
        {
            image = [UIImage imageWithContentsOfFile:imagePath];
            [self.dicCaches setObject:image forKey:strKey];
        }
    }
    
    return image;
}

- (NSString *)getWebImageHelperCachesDirectoryPath
{
    NSArray *paths = NSSearchPathForDirectoriesInDomains(NSCachesDirectory, NSUserDomainMask, YES);
    NSString *cachesDirectoryPath = paths.firstObject;
    return [cachesDirectoryPath stringByAppendingPathComponent:@"WebImageHelperCaches"];
}

- (void)createWebImageHelperCachesDirectory
{
    NSString *path = [self getWebImageHelperCachesDirectoryPath];
    if (![[NSFileManager defaultManager] fileExistsAtPath:path])
    {
        NSError *error = nil;
        BOOL isCreated = [[NSFileManager defaultManager] createDirectoryAtPath:path
                                                   withIntermediateDirectories:NO
                                                                    attributes:nil
                                                                         error:&error];
        if (!isCreated || error)
            NSLog(@"\n%s\n%@\n", __FUNCTION__, error.localizedDescription);
    }
}

- (void)emptyWebImageHelperCachesDirectory
{
    NSFileManager *fileManager = [NSFileManager defaultManager];
    NSString *directory = [self getWebImageHelperCachesDirectoryPath];
    NSError *error = nil;
    NSArray *allFiles = [fileManager contentsOfDirectoryAtPath:directory error:&error];
    
    if (allFiles && !error)
    {
        for (NSString *file in allFiles)
        {
            BOOL success = [fileManager removeItemAtPath:[NSString stringWithFormat:@"%@/%@",
                                                          directory, file]
                                                   error:&error];
            if (!success || error)
                NSLog(@"\n%s\n%@\n", __FUNCTION__, error.localizedDescription);
        }
    }
    else
        NSLog(@"\n%s\n%@\n", __FUNCTION__, error.localizedDescription);
}

- (void)setImage:(UIImage *)image ofImageView:(UIImageView *)imageView
{
    dispatch_async(dispatch_get_main_queue(), ^{
        imageView.image = image ? image : [UIImage imageNamed:@"Not_Found.png"];
    });
}

- (void)createCacheOfImage:(UIImage *)image forStrUrl:(NSString *)strUrl
{
    NSString *strKey = [strUrl getMD5];
    if (image)
    {
        NSString *imagePath = [[self getWebImageHelperCachesDirectoryPath]
                               stringByAppendingPathComponent:[NSString stringWithFormat:@"%@.png",
                                                               strKey]];
        
        if ([UIImagePNGRepresentation(image) writeToFile:imagePath atomically:YES])
            [self.dicCaches setObject:image forKey:strKey];
    }
}

@end

@implementation NSString (DDXML)

- (NSString *)getMD5
{
    const char *str = [self UTF8String];
    unsigned char result[CC_MD5_DIGEST_LENGTH];
    
    CC_MD5(str, (CC_LONG)strlen(str), result);
    NSMutableString *resultStr = [NSMutableString stringWithCapacity:CC_MD5_DIGEST_LENGTH * 2];
    
    for (int i = 0; i < CC_MD5_DIGEST_LENGTH; i++)
        [resultStr appendFormat:@"%02x", result[i]];
    
    return resultStr;
}

@end
