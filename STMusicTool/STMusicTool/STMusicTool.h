//
//  STMusicTool.h
//  STMusicTool
//
//  Created by TangJR on 3/24/16.
//  Copyright © 2016 tangjr. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <MediaPlayer/MediaPlayer.h>
@class STMusicTool;

typedef NS_ENUM(NSInteger, STMusicSortType) {
    STMusicSortTypeNone, ///< 不排序，从 itunes 中读出来是什么顺序就是什么顺序
    STMusicSortTypeTime, ///< 按添加时间排序
    STMusicSortTypeName, ///< 按歌曲名称排序
};

typedef NS_ENUM(NSInteger, STMusicPlayType) {
    STMusicPlayTypeRepeatAll, ///< 全部循环
    STMusicPlayTypeSingleCycle, ///< 单曲循环
    STMusicPlayTypeRandom ///< 随机播放
};

@protocol STMusicToolDelegate <NSObject>

// 播放错误，主要用于在播放过程中，出现歌曲被删除等情况
- (void)musicTool:(STMusicTool *)musicTool playWithError:(NSError *)error;

// 当前进度 百分制
- (void)musicTool:(STMusicTool *)musicTool currentProgress:(float)currentProgress;

// 准备播放的歌曲
- (void)musicTool:(STMusicTool *)musicTool prepareToPlayWithIndex:(NSInteger)index;

// 歌曲开始播放的回调，包含切歌开始和正常播放完成后开始
- (void)musicTool:(STMusicTool *)musicTool playWithIndex:(NSInteger)index;

// 歌曲正常播放完毕的回调，不包含切歌
- (void)musicTool:(STMusicTool *)musicTool finishWithIndex:(NSInteger)finishIndex;

// 歌曲列表变化（更改排序，更改搜索，同步歌曲）
- (void)musicTool:(STMusicTool *)musicTool musicListChanged:(NSArray *)musicList;

@end

@interface STMusicTool : NSObject

@property (strong, nonatomic, readonly) NSURL *currentPlayingURL; ///< 当前正在播放的 url
@property (copy, nonatomic, readonly) NSArray<MPMediaItem *> *currentPlayList; ///< 当前播放列表
@property (assign, nonatomic, readonly) BOOL isPlaying; ///< 是否正在播放

@property (assign, nonatomic) id<STMusicToolDelegate> delegate;

@property (assign, nonatomic) STMusicSortType sortType; ///< 设置排序方式
@property (assign, nonatomic) STMusicPlayType playType; ///< 设置播放方式


- (void)playNext;
- (void)playLast;
- (void)startWithIndex:(NSInteger)index;
- (void)playAtProgress:(float)progress;

- (void)play;
- (void)pause;

- (void)refreshMusicList;

@end