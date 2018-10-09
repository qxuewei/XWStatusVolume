//
//  XWStatusVolumeManager.m
//  BeijingLive
//
//  Created by 邱学伟 on 2018/4/19.
//  Copyright © 2018年 邱学伟. All rights reserved.
//

#import "XWStatusVolumeManager.h"
#import <MediaPlayer/MediaPlayer.h>
#import <AVFoundation/AVFoundation.h>
#import "XWStatusVolumeVC.h"

#define kStatusVolumeScreenSize [UIScreen mainScreen].bounds

#define kStatusVolumeColorHexCode(hex) [UIColor colorWithRed:((hex >> 16) & 0xFF)/255.0  green:((hex >> 8) & 0xFF)/255.0 blue:(hex & 0xFF)/255.0  alpha:1.0]

/// 判断iPhone X
//#define kStatusVolumeIS_IPHONEX (([[UIScreen mainScreen] bounds].size.height - 812) ? NO : YES)


/// 判断iPhone X / XS / XS MAX / XR
static inline BOOL isIPhoneXSeries() {
    BOOL iPhoneXSeries = NO;
    if (UIDevice.currentDevice.userInterfaceIdiom != UIUserInterfaceIdiomPhone) {
        return iPhoneXSeries;
    }
    
    if (@available(iOS 11.0, *)) {
        UIWindow *mainWindow = [[[UIApplication sharedApplication] delegate] window];
        if (mainWindow.safeAreaInsets.bottom > 0.0) {
            iPhoneXSeries = YES;
        }
    }
    
    return iPhoneXSeries;
}

/// 判断竖屏
#define kStatusVolumeIsPortrait ([[UIApplication sharedApplication] statusBarOrientation] == UIInterfaceOrientationPortrait || [[UIApplication sharedApplication] statusBarOrientation] == UIInterfaceOrientationPortraitUpsideDown)

@interface XWStatusVolumeManager ()

/**
 是否隐藏状态栏
 */
@property (nonatomic, assign) BOOL isPrefersStatusBarHidden;
@property (nonatomic, strong) XWStatusVolumeVC *statusVolumeVC;

@property (nonatomic, assign) NSInteger displayCount;
@property (nonatomic, strong) UIColor *indicatorTintColor;
@property (nonatomic, strong) UIColor *barBackgroundColor;
@property (nonatomic, assign) NSTimeInterval displayTimeInterval;

@property (nonatomic, strong) UIView <XWVolumeView> *volumeView;
@property (nonatomic, strong) MPVolumeView *systemVolumeView;
@property (nonatomic, readonly, strong) UIWindow *overlayWindow;
@end

/// 进度视图
@interface XWStatusVolumeView : UIView <XWVolumeView>
@property (nonatomic, strong) UIProgressView *progressView;
@end

@implementation XWStatusVolumeManager
@synthesize overlayWindow = _overlayWindow;

#pragma mark - public
+ (XWStatusVolumeManager *)sharedInstance {
    static XWStatusVolumeManager *statusVolumeManager;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        statusVolumeManager = [[self alloc] init];
    });
    return statusVolumeManager;
}

+ (void)regiseter: (UIView<XWVolumeView> *_Nullable)volumeView {
    if (volumeView) {
        [self sharedInstance].volumeView = volumeView;
    }else{
        [self sharedInstance].volumeView = [[XWStatusVolumeView alloc] init];
    }
    [self sharedInstance].displayTimeInterval = 1.0;
    [self sharedInstance].indicatorTintColor = kStatusVolumeColorHexCode(0xc83838);
    if (isIPhoneXSeries() && kStatusVolumeIsPortrait) {
        [self sharedInstance].barBackgroundColor = [UIColor whiteColor];
    }else{
        [self sharedInstance].barBackgroundColor = [UIColor clearColor];
    }
}

+ (void)addCustomVolumeView {
    [self setupUI];
    [self sharedInstance].systemVolumeView = [[MPVolumeView alloc] initWithFrame:CGRectMake(-100, -100, 1, 1)];
    [[self sharedInstance].overlayWindow addSubview:[self sharedInstance].systemVolumeView];
    [self sharedInstance].overlayWindow.hidden = false;
    [[AVAudioSession sharedInstance] setActive:true error:nil];
    [[NSNotificationCenter defaultCenter] addObserver:[self sharedInstance] selector:@selector(volumeChangedMethod:) name:@"AVSystemController_SystemVolumeDidChangeNotification" object:nil];
}

+ (void)removeVolumeView {
    [[self sharedInstance].systemVolumeView removeFromSuperview];
    [[NSNotificationCenter defaultCenter] removeObserver:[self sharedInstance]];
    [self sharedInstance].overlayWindow.hidden = true;
}

#pragma mark - system

#pragma mark - private
+ (void)setupUI {
    if ([[self volumeView] isKindOfClass:[XWStatusVolumeView class]]) {
        XWStatusVolumeView *statusVolumeView = (XWStatusVolumeView *)[self volumeView];
        statusVolumeView.backgroundColor = [self barBackgroundColor];
        statusVolumeView.progressView.tintColor = [self indicatorTintColor];
    }
}

- (void)volumeChangedMethod: (NSNotification *)notification {
    [[AVAudioSession sharedInstance] setActive:true error:nil];
    if([[notification.userInfo objectForKey:@"AVSystemController_AudioVolumeChangeReasonNotificationParameter"] isEqualToString:@"ExplicitVolumeChange"]) {
        float volume = [[[notification userInfo] objectForKey:@"AVSystemController_AudioVolumeNotificationParameter"] floatValue];
        [self displayVolumeChanged:[AVAudioSession sharedInstance].outputVolume to:volume];
    }
}

- (void)displayVolumeChanged:(float)from to:(float)to {
    NSTimeInterval appearTimeInterval = 0.2;
    self.volumeView.hidden = false;
    
    if (self.displayCount == 0) {
        self.volumeView.frame = CGRectMake(0, -(_volumeView.viewHeight), kStatusVolumeScreenSize.size.width, _volumeView.viewHeight);
        self.displayCount += 1;
        [self.overlayWindow.rootViewController.view addSubview:self.volumeView];
        [UIView animateWithDuration:appearTimeInterval animations:^{
            self.volumeView.transform = CGAffineTransformMakeTranslation(0, self.volumeView.viewHeight);
        } completion:^(BOOL finished) {
            [self.volumeView updateVolume:to];
        }];
    }else{
        self.displayCount += 1;
    }

    [self.volumeView setCurrentVolume:from];
    
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(self.displayTimeInterval * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        self.displayCount -= 1;
        if (self.displayCount == 0) {
            [UIView animateWithDuration:appearTimeInterval animations:^{
                self.volumeView.transform = CGAffineTransformIdentity;
            } completion:^(BOOL finished) {
                self.volumeView.hidden = true;
            }];
        }
    });
}

#pragma mark - setter
- (void)setIsPrefersStatusBarHidden:(BOOL)isPrefersStatusBarHidden {
    _isPrefersStatusBarHidden = isPrefersStatusBarHidden;
    self.statusVolumeVC.isPrefersStatusBarHidden = isPrefersStatusBarHidden;
}

#pragma mark - getter
- (UIWindow *)overlayWindow {
    if(!_overlayWindow){
        _overlayWindow = [[UIWindow alloc] initWithFrame:kStatusVolumeScreenSize];
        _overlayWindow.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
        _overlayWindow.backgroundColor = [UIColor clearColor];
        _overlayWindow.userInteractionEnabled = NO;
        _overlayWindow.windowLevel = UIWindowLevelStatusBar;
        _overlayWindow.rootViewController = self.statusVolumeVC;
        _overlayWindow.rootViewController.view.backgroundColor = [UIColor clearColor];
    }
    return _overlayWindow;
}

- (XWStatusVolumeVC *)statusVolumeVC {
    if(!_statusVolumeVC){
        _statusVolumeVC = [[XWStatusVolumeVC alloc] init];
    }
    return _statusVolumeVC;
}

#pragma mark - class proterty
+ (NSTimeInterval)displayTimeInterval {
    return [self sharedInstance].displayTimeInterval;
}
+ (void)setDisplayTimeInterval:(NSTimeInterval)displayTimeInterval {
    [self sharedInstance].displayTimeInterval = displayTimeInterval;
}

+ (UIColor *)indicatorTintColor {
    return [self sharedInstance].indicatorTintColor;
}
+ (void)setIndicatorTintColor:(UIColor *)indicatorTintColor {
    [self sharedInstance].indicatorTintColor = indicatorTintColor;
}

+ (UIColor *)barBackgroundColor {
    return [self sharedInstance].barBackgroundColor;
}
+ (void)setBarBackgroundColor:(UIColor *)barBackgroundColor {
    [self sharedInstance].barBackgroundColor = barBackgroundColor;
}

+ (UIView <XWVolumeView> *)volumeView {
    return [self sharedInstance].volumeView;
}

+ (BOOL)isPrefersStatusBarHidden {
    return [self sharedInstance].isPrefersStatusBarHidden;
}
+ (void)setIsPrefersStatusBarHidden:(BOOL)isPrefersStatusBarHidden {
    [self sharedInstance].isPrefersStatusBarHidden = isPrefersStatusBarHidden;
}

@end

@implementation XWStatusVolumeView
static const CGFloat cLeftMargin = 0.0; //左间距
//static const CGFloat cBottomMargin = 0.0; //底部间距
static const CGFloat cHeight = 3.0; //高度

#pragma mark - system
- (instancetype)initWithFrame:(CGRect)frame {
    if (self = [super initWithFrame:frame]) {
        [self addSubview:self.progressView];
    }
    return self;
}

- (void)layoutSubviews {
    [super layoutSubviews];
    self.progressView.frame = CGRectMake(cLeftMargin, self.viewHeight - cHeight, [UIScreen mainScreen].bounds.size.width - 2 * cLeftMargin, cHeight);
}

#pragma mark - private
- (void)setCurrentVolume:(float)volume {
    _progressView.tintColor = XWStatusVolumeManager.indicatorTintColor;
    _progressView.trackTintColor = [[UIColor blackColor]  colorWithAlphaComponent:0.5];
    _progressView.backgroundColor = XWStatusVolumeManager.barBackgroundColor;
    _progressView.progress = volume;
}

- (void)updateVolume:(float)volume {
    [_progressView setProgress:volume animated:YES];
}

- (float)viewHeight {

    if (isIPhoneXSeries() && kStatusVolumeIsPortrait) {
        /// 竖屏 iPhone X 适配
        return [UIApplication sharedApplication].statusBarFrame.size.height;
    }
    return cHeight;
}

#pragma mark - getter
- (UIProgressView *)progressView {
    if(!_progressView){
        _progressView = [[UIProgressView alloc] init];
    }
    return _progressView;
}
@end
