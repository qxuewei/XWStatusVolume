//
//  XWStatusVolumeVC.m
//  BeijingLive
//
//  Created by 邱学伟 on 2018/4/20.
//  Copyright © 2018年 邱学伟. All rights reserved.
//

#import "XWStatusVolumeVC.h"

@interface XWStatusVolumeVC ()

@end

@implementation XWStatusVolumeVC

- (void)viewDidLoad {
    [super viewDidLoad];
    
}

// 是否隐藏状态栏
- (BOOL)prefersStatusBarHidden
{
    return self.isPrefersStatusBarHidden;
}


- (void)setIsPrefersStatusBarHidden:(BOOL)isPrefersStatusBarHidden {
    _isPrefersStatusBarHidden = isPrefersStatusBarHidden;
    [self setNeedsStatusBarAppearanceUpdate];
}
@end
