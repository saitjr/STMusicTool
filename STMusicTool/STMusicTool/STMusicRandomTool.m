//
//  STMusicRandomTool.m
//  STMusicTool
//
//  Created by TangJR on 3/25/16.
//  Copyright © 2016 tangjr. All rights reserved.
//

/*
 主要逻辑有一下几点：（假设一共8首，随机数组下标为 0-7）
 1. 当前播放 0，一轮播放完以后，重新打乱数组（打乱后，假设第0位是歌曲3，上一次播放的也是歌曲3，那么将第0位和最后一位对调）
 2. 用户点击播放歌曲 4，或者是从顺序播放切换过来的，那么乱序数组，然后将歌曲4，放到1，然后将切换过来的那一首放到0
 */

#import "STMusicRandomTool.h"

@interface STMusicRandomTool ()

@property (strong, nonatomic) NSMutableArray *randomList; ///< 随机数组
@property (assign, nonatomic) NSInteger originLength; ///< 总长度
@property (assign, nonatomic) NSInteger currentIndex; ///< 随机数组的下标

@end

@implementation STMusicRandomTool

- (instancetype)initWithLength:(NSInteger)length {
    self = [super init];
    if (self) {
        self.originLength = length;
        [self resetRandomData];
    }
    return self;
}

#pragma mark - Public

- (void)startRandomWithWillPlayIndex:(NSInteger)willPlayIndex {
    [self resetRandomData];
    // 当前想要播放的歌曲位置
    NSInteger willPlayRandomIndex = [self.randomList indexOfObject:@(willPlayIndex)];
    // 在没有插入其他歌曲的情况下，本来应该播的下一首的下标
    NSInteger nextShouldPlayRandomIndex = [self indexInRange:self.currentIndex + 1];
    // 交换即将播放的，和正在播放的下一首的位置
    [self.randomList exchangeObjectAtIndex:nextShouldPlayRandomIndex withObjectAtIndex:willPlayRandomIndex];
    self.currentIndex = nextShouldPlayRandomIndex;
}

- (void)startRandomWithCurrentPlayIndex:(NSInteger)currentPlayIndex {
    [self resetRandomData];
    // 当前正在播放的歌曲位置
    NSInteger currentPlayRandomIndex = [self.randomList indexOfObject:@(currentPlayIndex)];
    [self.randomList exchangeObjectAtIndex:0 withObjectAtIndex:currentPlayRandomIndex];
    self.currentIndex = 0;
}

#pragma mark - Private

- (NSInteger)indexInRange:(NSInteger)index {
    if (index < 0) {
        return self.originLength - 1;
    }
    if (index > self.originLength - 1) {
        return 0;
    }
    return index;
}

- (void)resetRandomData {
    [self.randomList removeAllObjects];
    for (int i = 0; i < self.originLength; i++) {
        [self.randomList addObject:@(i)];
    }
    [self.randomList sortUsingComparator:^NSComparisonResult(id  _Nonnull obj1, id  _Nonnull obj2) {
        return arc4random() % 3;
    }];
}

#pragma mark - Getter / Setter

- (NSInteger)nextShouldPlay {
    NSInteger nextShouldPlayRandomIndex = [self indexInRange:self.currentIndex + 1];
    self.currentIndex = nextShouldPlayRandomIndex;
    return [self.randomList[nextShouldPlayRandomIndex] integerValue];
}

- (NSInteger)lastShoulfPlay {
    NSInteger nextShouldPlayRandomIndex = [self indexInRange:self.currentIndex - 1];
    self.currentIndex = nextShouldPlayRandomIndex;
    return [self.randomList[nextShouldPlayRandomIndex] integerValue];
}

- (NSMutableArray *)randomList {
    if (!_randomList) {
        _randomList = [NSMutableArray new];
    }
    return _randomList;
}

@end