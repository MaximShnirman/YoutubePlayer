//
//  VimeoPlayerView.m
//  YoutubePlayer
//
//  Created by Maxim Shnirman on 14/06/2021.
//  Copyright © 2021 Maxim Shnirman. All rights reserved.
//

#import "VimeoPlayerView.h"
#import <WebKit/WebKit.h>

static BOOL kAutoPlay = YES;

@interface VimeoPlayerView () <WKNavigationDelegate>
@property (nonatomic, strong) WKWebView *webView;
@property (nonatomic, strong) NSURL *origin;
@end

@implementation VimeoPlayerView

#pragma mark - cycle
- (instancetype)init {
    if (self = [super init]) {
        self.autoresizingMask = (UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight);
    }
    return self;
}

- (void)dealloc {
 
}

- (void)layoutSubviews {
    self.webView.frame = CGRectMake(0, 0, self.frame.size.width, self.frame.size.height);
    [self.webView layoutSubviews];
    [super layoutSubviews];
}

- (void)willMoveToSuperview:(UIView *)newSuperview {
    [super willMoveToSuperview:newSuperview];
//    [self addSpinner];
}

#pragma mark - public
//- (void)setStateDelegate:(id<PlayerStateProtocol>)delegate {
//    _stateDelegate = delegate;
//}
//
//- (void)setErrorDelegate:(id<PlayerErrorProtocol>)delegate {
//    _errorDelegate = delegate;
//}

- (void)loadVideoWithId:(NSString *)videoId {
    NSString *player = [self player];
    NSString *playerParams = [self playerParamWithVideoId:videoId autoPlay:kAutoPlay];
    
    if (player && playerParams) {
        NSString *embedHTML = [NSString stringWithFormat:player, playerParams];
        self.webView.userInteractionEnabled = YES;
        [self.webView loadHTMLString:embedHTML baseURL:self.origin];
    } else {
        NSLog(@"there was a problem creating the webView");
    }
}

#pragma mark - notifications
//- (void)onEnterFullScreen {
//    [self invocator:@selector(playerEnteredFullscreen:)];
//}
//
//- (void)onCloseFullScreen {
//    [self invocator:@selector(playerExitedFullscreen:)];
//}

#pragma mark - private getters
- (NSURL *)origin {
    if (!_origin) {
        NSString *stringURL = [[NSString stringWithFormat:@"https://%@", @"vimeo"] lowercaseString];
        _origin = [NSURL URLWithString:stringURL];
    }
    return _origin;
}

- (NSString *_Nullable)player {
    NSString *html = [[NSBundle mainBundle] pathForResource:@"vimeo" ofType:@"html"];
    NSError *jsonRenderingError = nil;
    NSString *player = [NSString stringWithContentsOfFile:html encoding:NSUTF8StringEncoding error:&jsonRenderingError];
    
    if (jsonRenderingError) {
        NSLog(@"error creating player from html: %@", jsonRenderingError);
        return nil;
    }
    
    return player;
}

- (NSString *_Nullable)playerParamWithVideoId:(NSString *)videoId autoPlay:(BOOL)autoplay {
    NSError *jsonRenderingError = nil;
    NSDictionary *playerParams = [self playerParams:videoId autoPlay:autoplay];
    NSData *jsonData = [NSJSONSerialization dataWithJSONObject:playerParams options:NSJSONWritingPrettyPrinted error:&jsonRenderingError];
    
    if (jsonRenderingError) {
        NSLog(@"error creating player params: %@", jsonRenderingError);
        return nil;
    }
    
    return [[NSString alloc] initWithData:jsonData encoding:NSUTF8StringEncoding];
}

- (NSDictionary *)playerParams:(NSString *)videoId autoPlay:(BOOL)autoPlay {
//   options: ["autopause", "autoplay", "background", "byline", "color", "controls", "dnt", "height", "id", "loop", "maxheight", "maxwidth", "muted", "playsinline", "portrait", "responsive", "speed", "texttrack", "title", "transparent", "url", "width"];

    NSString *urlString = [NSString stringWithFormat:@"https://vimeo.com/%@", videoId];
    return @{
        @"url": urlString,
        @"autoplay": @(autoPlay),
        @"width": @"1000",
        @"playsinline": @(true),
        @"muted": @(true),
        @"byline": @(true),
        @"title": @(true),
        @"background": @(true),
        @"loop": @(false),
        @"controls": @(true)
    };
}

- (WKWebView *)webView {
    if (!_webView) {
        WKWebViewConfiguration *config = [self wkConfiguration];
        _webView = [self wkWebView:config];
        [self addSubview:_webView];
    }
    
    return _webView;
}

- (WKWebView *)wkWebView:(WKWebViewConfiguration *)config {
    WKWebView *webView = [[WKWebView alloc] initWithFrame:CGRectZero configuration:config];
    webView.navigationDelegate = self;
    webView.userInteractionEnabled = NO;
    webView.scrollView.scrollEnabled = NO;
    webView.backgroundColor = [UIColor clearColor];
    
    for (UIView *view in _webView.subviews) {
        view.backgroundColor = [UIColor clearColor];
    }
    
    return webView;
}

- (WKWebViewConfiguration *)wkConfiguration {
    WKWebViewConfiguration *config = [[WKWebViewConfiguration alloc] init];
    config.allowsInlineMediaPlayback = YES;
    config.mediaTypesRequiringUserActionForPlayback = WKAudiovisualMediaTypeNone;
    
    return config;
}

#pragma mark - private helpers
//- (void)addSpinner {
//    self.spinner = [[UIActivityIndicatorView alloc] initWithActivityIndicatorStyle:UIActivityIndicatorViewStyleLarge];
//    [self.spinner setCenter:self.center];
//    [self.spinner startAnimating];
//    [self addSubview:self.spinner];
//}
//
//- (void)removeSpinner {
//    [self.spinner stopAnimating];
//    [self.spinner removeFromSuperview];
//}

#pragma mark - selector invocator
//- (void)invocator:(SEL)selector {
//    if (self.stateDelegate && [self.stateDelegate respondsToSelector:selector]) {
//#pragma clang diagnostic push
//#pragma clang diagnostic ignored "-Warc-performSelector-leaks"
//        [self.stateDelegate performSelector:selector withObject:self];
//#pragma clang diagnostic pop
//    }
//}
//
//- (void)errorInvocator:(SEL)selector error:(NSError *)error {
//    if (self.errorDelegate && [self.errorDelegate respondsToSelector:selector]) {
//#pragma clang diagnostic push
//#pragma clang diagnostic ignored "-Warc-performSelector-leaks"
//        [self.errorDelegate performSelector:selector withObject:self withObject:error];
//#pragma clang diagnostic pop
//    }
//}

#pragma mark - WKNavigationDelegate
- (void)webView:(WKWebView *)webView decidePolicyForNavigationAction:(WKNavigationAction *)navigationAction decisionHandler:(void (^)(WKNavigationActionPolicy))decisionHandler {
    if (webView != self.webView) {
        return;
    }
    
    NSURL *url = navigationAction.request.URL;
    if ([[url scheme] isEqualToString:@"https"]) {
        if ([url.host isEqualToString:[self origin].host] || [url.host isEqualToString:@"player.vimeo.com"]) {
            decisionHandler(WKNavigationActionPolicyAllow);
        } else {
            decisionHandler(WKNavigationActionPolicyCancel);
        }
        return;
    }
    
    if ([[url scheme] isEqualToString:@"player"]) {
        [self handlePlayer:url];
        decisionHandler(WKNavigationActionPolicyCancel);
        return;
    }
    
    decisionHandler(WKNavigationActionPolicyCancel);
}

- (void)handlePlayer:(NSURL *)url {
    NSString *host = [url host];
    NSLog(@"host: %@", host);
    
    if ([host isEqualToString:@"onPlay"]) {
        NSLog(@"video starting to play");
        return;
    }
    
    if ([host isEqualToString:@"pause"]) {
        NSLog(@"video paused");
        return;
    }
    
    if ([host isEqualToString:@"pause"]) {
        NSLog(@"video paused");
        return;
    }
    
    NSDictionary *comp = [self componentsForQuery:[url query]];
    NSLog(@"comp: %@", comp);
}

- (NSDictionary *)componentsForQuery:(NSString *)query {
    NSDictionary *comp = [NSMutableDictionary dictionary];
    NSArray *queryArray = [query componentsSeparatedByString:@"&"];
    
    for (NSString *queryStr in queryArray) {
        NSRange range = [queryStr rangeOfString:@"="];
        NSString *waUrl = [queryStr substringFromIndex:range.location + 1];
        [comp setValue:waUrl forKey:[queryStr substringToIndex:range.location]];
    }
    
    return comp;
}

@end
