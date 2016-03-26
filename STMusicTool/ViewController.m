//
//  ViewController.m
//  STMusicTool
//
//  Created by TangJR on 3/24/16.
//  Copyright © 2016 tangjr. All rights reserved.
//

#import "ViewController.h"
#import <MediaPlayer/MediaPlayer.h>
#import "STMusicTool.h"

@interface ViewController () <STMusicToolDelegate>

@property (strong, nonatomic) STMusicTool *tool;
@property (copy, nonatomic) NSArray *musicList;

@property (weak, nonatomic) IBOutlet UISlider *slider;
@property (weak, nonatomic) IBOutlet UILabel *label;

@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view, typically from a nib.
    
    self.tool = [STMusicTool new];
    self.tool.delegate = self;
    self.musicList = self.tool.currentPlayList;
    
    self.tool.sortType = STMusicSortTypeTime;
    
    [self.tool play];
}

#pragma mark - STMusicToolDelegate

- (void)musicTool:(STMusicTool *)musicTool currentProgress:(float)currentProgress {
    self.slider.value = currentProgress;
}

- (void)musicTool:(STMusicTool *)musicTool finishWithIndex:(NSInteger)finishIndex {
    NSLog(@"播放完歌曲 %@", ((MPMediaItem *)self.musicList[finishIndex]).title);
}

- (void)musicTool:(STMusicTool *)musicTool playWithIndex:(NSInteger)index {
    NSLog(@"开始播放歌曲 %@", ((MPMediaItem *)self.musicList[index]).title);
}

- (void)musicTool:(STMusicTool *)musicTool prepareToPlayWithIndex:(NSInteger)index {
    NSLog(@"准备播放歌曲 %@", ((MPMediaItem *)self.musicList[index]).title);
    self.label.text = ((MPMediaItem *)self.musicList[index]).title;
}

- (void)musicTool:(STMusicTool *)musicTool playWithError:(NSError *)error {
    NSLog(@"播放失败");
}

- (void)musicTool:(STMusicTool *)musicTool musicListChanged:(NSArray *)musicList {
    NSLog(@"歌曲列表变化");
    self.musicList = musicList;
    
    for (MPMediaItem *item in self.musicList) {
        NSLog(@"%@", item.title);
    }
}

#pragma mark - Button Tapped

- (IBAction)refreshButtonTapped:(id)sender {
    [self.tool refreshMusicList];
}

- (IBAction)controlSegmentValueChanged:(UISegmentedControl *)sender {
    if (sender.selectedSegmentIndex == 0) {
        [self.tool play];
        return;
    }
    if (sender.selectedSegmentIndex == 1) {
        [self.tool pause];
        return;
    }
}

- (IBAction)lastButtonTapped:(UIButton *)sender {
    [self.tool playLast];
}

- (IBAction)nextButtonTapped:(UIButton *)sender {
    [self.tool playNext];
}

- (IBAction)repeatSegmentValueChanged:(UISegmentedControl *)sender {
    self.tool.playType = sender.selectedSegmentIndex;
}

- (IBAction)sliderValueChanged:(UISlider *)sender {
    [self.tool playAtProgress:sender.value];
}

@end