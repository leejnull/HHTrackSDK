//
//  HHTrackTool.m
//  HHTrackSDK
//
//  Created by 李俊 on 2022/6/14.
//

#import "HHTrackTool.h"
#include <sys/sysctl.h>
#import <UIKit/UIKit.h>
#import <AdSupport/AdSupport.h>
#import <AdSupport/ASIdentifierManager.h>
#import <AppTrackingTransparency/ATTrackingManager.h>
#import <objc/runtime.h>
#import <CommonCrypto/CommonHMAC.h>

@implementation HHTrackTool

+ (NSString *)deviceModel {
    size_t size;
    sysctlbyname("hw.machine", NULL, &size, NULL, 0);
    char answer[size];
    sysctlbyname("hw.machine", answer, &size, NULL, 0);
    NSString *results = @(answer);
    return results;
}

+ (NSString *)IDFA {
    if (@available(iOS 14, *)) {
        if ([ATTrackingManager trackingAuthorizationStatus] == ATTrackingManagerAuthorizationStatusAuthorized) {
            return [[[ASIdentifierManager sharedManager] advertisingIdentifier] UUIDString];
        }
    } else {
        if ([ASIdentifierManager sharedManager].advertisingTrackingEnabled) {
            return [[[ASIdentifierManager sharedManager] advertisingIdentifier] UUIDString];
        }
    }
    return nil;
}

+ (NSString *)IDFV {
    return [[UIDevice currentDevice].identifierForVendor UUIDString];
}

+ (NSString *)UUID {
    return [NSUUID UUID].UUIDString;
}

+ (NSString *)deviceId {
    return [NSString stringWithFormat:@"IDFV=%@|IDFA=%@|UUID=%@", [self IDFV] ?: @"", [self IDFA] ?: @"", [self UUID] ?: @""];
}

+ (BOOL)isFirstDay {
    NSString *firstDay = [[NSUserDefaults standardUserDefaults] objectForKey:@"hh_track_is_first_day"];
    if (!firstDay) {
        [self setIsFirstDay];
        return YES;
    }
    NSDate *today = [NSDate date];
    NSDateFormatter *formatter = [[NSDateFormatter alloc] init];
    formatter.dateFormat = @"yyyy-MM-dd";
    NSString *todayDate = [formatter stringFromDate:today];
    BOOL res = ![firstDay isEqualToString:todayDate];
    if (!res) {
        [self setIsFirstDay];
    }
    return res;
}

+ (void)setIsFirstDay {
    NSDate *today = [NSDate date];
    NSDateFormatter *formatter = [[NSDateFormatter alloc] init];
    formatter.dateFormat = @"yyyy-MM-dd";
    NSString *todayDate = [formatter stringFromDate:today];
    [[NSUserDefaults standardUserDefaults] setObject:todayDate forKey:@"hh_track_is_first_day"];
    [[NSUserDefaults standardUserDefaults] synchronize];
}

+ (BOOL)isFirstTime {
    NSString *firstTime = [[NSUserDefaults standardUserDefaults] objectForKey:@"hh_track_is_first_time"];
    if (!firstTime) {
        [self setIsFirstTime];
        return YES;
    }
    NSDate *today = [NSDate date];
    NSDateFormatter *formatter = [[NSDateFormatter alloc] init];
    formatter.dateFormat = @"yyyy-MM-dd";
    NSString *todayDate = [formatter stringFromDate:today];
    BOOL res = ![firstTime isEqualToString:todayDate];
    if (!res) {
        [self setIsFirstTime];
    }
    return res;
}

+ (void)setIsFirstTime {
    NSDate *today = [NSDate date];
    NSDateFormatter *formatter = [[NSDateFormatter alloc] init];
    formatter.dateFormat = @"yyyy-MM-dd";
    NSString *todayDate = [formatter stringFromDate:today];
    [[NSUserDefaults standardUserDefaults] setObject:todayDate forKey:@"hh_track_is_first_time"];
    [[NSUserDefaults standardUserDefaults] synchronize];
}

+ (NSString *)eventTime {
    NSDateFormatter *formatter = [[NSDateFormatter alloc] init];
    formatter.dateFormat = @"yyyy-MM-dd HH:mm:ss";
    return [formatter stringFromDate:[NSDate date]];
}

+ (void)saveAnonymousId:(NSString *)anonymousId {
    [[NSUserDefaults standardUserDefaults] setObject:anonymousId forKey:@"hh_track_anonymous_id"];
    [[NSUserDefaults standardUserDefaults] synchronize];
}

+ (NSString *)anonymousId {
    return [[NSUserDefaults standardUserDefaults] objectForKey:@"hh_track_anonymous_id"];
}

+ (void)saveLoginId:(NSString *)loginId {
    [[NSUserDefaults standardUserDefaults] setObject:loginId forKey:@"hh_track_login_id"];
    [[NSUserDefaults standardUserDefaults] synchronize];
}

+ (NSString *)loginId {
    return [[NSUserDefaults standardUserDefaults] objectForKey:@"hh_track_login_id"];
}

+ (NSDictionary *)screenInfo {
    UIViewController *ctrl = [self findCurrentShowingViewController];
    if (ctrl) {
        return @{
            @"screenName": NSStringFromClass(ctrl.class),
            @"title": ctrl.title ?: @""
        };
    }
    return @{
        @"screenName": @"",
        @"title": @""
    };
}

+ (UIViewController *)findCurrentShowingViewController {
    //获得当前活动窗口的根视图
    UIViewController *vc = [UIApplication sharedApplication].keyWindow.rootViewController;
    UIViewController *currentShowingVC = [self findCurrentShowingViewControllerFrom:vc];
    return currentShowingVC;
}

+ (UIViewController *)findCurrentShowingViewControllerFrom:(UIViewController *)vc {
    UIViewController *currentShowingVC;
    if ([vc presentedViewController]) { //注要优先判断vc是否有弹出其他视图，如有则当前显示的视图肯定是在那上面
        // 当前视图是被presented出来的
        UIViewController *nextRootVC = [vc presentedViewController];
        currentShowingVC = [self findCurrentShowingViewControllerFrom:nextRootVC];
    } else if ([vc isKindOfClass:[UITabBarController class]]) {
        // 根视图为UITabBarController
        UIViewController *nextRootVC = [(UITabBarController *)vc selectedViewController];
        currentShowingVC = [self findCurrentShowingViewControllerFrom:nextRootVC];
    } else if ([vc isKindOfClass:[UINavigationController class]]){
        // 根视图为UINavigationController
        UIViewController *nextRootVC = [(UINavigationController *)vc visibleViewController];
        currentShowingVC = [self findCurrentShowingViewControllerFrom:nextRootVC];
    } else {
        // 根视图为非导航类
        currentShowingVC = vc;
    }
    
    return currentShowingVC;
}

+ (void)hookWithClass:(Class)hookClass originSelector:(SEL)originSelector newSelector:(SEL)newSelector {
    Method originMethod = class_getInstanceMethod(hookClass, originSelector);
    Method newMethod = class_getInstanceMethod(hookClass, newSelector);
    BOOL added = class_addMethod(hookClass, originSelector, method_getImplementation(newMethod), method_getTypeEncoding(newMethod));
    if (added) {
        class_replaceMethod(hookClass, newSelector, method_getImplementation(originMethod), method_getTypeEncoding(originMethod));
    } else {
        method_exchangeImplementations(originMethod, newMethod);
    }
}

+ (NSString *)md5:(NSString *)hashString {
    const char *input = [hashString UTF8String];
    unsigned char digest[CC_MD5_DIGEST_LENGTH];
    
    CC_MD5(input, (CC_LONG)strlen(input), digest);

    NSMutableString *result = [NSMutableString stringWithCapacity:CC_MD5_DIGEST_LENGTH*2];
    for (int i = 0; i < CC_MD5_DIGEST_LENGTH; i++) {
        [result appendFormat:@"%02x", digest[i]];
    }
    
    return result.copy;
}

@end
