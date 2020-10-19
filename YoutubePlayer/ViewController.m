//
//  ViewController.m
//  YoutubePlayer
//
//  Created by Maxim Shnirman on 13/10/2020.
//  Copyright © 2020 Maxim Shnirman. All rights reserved.
//

#import "ViewController.h"
#import "PlayerView.h"

static NSString *const youtubeVideoId = @"-CX7qKaJDvQ";

@interface ViewController () <PlayerStateProtocol, PlayerErrorProtocol>
@property (weak, nonatomic) IBOutlet UIView *conainer;
@property (strong, nonatomic) PlayerView *playerView;
@end

@implementation ViewController

#pragma mark - life cycle
- (void)viewDidLoad {
    [super viewDidLoad];

    _playerView = [[PlayerView alloc] init];
    _playerView.center = self.conainer.center;
    _playerView.frame = CGRectMake(0, 0, self.conainer.frame.size.width, self.conainer.frame.size.height);
    [_playerView setStateDelegate:self];
    [_playerView setErrorDelegate:self];
    [_playerView loadYoutubeIframeWithId:youtubeVideoId];
    
    [self.conainer addSubview:_playerView];
}

#pragma mark - PlayerStateProtocol
- (void)playerEnteredFullscreen:(PlayerView *)player {
    NSLog(@"playerEnteredFullscreen");
}

- (void)playerExitedFullscreen:(PlayerView *)player {
    NSLog(@"playerExitedFullscreen");
}

- (void)playerReady:(PlayerView *)player {
    NSLog(@"playerReady");
}

- (void)playerUnstarted:(PlayerView *)player {
    NSLog(@"playerUnstarted");
}

- (void)playerEnded:(PlayerView *)player {
    NSLog(@"playerEnded");
}

- (void)playerPlaying:(PlayerView *)player {
    NSLog(@"playerPlaying");
}

- (void)playerPaused:(PlayerView *)player {
    NSLog(@"playerPaused");
}

- (void)playerBuffering:(PlayerView *)player {
    NSLog(@"playerBuffering");
}

- (void)playerCued:(PlayerView *)player {
    NSLog(@"playerCued");
}

#pragma mark - PlayerErrorProtocol
- (void)player:(PlayerView *)player errorInvalidParam:(NSError *)error {
    NSLog(@"errorInvalidParam. error: %@", error);
}

- (void)player:(PlayerView *)player errorHTML5:(NSError *)error {
    NSLog(@"errorHTML5. error: %@", error);
}

- (void)player:(PlayerView *)player errorNotFound:(NSError *)error {
    NSLog(@"errorNotFound. error: %@", error);
}

- (void)player:(PlayerView *)player errorNotEmbeddable:(NSError *)error {
    NSLog(@"errorNotEmbeddable. error: %@", error);
}

- (void)player:(PlayerView *)player errorUnknown:(NSError *)error {
    NSLog(@"errorUnknown. error: %@", error);
}

@end
