//
//  VideoProtocol.h
//  YoutubePlayer
//
//  Created by Maxim Shnirman on 15/06/2021.
//  Copyright © 2021 Maxim Shnirman. All rights reserved.
//

#ifndef VideoProtocol_h
#define VideoProtocol_h

@protocol VideoPlayer <NSObject>
- (void)loadVideoWithId:(NSString *)videoId;
@end

@protocol VideoPlayerStateProtocol <NSObject>
@optional
- (void)playerEnteredFullscreen:(id<VideoPlayer>)player;
- (void)playerExitedFullscreen:(id<VideoPlayer>)player;
- (void)playerReady:(id<VideoPlayer>)player;
- (void)playerNotStarted:(id<VideoPlayer>)player;
- (void)playerEnded:(id<VideoPlayer>)player;
- (void)playerPlaying:(id<VideoPlayer>)player;
- (void)playerPaused:(id<VideoPlayer>)player;
- (void)playerBuffering:(id<VideoPlayer>)player;
- (void)playerCued:(id<VideoPlayer>)player;
@end

@protocol VideoPlayerErrorProtocol <NSObject>
@optional
- (void)player:(id<VideoPlayer>)player errorInvalidParam:(NSError *)error;
- (void)player:(id<VideoPlayer>)player errorHTML5:(NSError *)error;
- (void)player:(id<VideoPlayer>)player errorNotFound:(NSError *)error;
- (void)player:(id<VideoPlayer>)player errorNotEmbeddable:(NSError *)error;
- (void)player:(id<VideoPlayer>)player errorUnknown:(NSError *)error;
@end

#endif /* VideoProtocol_h */
