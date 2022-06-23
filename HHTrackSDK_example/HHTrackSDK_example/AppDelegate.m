//
//  AppDelegate.m
//  HHTrackSDK_example
//
//  Created by 李俊 on 2022/6/14.
//

#import "AppDelegate.h"
#import <HHTrackSDK/HHTrackManager.h>

@interface AppDelegate ()

@end

@implementation AppDelegate


- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions {
    // Override point for customization after application launch.
    [HHTrackManager registeWithUrl:@"http://cn-dev02-api.henhenchina.com/cpp-databricks/v1/collect"];
    [HHTrackManager sharedInstance].flushBulkSize = 10;
    [HHTrackManager sharedInstance].onDynamicProperties = ^NSDictionary<NSString *,id> * _Nonnull{
        NSMutableDictionary *dict = @{}.mutableCopy;
        NSString *userId = [[NSUserDefaults standardUserDefaults] objectForKey:@"user_id"];
        if (userId.length) {
            [dict addEntriesFromDictionary:@{
                @"user_id": userId,
                @"user_type": @1
            }];
        }
        return dict;
    };
    [HHTrackManager sharedInstance].onEventStream = ^(NSString * _Nonnull event) {
        NSLog(@"[Event]: %@", event);
    };
    return YES;
}


#pragma mark - UISceneSession lifecycle


- (UISceneConfiguration *)application:(UIApplication *)application configurationForConnectingSceneSession:(UISceneSession *)connectingSceneSession options:(UISceneConnectionOptions *)options {
    // Called when a new scene session is being created.
    // Use this method to select a configuration to create the new scene with.
    return [[UISceneConfiguration alloc] initWithName:@"Default Configuration" sessionRole:connectingSceneSession.role];
}


- (void)application:(UIApplication *)application didDiscardSceneSessions:(NSSet<UISceneSession *> *)sceneSessions {
    // Called when the user discards a scene session.
    // If any sessions were discarded while the application was not running, this will be called shortly after application:didFinishLaunchingWithOptions.
    // Use this method to release any resources that were specific to the discarded scenes, as they will not return.
}


@end
