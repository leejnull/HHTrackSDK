//
//  HHTrackTool.h
//  HHTrackSDK
//
//  Created by 李俊 on 2022/6/14.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface HHTrackTool : NSObject

/// 获取设备型号
+ (NSString *)deviceModel;

+ (NSString *)IDFA;
+ (NSString *)IDFV;
+ (NSString *)UUID;

/// 获取设备Id
+ (NSString *)deviceId;

/// 是否首次
+ (BOOL)isFirstDay;

/// 是否首次访问
+ (BOOL)isFirstTime;

/// 事件发生时间
+ (NSString *)eventTime;

+ (void)saveAnonymousId:(NSString *)anonymousId;
+ (NSString *)anonymousId;

+ (void)saveLoginId:(NSString *)loginId;
+ (NSString *)loginId;

+ (NSDictionary *)screenInfo;

+ (void)hookWithClass:(Class)hookClass originSelector:(SEL)originSelector newSelector:(SEL)newSelector;

+ (NSString *)md5:(NSString *)hashString;

@end

NS_ASSUME_NONNULL_END
