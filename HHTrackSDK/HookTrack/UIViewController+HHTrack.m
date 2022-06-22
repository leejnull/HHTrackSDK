//
//  UIViewController+HHTrack.m
//  HHTrackSDK
//
//  Created by 李俊 on 2022/6/15.
//

#import "UIViewController+HHTrack.h"
#import "HHTrackManager.h"
#import "HHTrackTool.h"
#import <objc/runtime.h>

@implementation UIViewController (HHTrack)

+ (void)load {
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        [HHTrackTool hookWithClass:[self class] originSelector:@selector(viewDidAppear:) newSelector:@selector(hh_track_viewDidAppear:)];
        [HHTrackTool hookWithClass:[self class] originSelector:@selector(viewDidDisappear:) newSelector:@selector(hh_track_viewDidDisappear:)];
    });
}

- (void)hh_track_viewDidAppear:(BOOL)animated {
    [self hh_track_viewDidAppear:animated];
    
    [self setViewDidAppearDate:[NSDate date]];
    
    [[HHTrackManager sharedInstance] track:@"AppScreenView" properties:@{
        @"screenName": NSStringFromClass(self.class),
    }];
}

- (void)hh_track_viewDidDisappear:(BOOL)animated {
    [self hh_track_viewDidDisappear:animated];
    
    NSDate *appearDate = [self viewDidAppearDate];
    NSInteger duration = 0;
    if (appearDate) {
        duration = [[NSDate date] timeIntervalSinceDate:appearDate];
    }
    
    [[HHTrackManager sharedInstance] track:@"AppScreenClose" properties:@{
        @"screenName": NSStringFromClass(self.class),
        @"eventDuration": @(duration)
    }];
}

- (void)setViewDidAppearDate:(NSDate *)date {
    objc_setAssociatedObject(self, "hh_track_view_did_appear_date", date, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
}

- (NSDate *)viewDidAppearDate {
    return objc_getAssociatedObject(self, "hh_track_view_did_appear_date");
}

@end
