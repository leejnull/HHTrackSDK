//
//  HHTrackNetwork.h
//  HHTrackSDK
//
//  Created by 李俊 on 2022/6/17.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface HHTrackNetwork : NSObject

@property (nonatomic, strong) NSURL *serverURL;

- (instancetype)initWithServerURL:(NSURL *)serverURL;

- (instancetype)init NS_UNAVAILABLE;

- (BOOL)flushEvents:(NSArray<NSDictionary *> *)events;

@end

NS_ASSUME_NONNULL_END
