//
//  PlayerView.h
//  YoutubePlayer
//
//  Created by Maxim Shnirman on 13/10/2020.
//  Copyright © 2020 Maxim Shnirman. All rights reserved.
//

#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN
@class PlayerView;

@protocol PlayerStateProtocol <NSObject>
@optional
- (void)playerEnteredFullscreen:(PlayerView *)player;
- (void)playerExitedFullscreen:(PlayerView *)player;
- (void)playerReady:(PlayerView *)player;
- (void)playerUnstarted:(PlayerView *)player;
- (void)playerEnded:(PlayerView *)player;
- (void)playerPlaying:(PlayerView *)player;
- (void)playerPaused:(PlayerView *)player;
- (void)playerBuffering:(PlayerView *)player;
- (void)playerCued:(PlayerView *)player;
@end

@protocol PlayerErrorProtocol <NSObject>
@optional
- (void)player:(PlayerView *)player errorInvalidParam:(NSError *)error;
- (void)player:(PlayerView *)player errorHTML5:(NSError *)error;
- (void)player:(PlayerView *)player errorNotFound:(NSError *)error;
- (void)player:(PlayerView *)player errorNotEmbeddable:(NSError *)error;
- (void)player:(PlayerView *)player errorUnknown:(NSError *)error;
@end

@interface PlayerView : UIView
- (void)loadYoutubeIframeWithId:(NSString *)youtubeId;
- (void)setStateDelegate:(id<PlayerStateProtocol>)stateDelegate;
- (void)setErrorDelegate:(id<PlayerErrorProtocol>)errorDelegate;
@end

NS_ASSUME_NONNULL_END
