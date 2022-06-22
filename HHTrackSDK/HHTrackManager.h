//
//  HHTrackManager.h
//  HHTrackSDK
//
//  Created by 李俊 on 2022/6/14.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface HHTrackManager : NSObject

/// 静态属性，在初始化阶段设置，属性不会再变更
@property (nonatomic, copy) NSDictionary<NSString *, id> *(^onStaticProperties)(void);

/// 动态属性，每次都会调用获取
@property (nonatomic, copy) NSDictionary<NSString *, id> *(^onDynamicProperties)(void);

/// 匿名用户Id，默认按照 IDFV > IDFA > UUID的优先级获取
@property (nonatomic, copy) NSString *anonymousId;

/// 上传数量大小，默认50
@property (nonatomic, assign) NSUInteger flushBulkSize;

+ (HHTrackManager *)sharedInstance;

+ (void)registeWithUrl:(NSString *)url;

- (void)track:(NSString *)eventName properties:(NSDictionary<NSString *, id> * _Nullable)properties;

/// 登录建立绑定关系
/// @param loginId 用户id
- (void)login:(NSString *)loginId;

- (void)flush;

@end

NS_ASSUME_NONNULL_END
