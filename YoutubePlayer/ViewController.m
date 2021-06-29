//
//  ViewController.m
//  YoutubePlayer
//
//  Created by Maxim Shnirman on 13/10/2020.
//  Copyright © 2020 Maxim Shnirman. All rights reserved.
//

#import "ViewController.h"
#import "YoutubePlayerView.h"
#import "VimeoPlayerView.h"
#import "VideoProtocol.h"

typedef enum PlayerType: NSUInteger {
    kYouTube,
    kVimeo
} PlayerType;

static PlayerType const playerType = kYouTube;
static NSString *const youtubeVideoId = @"e85E1zQSg4I";
static NSString *const vimeoVideoId = @"294446154";

@interface ViewController () <VideoPlayerStateProtocol, VideoPlayerErrorProtocol>
@property (weak, nonatomic) IBOutlet UIView *container;
@property (strong, nonatomic) YoutubePlayerView *youtubeView;
@property (strong, nonatomic) VimeoPlayerView *vimeoView;
@end

@implementation ViewController

#pragma mark - life cycle
- (void)viewDidLoad {
    [super viewDidLoad];

    switch (playerType) {
        case kYouTube:
            _youtubeView = [[YoutubePlayerView alloc] init];
            _youtubeView.center = self.container.center;
            _youtubeView.frame = CGRectMake(0, 0, self.container.frame.size.width, self.container.frame.size.height);
            
            [_youtubeView setStateDelegate:self];
            [_youtubeView setErrorDelegate:self];
            [_youtubeView loadVideoWithId:youtubeVideoId];
            
            [self.container addSubview:_youtubeView];
            break;
            
        case kVimeo:
            _vimeoView = [[VimeoPlayerView alloc] init];
            _vimeoView.center = self.container.center;
            _vimeoView.frame = CGRectMake(0, 0, self.container.frame.size.width, self.container.frame.size.height);
            
//            [_vimeoView setStateDelegate:self];
//            [_vimeoView setErrorDelegate:self];
            [_vimeoView loadVideoWithId:vimeoVideoId];
            
            [self.container addSubview:_vimeoView];
            break;
       
        default:
            break;
    }
}

#pragma mark - PlayerStateProtocol
- (void)playerEnteredFullscreen:(YoutubePlayerView *)player {
    NSLog(@"playerEnteredFullscreen");
}

- (void)playerExitedFullscreen:(YoutubePlayerView *)player {
    NSLog(@"playerExitedFullscreen");
}

- (void)playerReady:(YoutubePlayerView *)player {
    NSLog(@"playerReady");
}

- (void)playerNotStarted:(YoutubePlayerView *)player {
    NSLog(@"playerUnstarted");
}

- (void)playerEnded:(YoutubePlayerView *)player {
    NSLog(@"playerEnded");
}

- (void)playerPlaying:(YoutubePlayerView *)player {
    NSLog(@"playerPlaying");
}

- (void)playerPaused:(YoutubePlayerView *)player {
    NSLog(@"playerPaused");
}

- (void)playerBuffering:(YoutubePlayerView *)player {
    NSLog(@"playerBuffering");
}

- (void)playerCued:(YoutubePlayerView *)player {
    NSLog(@"playerCued");
}

#pragma mark - PlayerErrorProtocol
- (void)player:(YoutubePlayerView *)player errorInvalidParam:(NSError *)error {
    NSLog(@"errorInvalidParam. error: %@", error);
}

- (void)player:(YoutubePlayerView *)player errorHTML5:(NSError *)error {
    NSLog(@"errorHTML5. error: %@", error);
}

- (void)player:(YoutubePlayerView *)player errorNotFound:(NSError *)error {
    NSLog(@"errorNotFound. error: %@", error);
}

- (void)player:(YoutubePlayerView *)player errorNotEmbeddable:(NSError *)error {
    NSLog(@"errorNotEmbeddable. error: %@", error);
}

- (void)player:(YoutubePlayerView *)player errorUnknown:(NSError *)error {
    NSLog(@"errorUnknown. error: %@", error);
}

@end
