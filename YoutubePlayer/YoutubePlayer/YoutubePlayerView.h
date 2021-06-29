//
//  YoutubePlayerView.h
//  YoutubePlayer
//
//  Created by Maxim Shnirman on 13/10/2020.
//  Copyright © 2020 Maxim Shnirman. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "VideoProtocol.h"

NS_ASSUME_NONNULL_BEGIN

@interface YoutubePlayerView : UIView <VideoPlayer>
- (void)loadVideoWithId:(NSString *)youtubeId;
- (void)setStateDelegate:(id<VideoPlayerStateProtocol>)stateDelegate;
- (void)setErrorDelegate:(id<VideoPlayerErrorProtocol>)errorDelegate;
@end

NS_ASSUME_NONNULL_END
