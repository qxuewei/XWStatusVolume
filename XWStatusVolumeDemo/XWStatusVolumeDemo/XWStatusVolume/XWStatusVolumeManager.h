//
//  XWStatusVolumeManager.h
//  BeijingLive
//
//  Created by 邱学伟 on 2018/4/19.
//  Copyright © 2018年 邱学伟. All rights reserved.
//  全局音量视图

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>

/// 进度视图可custom
@protocol XWVolumeView <NSObject>
@optional
- (void)setCurrentVolume:(float)volume;
- (void)updateVolume:(float)volume;
- (float)viewHeight;
@end

@interface XWStatusVolumeManager : NSObject

/**
 是否隐藏状态栏
 */
@property (class, nonatomic, assign) BOOL isPrefersStatusBarHidden;

/**
 custom进度视图
 */
@property (class, nonatomic, readonly, strong, nullable) UIView <XWVolumeView> *volumeView;
/**
 进度条颜色
 */
@property (class, nonatomic, strong, nonnull) UIColor *indicatorTintColor;
/**
 背景色
 */
@property (class, nonatomic, strong, nonnull) UIColor *barBackgroundColor;
/**
 出现时间 默认1s
 */
@property (class, nonatomic, assign) NSTimeInterval displayTimeInterval;

+ (void)regiseter: (UIView<XWVolumeView> *_Nullable)volumeView;
+ (void)addCustomVolumeView;
+ (void)removeVolumeView;
@end
