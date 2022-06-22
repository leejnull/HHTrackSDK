//
//  HHTrackDatabase.h
//  HHTrackSDK
//
//  Created by 李俊 on 2022/6/16.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface HHTrackDatabase : NSObject

@property (nonatomic, copy, readonly) NSString *filePath;
@property (nonatomic, assign, readonly) NSInteger eventCount;

- (instancetype)initWithFilePath:(NSString * _Nullable)filePath;

- (void)insertEvent:(NSDictionary *)event;
- (NSArray<NSDictionary *> *)selectEventsForCount:(NSUInteger)count;
- (BOOL)deleteEventsForCount:(NSUInteger)count;

@end

NS_ASSUME_NONNULL_END
