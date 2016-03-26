//
//  STMusicTool.m
//  STMusicTool
//
//  Created by TangJR on 3/24/16.
//  Copyright © 2016 tangjr. All rights reserved.
//

#import "STMusicTool.h"
#import "STMusicRandomTool.h"
#import <AVFoundation/AVFoundation.h>

@interface STMusicTool () <AVAudioPlayerDelegate>

@property (strong, nonatomic) AVAudioPlayer *player; ///< 播放器
@property (copy, nonatomic) NSArray *musicList; ///< 播放列表
@property (assign, nonatomic) NSInteger currentPlayIndex; ///< 当前播放下标
@property (weak, nonatomic) MPMediaItem *currentPlayItem; ///< 当前播放的 item

// 是否应该自动播放，主要用于判断列表更新等情况，是否应该播放音乐
// 如果当前正在播放，那就应该自动播放
// 如果当前没有播放，或者 player 是空，那就不应该自动播放
@property (assign, nonatomic, readonly) BOOL shouldAutoPlay;

@property (assign, nonatomic) NSTimer *timer;
@property (assign, nonatomic) NSTimeInterval timeCount; ///< 当前这首歌已播放了秒数
@property (strong, nonatomic) NSDate *pauseDate;
@property (strong, nonatomic) NSDate *previousFireDate;

@property (strong, nonatomic) STMusicRandomTool *randomTool; ///< 随机

@end

@implementation STMusicTool

#pragma mark - Life Cycle

- (void)dealloc {
    [[MPMediaLibrary defaultMediaLibrary] endGeneratingLibraryChangeNotifications];
}

- (instancetype)init {
    self = [super init];
    if (self) {
        [self loadMusicList];
        [self setupNotification];
    }
    return self;
}

- (void)loadMusicList {
    MPMediaQuery *query = [[MPMediaQuery alloc] init];
    self.musicList = [query items];
}

- (void)setupNotification {
    [[MPMediaLibrary defaultMediaLibrary] beginGeneratingLibraryChangeNotifications];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(mediaLibraryDidChangeNotification:) name:MPMediaLibraryDidChangeNotification object:nil];
}

#pragma mark - Public Methods

- (void)playLast {
    [self preparePlayIndexWithIsNext:NO];
    [self playWithIndex:self.currentPlayIndex];
}

- (void)playNext {
    [self preparePlayIndexWithIsNext:YES];
    [self playWithIndex:self.currentPlayIndex];
}

- (void)playAtProgress:(float)progress {
    // 如果拖动到 1.0 会有点问题，还是改成 0.99 会好一点
    if (progress == 1.0) {
        progress = 0.99;
    }
    NSTimeInterval time = self.player.duration * progress;
    self.player.currentTime = time;
    self.timeCount = time;
}

- (void)startWithIndex:(NSInteger)index {
    if (self.playType == STMusicPlayTypeRandom) {
        [self.randomTool startRandomWithWillPlayIndex:index];
    }
    [self playWithIndex:index];
}

- (void)play {
    if (self.player != nil) {
        [self resume];
        return;
    }
    if ([self isMusicListEmpty]) {
        return;
    }
    NSURL *url = ((MPMediaItem *)self.musicList[self.currentPlayIndex]).assetURL;
    [self playWithURL:url];
}

- (void)pause {
    [self.player pause];
    [self pauseTimer];
}

- (void)resume {
    [self.player play];
    [self resumeTimer];
}

- (void)refreshMusicList {
    // 更新逻辑应该是
    // 先保存当前正在播放的歌曲，然后移除全部的，然后重新添加全部
    // 然后找到当前正在播放的歌曲的下标，更新 currentPlayIndex
    [self loadMusicList];
    
    // 如果更新之后，歌曲列表没有了，则清除所有数据
    if ([self isMusicListEmpty]) {
        [self clearAllData];
        return;
    }
    NSInteger currentIndexInNewList = [self.musicList indexOfObject:self.currentPlayItem];
    
    // 如果当前在播放的歌曲被删除了，则直接播放下一首
    if (currentIndexInNewList == NSNotFound) {
        // 如果当前正在播放，再切歌，如果当前没有播放，那就不用播了
        if (self.shouldAutoPlay) {
            [self playNext];
        } else {
            [self clearAllData];
            [self preparePlayIndexWithIsNext:YES];
        }
    } else {
        self.currentPlayIndex = currentIndexInNewList;
    }
    
    // 如果是随机模式，则需要重置 randomTool，因为鬼知道总长度变没有
    if (self.playType == STMusicPlayTypeRandom) {
        self.randomTool = [[STMusicRandomTool alloc] initWithLength:self.musicList.count];
        [self.randomTool startRandomWithCurrentPlayIndex:self.currentPlayIndex];
    }
    
    if (self.delegate && self.delegate && [self.delegate respondsToSelector:@selector(musicTool:prepareToPlayWithIndex:)]) {
        [self.delegate musicTool:self prepareToPlayWithIndex:self.currentPlayIndex];
    }
}

#pragma mark - Private Methods

- (void)preparePlayIndexWithIsNext:(BOOL)isNext {
    if (self.playType != STMusicPlayTypeRandom || self.musicList.count <= 3) {
        self.currentPlayIndex = [self indexInRange:isNext ? self.currentPlayIndex + 1 : self.currentPlayIndex - 1];
        return;
    }
    NSInteger newIndex = isNext ? self.randomTool.nextShouldPlay : self.randomTool.lastShoulfPlay;
    self.currentPlayIndex = newIndex;
}

- (void)playWithIndex:(NSInteger)index {
    NSURL *url = ((MPMediaItem *)self.musicList[index]).assetURL;
    [self playWithURL:url];
}

- (NSInteger)indexInRange:(NSInteger)index {
    if (index < 0) {
        return self.musicList.count - 1;
    }
    if (index > self.musicList.count - 1) {
        return 0;
    }
    return index;
}

- (void)playWithURL:(NSURL *)url {
    NSError *error = nil;
    self.player = [[AVAudioPlayer alloc] initWithContentsOfURL:url error:&error];
    if (error && self.delegate && [self.delegate respondsToSelector:@selector(musicTool:playWithError:)]) {
        [self.delegate musicTool:self playWithError:error];
        return;
    }
    self.player.numberOfLoops = 0;
    self.player.volume = 1;
    self.player.delegate = self;
    [self.player prepareToPlay];
    [self.player play];
    [self startTimer];
    [[AVAudioSession sharedInstance] setCategory:AVAudioSessionCategoryPlayback error:nil];
    self.currentPlayItem = self.musicList[self.currentPlayIndex];
    
    if (self.delegate && [self.delegate respondsToSelector:@selector(musicTool:prepareToPlayWithIndex:)]) {
        [self.delegate musicTool:self prepareToPlayWithIndex:self.currentPlayIndex];
    }
    
    if (self.delegate && [self.delegate respondsToSelector:@selector(musicTool:playWithIndex:)]) {
        [self.delegate musicTool:self playWithIndex:self.currentPlayIndex];
    }
}

- (void)sortMusicList {
    if (self.musicList == nil || self.musicList.count == 0) {
        return;
    }
    // 如果是默认排序，就直接 return
    // 默认：默认排序即从 itunes 读出来的顺序，如果用户一旦改过排序方式，就再也回不到默认排序了，所以，可以直接 return
    if (self.sortType == STMusicSortTypeNone) {
        return;
    }
    if (self.sortType == STMusicSortTypeTime) {
        @autoreleasepool {
            NSArray *tempArray = [self.musicList sortedArrayUsingComparator:^NSComparisonResult(MPMediaItem *obj1, MPMediaItem *obj2) {
                return [obj1.releaseDate compare:obj2.releaseDate];
            }];
            self.musicList = tempArray;
        }
    }
    if (self.sortType == STMusicSortTypeName) {
        @autoreleasepool {
            NSArray *tempArray = [self.musicList sortedArrayUsingComparator:^NSComparisonResult(MPMediaItem *obj1, MPMediaItem *obj2) {
                return [obj1.title compare:obj2.title];
            }];
            self.musicList = tempArray;
        }
    }
}

// 在没有音乐文件时，清空所有数据
- (void)clearAllData {
    self.currentPlayIndex = 0;
    self.player = nil;
    [self stopTimer];
}

- (BOOL)isMusicListEmpty {
    return self.musicList == nil || self.musicList.count == 0;
}

#pragma mark - Timer

- (void)startTimer {
    [self stopTimer];
    self.timer = [NSTimer scheduledTimerWithTimeInterval:1 target:self selector:@selector(timerHandler) userInfo:nil repeats:YES];
}

- (void)pauseTimer {
    self.pauseDate = [NSDate dateWithTimeIntervalSinceNow:0];
    self.previousFireDate = [self.timer fireDate];
    [self.timer setFireDate:[NSDate distantFuture]];
}

- (void)resumeTimer {
    float pauseTime = -1 * [self.pauseDate timeIntervalSinceNow];
    [self.timer setFireDate:[NSDate dateWithTimeInterval:pauseTime sinceDate:self.previousFireDate]];
    self.pauseDate = nil;
    self.previousFireDate = nil;
}

- (void)stopTimer {
    [self.timer invalidate];
    self.timer = nil;
    self.timeCount = 0;
}

- (void)timerHandler {
    self.timeCount++;
    if (self.delegate && [self.delegate respondsToSelector:@selector(musicTool:currentProgress:)]) {
        NSTimeInterval totalCount = self.currentPlayItem.playbackDuration;
        [self.delegate musicTool:self currentProgress:self.timeCount / totalCount];
    }
}

#pragma mark - AVAudioPlayerDelegate

- (void)audioPlayerDidFinishPlaying:(AVAudioPlayer *)player successfully:(BOOL)flag {
    // 这两个 if 不能换位置，因为下面的 if 会播放下一曲，这样 currentPlayIndex 就 ++ 了，返回去的下标就会有问题
    if (self.delegate && [self.delegate respondsToSelector:@selector(musicTool:finishWithIndex:)]) {
        [self.delegate musicTool:self finishWithIndex:self.currentPlayIndex];
    }
    if (self.playType == STMusicPlayTypeSingleCycle) {
        [self play];
        return;
    }
    if (self.playType != STMusicPlayTypeSingleCycle) {
        [self playNext];
        return;
    }
}

#pragma mark - Notification

- (void)mediaLibraryDidChangeNotification:(NSNotification *)notification {
    [self refreshMusicList];
}

#pragma mark - Getter / Setter

- (BOOL)isPlaying {
    return self.player.isPlaying;
}

- (NSURL *)currentPlayingURL {
    return self.player.url;
}

- (NSArray<MPMediaItem *> *)currentPlayList {
    return self.musicList;
}

- (BOOL)shouldAutoPlay {
    if (self.player && self.player.isPlaying) {
        return YES;
    }
    return NO;
}

- (void)setMusicList:(NSArray *)musicList {
    _musicList = musicList;
    if (self.delegate && [self.delegate respondsToSelector:@selector(musicTool:musicListChanged:)]) {
        [self.delegate musicTool:self musicListChanged:self.musicList];
    }
}

- (void)setSortType:(STMusicSortType)sortType {
    _sortType = sortType;
    [self sortMusicList];
}

- (void)setPlayType:(STMusicPlayType)playType {
    _playType = playType;
    if (playType == STMusicPlayTypeRandom) {
        [self.randomTool startRandomWithCurrentPlayIndex:self.currentPlayIndex];
        return;
    }
}

- (STMusicRandomTool *)randomTool {
    if (!_randomTool) {
        _randomTool = [[STMusicRandomTool alloc] initWithLength:self.musicList.count];
    }
    return _randomTool;
}

@end