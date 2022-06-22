//
//  HHTrackManager.m
//  HHTrackSDK
//
//  Created by 李俊 on 2022/6/14.
//

#import "HHTrackManager.h"
#import <UIKit/UIKit.h>
#import "HHTrackTool.h"
#import "HHTrackDatabase.h"
#import "HHTrackNetwork.h"
#import "UIViewController+HHTrack.h"

@interface HHTrackManager ()

@property (nonatomic, strong) NSDictionary<NSString *, id> *automaticProperties;
@property (nonatomic, strong) NSDictionary<NSString *, id> *staticProperties;
@property (nonatomic, assign) BOOL applicationWillResignActive;
@property (nonatomic, assign) BOOL applicationDidFinishLaunching;

/// UUID+时间戳 md5
@property (nonatomic, copy) NSString *sessionId;
@property (nonatomic, strong) NSDate *appStartDate;

@property (nonatomic, strong) HHTrackDatabase *database;
@property (nonatomic, strong) HHTrackNetwork *network;

@property (nonatomic, strong) dispatch_queue_t serialQueue;

@end

@implementation HHTrackManager

static HHTrackManager *instance = nil;

+ (void)registeWithUrl:(NSString *)url {
    NSLog(@"注册URL: %@", url);
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        instance = [[HHTrackManager alloc] initWithUrl:url];
    });
}

- (instancetype)initWithUrl:(NSString *)url {
    self = [super init];
    if (self) {
        _automaticProperties = [self collectAutomaticProperties];
        _database = [[HHTrackDatabase alloc] init];
        _network = [[HHTrackNetwork alloc] initWithServerURL:[NSURL URLWithString:url]];
        _serialQueue = dispatch_queue_create([NSString stringWithFormat:@"hh_track_serial_queue_%p", self].UTF8String, DISPATCH_QUEUE_SERIAL);
        _flushBulkSize = 50;
        
        [self setupListeners];
    }
    return self;
}

+ (HHTrackManager *)sharedInstance {
    return instance;
}

- (void)dealloc {
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

#pragma mark - notifications

- (void)setupListeners {
    NSNotificationCenter *center = [NSNotificationCenter defaultCenter];
    // 应用程序退出 - 退到后台
    [center addObserver:self selector:@selector(applicationDidEnterBackground:) name:UIApplicationDidEnterBackgroundNotification object:nil];
    // 应用程序启动
    [center addObserver:self selector:@selector(applicationDidFinishLaunching:) name:UIApplicationDidFinishLaunchingNotification object:nil];
    [center addObserver:self selector:@selector(applicationDidBecomeActive:) name:UIApplicationDidBecomeActiveNotification object:nil];
    [center addObserver:self selector:@selector(applicationWillResignActive:) name:UIApplicationWillResignActiveNotification object:nil];
}

- (void)applicationDidEnterBackground:(NSNotification *)notification {
    self.applicationWillResignActive = NO;
    
    NSInteger interval = [[NSDate date] timeIntervalSinceDate:self.appStartDate];
    NSDictionary *properties = @{@"eventDuration": @(interval)};
    
    [self track:@"AppEnd" properties:properties];
}

- (void)applicationDidFinishLaunching:(NSNotification *)notification {
    self.applicationDidFinishLaunching = YES;
}

- (void)applicationDidBecomeActive:(NSNotification *)notification {
    if (self.applicationWillResignActive) {
        self.applicationWillResignActive = NO;
        return;
    }
    self.appStartDate = [NSDate date];
    
    NSDictionary *properties = @{
        @"resumeFromBackground": @(!self.applicationDidFinishLaunching),
    };
    
    if (!self.applicationDidFinishLaunching) {
        self.sessionId = nil;
    }
    self.applicationDidFinishLaunching = NO;
    
    [self track:@"AppStart" properties:properties];
}

- (void)applicationWillResignActive:(NSNotification *)notification {
    self.applicationWillResignActive = YES;
}

#pragma mark - method

- (void)flush {
    dispatch_async(self.serialQueue, ^{
        [self flushByEventCount:self.flushBulkSize];
    });
}

- (void)flushByEventCount:(NSUInteger)count {
    NSArray<NSDictionary *> *events = [self.database selectEventsForCount:count];
    if (events.count == 0 || ![self.network flushEvents:events]) {
        return;
    }
    if (![self.database deleteEventsForCount:count]) {
        return;
    }
    NSLog(@"flush success");
}

- (void)track:(NSString *)eventName properties:(NSDictionary<NSString *,id> *)properties {
    if (!eventName || eventName.length == 0) {
        return;
    }
    NSMutableDictionary *eventDict = @{}.mutableCopy;
    // 设置事件名称
    eventDict[@"event"] = eventName;
    // 事件发生时间
    eventDict[@"eventTime"] = [HHTrackTool eventTime];
    // 事件内容
    NSMutableDictionary *dataDict = @{}.mutableCopy;
    // 通用数据（第一次上传）
    NSMutableDictionary *commonDict = @{}.mutableCopy;
    if (!self.sessionId) {
        [commonDict addEntriesFromDictionary:self.automaticProperties];
        NSString *hashString = [NSString stringWithFormat:@"%@|%f", [HHTrackTool UUID], [[NSDate date] timeIntervalSince1970]];
        self.sessionId = [HHTrackTool md5:hashString];
    }
    // 事件会话
    eventDict[@"sessionId"] = self.sessionId;
    
    // 业务侧静态属性
    if (self.staticProperties) {
        [commonDict addEntriesFromDictionary:self.staticProperties];
    }
    // 业务侧动态属性
    if (self.onDynamicProperties) {
        NSDictionary *dynamicProperties = self.onDynamicProperties();
        if (dynamicProperties) {
            [commonDict addEntriesFromDictionary:dynamicProperties];
        }
    }
    
    dataDict[@"common"] = commonDict;
    dataDict[@"event"] = properties ?: @{};
    
    // 设置事件内容
    eventDict[@"data"] = dataDict;
    
    dispatch_async(self.serialQueue, ^{
        [self printEvent:eventDict];
        [self.database insertEvent:eventDict];
        
        if (self.database.eventCount >= self.flushBulkSize) {
            [self flush];
        }
    });
}

- (void)printEvent:(NSDictionary *)event {
#if DEBUG
    NSError *error = nil;
    NSData *data = [NSJSONSerialization dataWithJSONObject:event options:NSJSONWritingPrettyPrinted error:&error];
    if (error) {
        NSLog(@"JSON Serialized Error: %@", error);
    }
    NSString *json = [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding];
    NSLog(@"[Event]: %@", json);
#endif
}

#pragma mark - setter

- (void)setOnStaticProperties:(NSDictionary<NSString *,id> * _Nonnull (^)(void))onStaticProperties {
    self.staticProperties = onStaticProperties();
}

#pragma mark - getter

- (NSDictionary<NSString *, id> *)collectAutomaticProperties {
    NSMutableDictionary *properties = @{}.mutableCopy;
    // 应用版本号
    properties[@"appVersion"] = NSBundle.mainBundle.infoDictionary[@"CFBundleShortVersionString"];
    // 设备制造商
    properties[@"manufacturer"] = @"Apple";
    // 手机型号
    properties[@"model"] = [HHTrackTool deviceModel];
    // 操作系统版本号
    properties[@"osVersion"] = UIDevice.currentDevice.systemVersion;
    // 屏幕高度
    properties[@"screenHeight"] = @([UIScreen mainScreen].bounds.size.height);
    // 屏幕宽度
    properties[@"screenWidth"] = @([UIScreen mainScreen].bounds.size.width);
    // 设备ID
    properties[@"deviceId"] = [HHTrackTool deviceId];
    return properties;
}

@end
