### Target
本文想做的事是, 在手机端使用 `webView` 加载百度首页, 并使加载出来的百度logo更换为任意的图片. 

### 原理
原理是使用 `NSURLProtocol` 监听所有 `URL Loading System` 中发出 `request` 请求, 对于指定的URL, 使之重定向到另外一个URL. 达到更换图片的目的.

### NSURLProtocol介绍
`NSURLProtocol` 是属于 `Foundation` 框架里的 [URL Loading System](https://developer.apple.com/documentation/foundation/url_loading_system) 的一部分. 它是一个抽象类, 需要继承它后, 重写一系列父类的方法, 且在向系统注册后, 就可以监听到所有来自 `URL Loading System` 中发出 `request` 请求, 包括使用 `NSURLConnection` 和 `NSURLSession ` 发出去的请求, 使用这两者的第三方框架就也能监听到, 比如 `AFNetWorking`. 而视图方面, 通过`UIWebView`、`WKWebView` 发出去的请求也能被监听到.

![URL Loading System](https://upload-images.jianshu.io/upload_images/4103407-c41ab298ca6af432.png?imageMogr2/auto-orient/strip%7CimageView2/2/w/1240)


监听到后我们可以修改原来 `requeset`, 比如给它添加参数, 或者干脆重定向到新的资源. 也可以对返回的 `response` 进行修改. 总之, 是否返回数据, 返回什么数据, 已经由我们决定了.

#### 如何向系统注册监听
 对于 `UIWebView` 和 `NSURLConnection` 只需要构建 `NSURLProtocol ` 的子类, 在子类中重载必要的方法, 并向系统注册`[NSURLProtocol registerClass:[FTMyURLProtocol class]];` 即可监听.

 
```
// .h
#import <Foundation/Foundation.h>

@interface FTMyURLProtocol : NSURLProtocol

@end

// .m
@implementation FTMyURLProtocol

/// 决定是否对这个request进行处理, 根据情况返回 YES or NO
+ (BOOL)canInitWithRequest:(NSURLRequest*)request {
    return YES;
}

/// 可以在此修改原来的request.
+ (NSURLRequest*)canonicalRequestForRequest:(NSURLRequest*)request {
    return request;
}

/// 可以在此修改response
- (void)startLoading {
  /// ...
}

@end
```

对于 `WKWebView`,除了上述操作外, 由于其基于 `wekkit` 内核, 使用到了 `WKBrowsingContextController` 和 `registerSchemeForCustomProtocol`, 我们需要通过反射的方式拿到了私有的 `class` & `selector`, 通过 `kvc` 取到`browsingContextController`. 通过把注册把 `http` 和 `https` 请求交给 `NSURLProtocol` 处理.

```
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

```

对于 `NSURLSession `, 除了上述操作外, 注册方式会不同.

```
- (void)exchangeSessionConfigurationGetter {
    Class cls = NSClassFromString(@"__NSCFURLSessionConfiguration") ?: NSClassFromString(@"NSURLSessionConfiguration");
    [self swizzleSelector:@selector(protocolClasses) fromClass:cls toClass:[self class]];
}

- (void)swizzleSelector:(SEL)selector fromClass:(Class)original toClass:(Class)stub {
    
    Method originalMethod = class_getInstanceMethod(original, selector);
    Method stubMethod = class_getInstanceMethod(stub, selector);
    if (!originalMethod || !stubMethod) {
        [NSException raise:NSInternalInconsistencyException format:@"Couldn't load NSURLSession hook."];
    }
    method_exchangeImplementations(originalMethod, stubMethod);
}

- (NSArray *)protocolClasses {
    return @[[FTMyURLProtocol class]];
}
```

介绍注册后, 我们来实现既定的需求吧.(在手机端使用 `webView` 加载百度首页, 并使加载出来的百度logo更换为任意的图片.)

首先我们已经知道在 `canInitWithRequest:` 这个方法中可以决定是否对拦截的 `request`进行处理. 这里我们处理所有的 `http` 和 `https` 请求(`URL Loading System` 可以发出的请求种类有 `ftp://` `http://` `https://` `file://` `data://`). 当让如果有必要我们也可以指定某个 URL 链接进行处理.

```
+ (BOOL)canInitWithRequest:(NSURLRequest*)request {
    if ([NSURLProtocol propertyForKey:kHandedRequestKey inRequest:request]) {return NO; }
    NSLog(@"%@", request.URL.absoluteString);
    NSString *scheme = [[request URL] scheme];
    if (([scheme caseInsensitiveCompare:@"http"]  == NSOrderedSame || [scheme caseInsensitiveCompare:@"https"] == NSOrderedSame )) {
        return YES;
    }
    return NO;
}
```

刚开始我已经通过log, 将百度logo的图片链接找了出来,于是在这个方法里面我们将其重定向为本地资源

```
static NSString * const kSourceBaiDuLogoURL  = @"https://m.baidu.com/static/index/plus/plus_logo.png";
static NSString * const kUseLocalDataURL = @"https://www.shigaoqiang.com";
```

```
+ (NSURLRequest*)canonicalRequestForRequest:(NSURLRequest*)request {
    NSMutableURLRequest *mutableReqeust = [request mutableCopy];
    
    // 如果是百度logo的链接则重定向
    if ([request.URL.absoluteString isEqualToString:kSourceBaiDuLogoURL]) {
        NSURL* url1 = [NSURL URLWithString:kUseLocalDataURL];
        mutableReqeust = [NSMutableURLRequest requestWithURL:url1];
    }
    
    return mutableReqeust;
}
```

在这个方法里面可以将本地的数据返回给上层. 可以看到我将本地的一张图片数据返回给了上层.当然让你也可以将其它的网络图片返回亦可.

```
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

- (void)stopLoading {
    if (self.task != nil) {
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
```

效果如图

![本地图片](https://upload-images.jianshu.io/upload_images/4103407-81e1b89803728a46.PNG?imageMogr2/auto-orient/strip%7CimageView2/2/w/1240)  

![网络图片](https://upload-images.jianshu.io/upload_images/4103407-3430ab51e962f828.PNG?imageMogr2/auto-orient/strip%7CimageView2/2/w/1240)




