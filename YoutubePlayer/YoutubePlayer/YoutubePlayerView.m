//
//  YoutubePlayerView.m
//  YoutubePlayer
//
//  Created by Maxim Shnirman on 13/10/2020.
//  Copyright © 2020 Maxim Shnirman. All rights reserved.
//

#import "YoutubePlayerView.h"
#import <WebKit/WebKit.h>

static BOOL kAutoPlay = YES;

static NSString *const kPlayerScheme = @"player";
static NSString *const kScheme = @"https";
static NSString *const kErrorDomain = @"YouTubePlayer";
static NSString *const kData = @"data";
static NSString *const kError = @"error";
static NSString *const kWidth = @"width";
static NSString *const kHeight = @"height";
static NSString *const kTime = @"time";

static NSString *const kPlayerStateNotStartedCode = @"-1";
static NSString *const kPlayerStateEndedCode = @"0";
static NSString *const kPlayerStatePlayingCode = @"1";
static NSString *const kPlayerStatePausedCode = @"2";
static NSString *const kPlayerStateBufferingCode = @"3";
static NSString *const kPlayerStateCuedCode = @"5";
static NSString *const kPlayerStateUnknownCode = @"unknown";

static NSString *const kPlayerErrorInvalidParamErrorCode = @"2";
static NSString *const kPlayerErrorHTML5ErrorCode = @"5";
static NSString *const kPlayerErrorVideoNotFoundErrorCode = @"100";
static NSString *const kPlayerErrorNotEmbeddableErrorCode = @"101";
static NSString *const kPlayerErrorCannotFindVideoErrorCode = @"105";
static NSString *const kPlayerErrorSameAsNotEmbeddableErrorCode = @"150";

static NSString *const kPlayerEmbedUrlRegexPattern = @"^http(s)://(www.)youtube.com/embed/(.*)$";
static NSString *const kPlayerAdUrlRegexPattern = @"^http(s)://pubads.g.doubleclick.net/pagead/conversion/";
static NSString *const kPlayerOAuthRegexPattern = @"^http(s)://accounts.google.com/o/oauth2/(.*)$";
static NSString *const kPlayerStaticProxyRegexPattern = @"^https://content.googleapis.com/static/proxy.html(.*)$";
static NSString *const kPlayerSyndicationRegexPattern = @"^https://tpc.googlesyndication.com/sodar/(.*).html$";

static NSString *const kPlayerOnReady = @"onPlayerReady";
static NSString *const kPlayerOnStateChange = @"onPlayerStateChange";
static NSString *const kPlayerOnError = @"onPlayerError";
static NSString *const kPlayerResize = @"onPlayerResize";
static NSString *const kPlayTime = @"onPlayTime";

@interface YoutubePlayerView () <WKNavigationDelegate>
@property (nonatomic, strong) WKWebView *webView;
@property (nonatomic, strong) NSURL *origin;
@property (nonatomic, strong) UIActivityIndicatorView *spinner;
@property (nonatomic, weak) id<VideoPlayerStateProtocol> stateDelegate;
@property (nonatomic, weak) id<VideoPlayerErrorProtocol> errorDelegate;
@end

@implementation YoutubePlayerView

typedef NS_ENUM(NSInteger, YTPlayerState) {
    PlayerStateNotStarted = -1,
    PlayerStateEnded,
    PlayerStatePlaying,
    PlayerStatePaused,
    PlayerStateBuffering,
    PlayerStateCued,
    PlayerStateUnknown
};

typedef NS_ENUM(NSInteger, YTPlayerError) {
    PlayerErrorUnknown = -1,
    PlayerErrorInvalidParam = 2,
    PlayerErrorHTML5 = 5,
    PlayerErrorVideoNotFound = 100,
    PlayerErrorNotEmbeddable = 101,
    PlayerErrorCannotFindVideo = 105,
    PlayerErrorSameAsNotEmbeddable = 150
};

#pragma mark - life cycle
- (instancetype)init {
    if (self = [super init]) {
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(onEnterFullScreen) name:UIWindowDidBecomeVisibleNotification object:nil];
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(onCloseFullScreen) name:UIWindowDidBecomeHiddenNotification object:nil];
        self.autoresizingMask = (UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight);
    }
    return self;
}

- (void)dealloc {
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

- (void)layoutSubviews {
    self.webView.frame = CGRectMake(0, 0, self.frame.size.width, self.frame.size.height);
    [self.webView layoutSubviews];
    [super layoutSubviews];
}

- (void)willMoveToSuperview:(UIView *)newSuperview {
    [super willMoveToSuperview:newSuperview];
    [self addSpinner];
}

#pragma mark - public
- (void)setStateDelegate:(id<VideoPlayerStateProtocol>)delegate {
    _stateDelegate = delegate;
}

- (void)setErrorDelegate:(id<VideoPlayerErrorProtocol>)delegate {
    _errorDelegate = delegate;
}

- (void)loadVideoWithId:(NSString *)videoId {
    NSString *player = [self player];
    NSString *playerParams = [self playerParamWithVideoId:videoId];
    
    if (player && playerParams) {
        NSString *embedHTML = [NSString stringWithFormat:player, playerParams, @(kAutoPlay)];
        self.webView.userInteractionEnabled = YES;
        [self.webView loadHTMLString:embedHTML baseURL:self.origin];
    } else {
        NSLog(@"there was a problem creating the webView");
    }
}

#pragma mark - notifications
- (void)onEnterFullScreen {
    [self invocator:@selector(playerEnteredFullscreen:)];
}

- (void)onCloseFullScreen {
    [self invocator:@selector(playerExitedFullscreen:)];
}

#pragma mark - private getters
- (NSURL *)origin {
    if (!_origin) {
        NSString *bundleId = [[NSBundle mainBundle] bundleIdentifier];
        NSString *stringURL = [[NSString stringWithFormat:@"https://%@", bundleId] lowercaseString];
        _origin = [NSURL URLWithString:stringURL];
    }
    return _origin;
}

- (NSString *_Nullable)player {
    NSString *html = [[NSBundle mainBundle] pathForResource:@"youtube" ofType:@"html"];
    NSError *jsonRenderingError = nil;
    NSString *player = [NSString stringWithContentsOfFile:html encoding:NSUTF8StringEncoding error:&jsonRenderingError];
    
    if (jsonRenderingError) {
        NSLog(@"error creating player from html: %@", jsonRenderingError);
        return nil;
    }
    
    return player;
}

- (NSString *_Nullable)playerParamWithVideoId:(NSString *)youtubeId {
    NSError *jsonRenderingError = nil;
    NSDictionary *playerParams = [self playerParams:youtubeId];
    NSData *jsonData = [NSJSONSerialization dataWithJSONObject:playerParams options:NSJSONWritingPrettyPrinted error:&jsonRenderingError];
    
    if (jsonRenderingError) {
        NSLog(@"error creating player params: %@", jsonRenderingError);
        return nil;
    }
    
    return [[NSString alloc] initWithData:jsonData encoding:NSUTF8StringEncoding];
}

- (NSDictionary *)playerParams:(NSString *)youtubeId {
    return @{
        @"videoId": youtubeId,
        @"playerVars": @{
                @"enablejsapi": @(false),
                @"autoplay": @(false),
                @"fs": @(true),
                @"rel": @(false),
                @"controls": @(true),
                @"playsinline": @(true),
                @"modestbranding": @(true)
        },
        @"events": @{
                @"onReady" : kPlayerOnReady,
                @"onStateChange" : kPlayerOnStateChange,
                @"onError" : kPlayerOnError
        },
        @"origin": self.origin.absoluteString
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
- (void)addSpinner {
    self.spinner = [[UIActivityIndicatorView alloc] initWithActivityIndicatorStyle:UIActivityIndicatorViewStyleLarge];
    [self.spinner setCenter:self.center];
    [self.spinner startAnimating];
    [self addSubview:self.spinner];
}

- (void)removeSpinner {
    [self.spinner stopAnimating];
    [self.spinner removeFromSuperview];
}

#pragma mark - selector invocator
- (void)invocator:(SEL)selector {
    if (self.stateDelegate && [self.stateDelegate respondsToSelector:selector]) {
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Warc-performSelector-leaks"
        [self.stateDelegate performSelector:selector withObject:self];
#pragma clang diagnostic pop
    }
}

- (void)errorInvocator:(SEL)selector error:(NSError *)error {
    if (self.errorDelegate && [self.errorDelegate respondsToSelector:selector]) {
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Warc-performSelector-leaks"
        [self.errorDelegate performSelector:selector withObject:self withObject:error];
#pragma clang diagnostic pop
    }
}

#pragma mark - state handler
- (void)handleState:(YTPlayerState)state {
    SEL selector = nil;
    
    switch (state) {
        case PlayerStateNotStarted:
            selector = @selector(playerNotStarted:);
            break;
        case PlayerStateEnded:
            selector = @selector(playerEnded:);
            break;
        case PlayerStatePlaying:
            selector = @selector(playerPlaying:);
            break;
        case PlayerStatePaused:
            selector = @selector(playerPaused:);
            break;
        case PlayerStateBuffering:
            selector = @selector(playerBuffering:);
            break;
        case PlayerStateCued:
            selector = @selector(playerCued:);
            break;
        case PlayerStateUnknown:
            selector = @selector(player:errorUnknown:);
            NSError *error = [NSError errorWithDomain:kErrorDomain code:PlayerStateUnknown userInfo:@{kData: @"unknown error in state"}];
            [self errorInvocator:selector error:error];
            return;
    }
    
    if (selector) {
        [self invocator:selector];
    }
}

- (YTPlayerState)playerStateForString:(NSString *)stateString {
    YTPlayerState state = PlayerStateUnknown;
    
    if ([stateString isEqualToString:kPlayerStateNotStartedCode]) {
        state = PlayerStateNotStarted;
    } else if ([stateString isEqualToString:kPlayerStateEndedCode]) {
        state = PlayerStateEnded;
    } else if ([stateString isEqualToString:kPlayerStatePlayingCode]) {
        state = PlayerStatePlaying;
    } else if ([stateString isEqualToString:kPlayerStatePausedCode]) {
        state = PlayerStatePaused;
    } else if ([stateString isEqualToString:kPlayerStateBufferingCode]) {
        state = PlayerStateBuffering;
    } else if ([stateString isEqualToString:kPlayerStateCuedCode]) {
        state = PlayerStateCued;
    }
    
    return state;
}

#pragma mark - error handler
- (void)handleError:(YTPlayerError)errorNum {
    SEL selector = nil;
    NSError *error = nil;
    
    switch (errorNum) {
        case PlayerErrorInvalidParam:
            selector = @selector(player:errorInvalidParam:);
            error = [NSError errorWithDomain:kErrorDomain code:PlayerErrorInvalidParam userInfo:@{kData: @"invalid param"}];
            break;
        case PlayerErrorHTML5:
            selector = @selector(player:errorHTML5:);
            error = [NSError errorWithDomain:kErrorDomain code:PlayerErrorHTML5 userInfo:@{kData: @"HTML5 error"}];
            break;
        case PlayerErrorVideoNotFound:
            selector = @selector(player:errorNotFound:);
            error = [NSError errorWithDomain:kErrorDomain code:PlayerErrorVideoNotFound userInfo:@{kData: @"video not found"}];
            break;
        case PlayerErrorNotEmbeddable:
            selector = @selector(player:errorNotEmbeddable:);
            error = [NSError errorWithDomain:kErrorDomain code:PlayerErrorNotEmbeddable userInfo:@{kData: @"video not embeddable"}];
            break;
        case PlayerErrorCannotFindVideo:
            selector = @selector(player:errorNotFound:);
            error = [NSError errorWithDomain:kErrorDomain code:PlayerErrorCannotFindVideo userInfo:@{kData: @"video not found"}];
            break;
        case PlayerErrorSameAsNotEmbeddable:
            selector = @selector(player:errorNotEmbeddable:);
            error = [NSError errorWithDomain:kErrorDomain code:PlayerErrorSameAsNotEmbeddable userInfo:@{kData: @"video not embeddable"}];
            break;
        default:
            selector = @selector(player:errorUnknown:);
            error = [NSError errorWithDomain:kErrorDomain code:PlayerErrorUnknown userInfo:@{kData: @"unknown error"}];
            break;
    }
    
    if (selector && error) {
        [self errorInvocator:selector error:error];
    }
}

- (YTPlayerError)playerErrorForString:(NSString *)data {
    YTPlayerError error = PlayerErrorUnknown;
    
    if ([data isEqual:kPlayerErrorInvalidParamErrorCode]) {
        error = PlayerErrorInvalidParam;
    } else if ([data isEqual:kPlayerErrorHTML5ErrorCode]) {
        error = PlayerErrorHTML5;
    } else if ([data isEqual:kPlayerErrorNotEmbeddableErrorCode] ||
               [data isEqual:kPlayerErrorSameAsNotEmbeddableErrorCode]) {
        error = PlayerErrorNotEmbeddable;
    } else if ([data isEqual:kPlayerErrorVideoNotFoundErrorCode] ||
               [data isEqual:kPlayerErrorCannotFindVideoErrorCode]) {
        error = PlayerErrorVideoNotFound;
    }
    
    return error;
}

#pragma mark - WKNavigationDelegate
- (void)webView:(WKWebView *)webView decidePolicyForNavigationAction:(WKNavigationAction *)navigationAction decisionHandler:(void (^)(WKNavigationActionPolicy))decisionHandler {
    if (webView != self.webView) {
        return;
    }
    
    NSURL *url = navigationAction.request.URL;
    if ([[url scheme] isEqualToString:kScheme]) {
        
        if ([self handleHTTPNavigationToUrl:url]) {
            decisionHandler(WKNavigationActionPolicyAllow);
        } else {
            decisionHandler(WKNavigationActionPolicyCancel);
        }
        return;
    }
    
    if ([[url scheme] isEqualToString:kPlayerScheme]) {
        [self handlePlayer:url];
        decisionHandler(WKNavigationActionPolicyCancel);
        return;
    }
    
    decisionHandler(WKNavigationActionPolicyCancel);
}

- (void)handlePlayer:(NSURL *)url {
    NSString *host = [url host];
    
    if ([host isEqualToString:kPlayerOnReady]) {
        [self removeSpinner];
        [self invocator:@selector(playerReady:)];
    } else if ([host isEqualToString:kPlayerOnStateChange]) {
        NSDictionary *comp = [self componentsForQuery:[url query]];
        
        if (comp[kData]) {
            YTPlayerState state = [self playerStateForString:comp[kData]];
            [self handleState:state];
        }
    } else if ([host isEqualToString:kPlayerOnError]) {
        NSDictionary *comp = [self componentsForQuery:[url query]];
        
        if (comp[kError]) {
            YTPlayerError error = [self playerErrorForString:comp[kError]];
            [self handleError:error];
        }
    } else if ([host isEqualToString:kPlayerResize]) {
        NSDictionary *comp = [self componentsForQuery:[url query]];
        
        if (comp[kWidth] && comp[kHeight]) {
            NSLog(@"resized to: [%@, %@]", comp[kWidth], comp[kHeight]);
        }
    } else if ([host isEqualToString:kPlayTime]) {
        NSDictionary *comp = [self componentsForQuery:[url query]];
        
        if (comp[kTime]) {
            NSLog(@"play time: [%.2f]", [comp[kTime] floatValue]);
        }
    }
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

- (BOOL)handleHTTPNavigationToUrl:(NSURL *)url {
    // When loading the webView for the first time, webView tries loading the originURL
    // since it is set as the webView.baseURL.
    // In that case we want to let it load itself in the webView instead of trying
    // to load it in a browser.
    if ([url.host isEqualToString:[self origin].host]) {
        return YES;
    }
    // Usually this means the user has clicked on the YouTube logo or an error message in the
    // player. Most URLs should open in the browser. The only http(s) URL that should open in this
    // webview is the URL for the embed, which is of the format:
    //     http(s)://www.youtube.com/embed/[VIDEO ID]?[PARAMETERS]
    NSString *absoluteString = url.absoluteString;
    
    NSTextCheckingResult *ytMatch = [self checkRegularExpression:absoluteString pattern:kPlayerEmbedUrlRegexPattern];
    NSTextCheckingResult *adMatch = [self checkRegularExpression:absoluteString pattern:kPlayerAdUrlRegexPattern];
    NSTextCheckingResult *syndicationMatch = [self checkRegularExpression:absoluteString pattern:kPlayerSyndicationRegexPattern];
    NSTextCheckingResult *oauthMatch = [self checkRegularExpression:absoluteString pattern:kPlayerOAuthRegexPattern];
    NSTextCheckingResult *staticProxyMatch = [self checkRegularExpression:absoluteString pattern:kPlayerStaticProxyRegexPattern];
    
    if (ytMatch || adMatch || oauthMatch || staticProxyMatch || syndicationMatch) {
        return YES;
    } else {
        [[UIApplication sharedApplication] openURL:url options:@{UIApplicationOpenURLOptionUniversalLinksOnly:@NO} completionHandler:nil];
        return NO;
    }
}

- (NSTextCheckingResult *_Nullable)checkRegularExpression:(NSString *)input pattern:(NSString *)pattern {
    NSError *error = nil;
    NSUInteger length = [input length];
    NSRegularExpression *ex = [NSRegularExpression regularExpressionWithPattern:pattern
                                                                        options:NSRegularExpressionCaseInsensitive
                                                                          error:&error];
    if (error) {
        NSLog(@"error while evaluating input: %@ for regex: %@", input, error);
        return nil;
    }
    
    NSTextCheckingResult *result = [ex firstMatchInString:input options:0 range:NSMakeRange(0, length)];
    return result;
}

@end
