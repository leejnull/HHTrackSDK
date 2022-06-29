//
//  HHTrackNetwork.m
//  HHTrackSDK
//
//  Created by 李俊 on 2022/6/17.
//

#import "HHTrackNetwork.h"
#import "HHTrackTool.h"

typedef void(^HHTrackURLSessionTaskCompletionHandler)(NSData * _Nullable data, NSURLResponse * _Nullable response, NSError * _Nullable error);

@interface HHTrackNetwork () <NSURLSessionDelegate>

@property (nonatomic, strong) NSURLSession *session;

@end

@implementation HHTrackNetwork

- (instancetype)initWithServerURL:(NSURL *)serverURL {
    self = [super init];
    if (self) {
        _serverURL = serverURL;
        
        NSURLSessionConfiguration *configuration = [NSURLSessionConfiguration defaultSessionConfiguration];
        configuration.HTTPMaximumConnectionsPerHost = 5;
        configuration.timeoutIntervalForRequest = 30;
        configuration.allowsCellularAccess = YES;
        
        NSOperationQueue *queue = [[NSOperationQueue alloc] init];
        queue.maxConcurrentOperationCount = 1;
        
        _session = [NSURLSession sessionWithConfiguration:configuration delegate:self delegateQueue:queue];
    }
    return self;
}

- (NSDictionary *)buildJSONDictWithEvents:(NSArray<NSDictionary *> *)events {
    NSMutableDictionary *commonDict = @{}.mutableCopy;
    NSMutableArray *eventArray = @[].mutableCopy;
    for (NSDictionary *dict in events) {
        [commonDict addEntriesFromDictionary:dict[@"data"][@"common"]];
        NSMutableDictionary *eventDict = @{}.mutableCopy;
        eventDict[@"eventName"] = dict[@"event"];
        eventDict[@"eventTime"] = dict[@"eventTime"];
        eventDict[@"sessionId"] = dict[@"sessionId"];
        eventDict[@"eventData"] = dict[@"data"][@"event"];
        [eventArray addObject:eventDict];
    }
    commonDict[@"time"] = [HHTrackTool eventTime];
    return @{
        @"common": commonDict,
        @"eventList": eventArray
    };
}

- (NSURLRequest *)buildRequestWithJSONDict:(NSDictionary *)dict {
    NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:self.serverURL];
    NSError *error;
    request.HTTPBody = [NSJSONSerialization dataWithJSONObject:dict options:NSJSONWritingFragmentsAllowed error:&error];
    if (error) {
        NSLog(@"build request error: %@", error);
        return nil;
    }
    request.allHTTPHeaderFields = @{
        @"Content-Type": @"application/json",
    };
    request.HTTPMethod = @"POST";
    return request;
}

- (BOOL)flushEvents:(NSArray<NSDictionary *> *)events {
    NSDictionary *jsonDict = [self buildJSONDictWithEvents:events];
    NSURLRequest *request = [self buildRequestWithJSONDict:jsonDict];
    
    __block BOOL flushSuccess = NO;
    dispatch_semaphore_t flushSemaphore = dispatch_semaphore_create(0);
    HHTrackURLSessionTaskCompletionHandler handler = ^(NSData * _Nullable data, NSURLResponse * _Nullable response, NSError * _Nullable error) {
        if (error) {
            NSLog(@"flush events error: %@", error);
            dispatch_semaphore_signal(flushSemaphore);
            return;
        }
        NSInteger statusCode = [(NSHTTPURLResponse *)response statusCode];
        if (statusCode >= 200 && statusCode < 300) {
            NSLog(@"flush events success: %@", jsonDict);
            flushSuccess = YES;
        } else {
            // 失败
            NSString *desc = [NSString stringWithFormat:@"flush events error, statusCode: %ld, events: %@", (long)statusCode, jsonDict];
            NSLog(@"flush events error: %@", desc);
        }
        dispatch_semaphore_signal(flushSemaphore);
    };
    
    NSURLSessionDataTask *task = [self.session dataTaskWithRequest:request completionHandler:handler];
    // 执行
    [task resume];
    
    dispatch_semaphore_wait(flushSemaphore, DISPATCH_TIME_FOREVER);
    
    return flushSuccess;
}

@end
