//
//  ViewController.m
//  ChangeBaiduLogo
//
//  Created by SGQ on 2018/11/6.
//  Copyright © 2018年 shigaoqiang. All rights reserved.
//

#import "ViewController.h"
#import <WebKit/WebKit.h>
#import "FTMyURLProtocol.h"

@interface ViewController ()
@property (strong, nonatomic) IBOutlet WKWebView *webView;

@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    [NSURLProtocol registerClass:[FTMyURLProtocol class]];
    [FTMyURLProtocol registerForWKWebView];
    
    NSURL *url = [NSURL URLWithString:@"https://www.baidu.com"];
    NSURLRequest *request = [NSURLRequest requestWithURL:url];
    [self.webView loadRequest:request];
}


- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}


@end
