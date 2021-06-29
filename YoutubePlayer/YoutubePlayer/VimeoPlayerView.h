//
//  VimeoPlayerView.h
//  YoutubePlayer
//
//  Created by Maxim Shnirman on 14/06/2021.
//  Copyright © 2021 Maxim Shnirman. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "VideoProtocol.h"

NS_ASSUME_NONNULL_BEGIN

@interface VimeoPlayerView : UIView <VideoPlayer>
- (void)loadVideoWithId:(NSString *)videoId;
@end

NS_ASSUME_NONNULL_END
