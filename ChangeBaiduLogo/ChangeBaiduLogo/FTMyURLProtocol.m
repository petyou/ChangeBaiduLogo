//
//  FTMyURLProtocol.m
//  funnyTry
//
//  Created by SGQ on 2018/10/31.
//  Copyright © 2018年 GQ. All rights reserved.
//

#import "FTMyURLProtocol.h"
#import <WebKit/WebKit.h>

static NSString * const kHandedRequestKey = @"kHandedRequestKey";

static NSString * const kSourceBaiDuLogoURL  = @"https://m.baidu.com/static/index/plus/plus_logo.png";
static NSString * const kRedirectBaiduURL = @"https://timgsa.baidu.com/timg?image&quality=80&size=b9999_10000&sec=1541079201966&di=3747fedd92f73e68a37fb0a986a7d2a0&imgtype=0&src=http%3A%2F%2Fpic34.photophoto.cn%2F20150112%2F0034034439579927_b.jpg";
static NSString * const kUseLocalDataURL = @"https://www.shigaoqiang.com";


@interface FTMyURLProtocol () <NSURLSessionDelegate>
@property (nonnull, strong) NSURLSessionDataTask *task;
@end

@implementation FTMyURLProtocol

/// 决定是否对这个request进行处理
+ (BOOL)canInitWithRequest:(NSURLRequest*)request {
    if ([NSURLProtocol propertyForKey:kHandedRequestKey inRequest:request]) {return NO; }
    NSLog(@"%@", request.URL.absoluteString);
    NSString *scheme = [[request URL] scheme];
    if (([scheme caseInsensitiveCompare:@"http"]  == NSOrderedSame || [scheme caseInsensitiveCompare:@"https"] == NSOrderedSame )) {
        return YES;
    }
    return NO;
}


+ (BOOL)requestIsCacheEquivalent:(NSURLRequest *)a toRequest:(NSURLRequest *)b {
    return [super requestIsCacheEquivalent:a toRequest:b];
}

+ (NSURLRequest*)canonicalRequestForRequest:(NSURLRequest*)request {
    NSMutableURLRequest *mutableReqeust = [request mutableCopy];
    
    //request截取重定向
    if ([request.URL.absoluteString isEqualToString:kSourceBaiDuLogoURL]) {
        NSURL* url1 = [NSURL URLWithString:kUseLocalDataURL];
        mutableReqeust = [NSMutableURLRequest requestWithURL:url1];
    }
    
    return mutableReqeust;
}

- (void)startLoading
{
    NSMutableURLRequest *request = [self.request mutableCopy];
    [NSURLProtocol setProperty:@(YES) forKey:kHandedRequestKey inRequest:request];

    if ([request.URL.absoluteString isEqualToString:kUseLocalDataURL]) {
        NSURLResponse *response = [[NSURLResponse alloc] initWithURL:[request URL]
                                                            MIMEType:@"image/png"
                                               expectedContentLength:-1
                                                    textEncodingName:nil];
        
        NSString *imagePath = [[NSBundle mainBundle] pathForResource:@"bftt" ofType:@"png"];
        NSData *data = [NSData dataWithContentsOfFile:imagePath];
        
        [[self client] URLProtocol:self didReceiveResponse:response cacheStoragePolicy:NSURLCacheStorageNotAllowed];
        [[self client] URLProtocol:self didLoadData:data];
        [[self client] URLProtocolDidFinishLoading:self];
        
    } else {
        NSURLSession *session = [NSURLSession sessionWithConfiguration:[NSURLSessionConfiguration defaultSessionConfiguration] delegate:self delegateQueue:nil];
        self.task = [session dataTaskWithRequest:self.request];
        [self.task resume];
    }
}

- (void)stopLoading
{
    if (self.task != nil)
    {
        [self.task  cancel];
    }
}


- (void)URLSession:(NSURLSession *)session dataTask:(NSURLSessionDataTask *)dataTask didReceiveResponse:(NSURLResponse *)response completionHandler:(void (^)(NSURLSessionResponseDisposition))completionHandler {
    [[self client] URLProtocol:self didReceiveResponse:response cacheStoragePolicy:NSURLCacheStorageNotAllowed];
    
    completionHandler(NSURLSessionResponseAllow);
}

- (void)URLSession:(NSURLSession *)session dataTask:(NSURLSessionDataTask *)dataTask didReceiveData:(NSData *)data {
    [[self client] URLProtocol:self didLoadData:data];
}

- (void)URLSession:(NSURLSession *)session task:(NSURLSessionTask *)task didCompleteWithError:(nullable NSError *)error {
    [self.client URLProtocolDidFinishLoading:self];
}

#pragma mark - register fow WKWebView
+ (void)registerForWKWebView {
    Class class = [[[WKWebView new] valueForKey:@"browsingContextController"] class];
    SEL selector = NSSelectorFromString(@"registerSchemeForCustomProtocol:");;
    if ([(id)class respondsToSelector:selector]) {
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Warc-performSelector-leaks"
        [(id)class performSelector:selector withObject:@"http"];
        [(id)class performSelector:selector withObject:@"https"];
#pragma clang diagnostic pop
    }
}

+ (void)unRegisterForWKWebView {
    Class class = [[[WKWebView new] valueForKey:@"browsingContextController"] class];
    SEL selector = NSSelectorFromString(@"unregisterSchemeForCustomProtocol:");
    if ([(id)class respondsToSelector:selector]) {
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Warc-performSelector-leaks"
        [(id)class performSelector:selector withObject:@"http"];
        [(id)class performSelector:selector withObject:@"https"];
#pragma clang diagnostic pop
    }
}

@end
