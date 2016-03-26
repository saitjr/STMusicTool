//
//  STMusicRandomTool.h
//  STMusicTool
//
//  Created by TangJR on 3/25/16.
//  Copyright © 2016 tangjr. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface STMusicRandomTool : NSObject

@property (assign, nonatomic, readonly) NSInteger nextShouldPlay; ///< 下一首
@property (assign, nonatomic, readonly) NSInteger lastShoulfPlay; ///< 上一首

- (instancetype)initWithLength:(NSInteger)length;

// 在随机播放过程中，选择要播放的歌曲
- (void)startRandomWithWillPlayIndex:(NSInteger)willPlayIndex;
// 在顺序播放过程中，切换到了随机播放
- (void)startRandomWithCurrentPlayIndex:(NSInteger)currentPlayIndex;

@end