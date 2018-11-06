//
//  FTMyURLProtocol.h
//  funnyTry
//
//  Created by SGQ on 2018/10/31.
//  Copyright © 2018年 GQ. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface FTMyURLProtocol : NSURLProtocol

+ (void)registerForWKWebView;

+ (void)unRegisterForWKWebView;

@end
