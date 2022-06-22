//
//  HHTrackDatabase.m
//  HHTrackSDK
//
//  Created by 李俊 on 2022/6/16.
//

#import "HHTrackDatabase.h"
#import <sqlite3.h>

static NSString * const kHHTrackDatabaseName = @"HHTrackDatabase.sqlite";

static sqlite3 *db;
static sqlite3_stmt *insertStmt = NULL;
static NSUInteger lastSelectEventCount = 50;
static sqlite3_stmt *selectStmt = NULL;

@interface HHTrackDatabase ()

@property (nonatomic, strong) dispatch_queue_t eventsQueue;
@property (nonatomic, assign) NSInteger eventCount;

@end

@implementation HHTrackDatabase

- (instancetype)initWithFilePath:(NSString *)filePath {
    self = [super init];
    if (self) {
        _filePath = filePath ?: [NSSearchPathForDirectoriesInDomains(NSCachesDirectory, NSUserDomainMask, YES).firstObject stringByAppendingPathComponent:kHHTrackDatabaseName];
        _eventsQueue = dispatch_queue_create([NSString stringWithFormat:@"hh_track_events_queue_%p", self].UTF8String, DISPATCH_QUEUE_SERIAL);
        
        [self open];
        [self queryLocalDatabaseEventCount];
    }
    return self;
}

- (instancetype)init {
    return [self initWithFilePath:nil];
}

- (void)open {
    dispatch_async(self.eventsQueue, ^{
        // 初始化sqlite
        if (sqlite3_initialize() != SQLITE_OK) {
            return;
        }
        // 打开数据库，获取指针
        if (sqlite3_open_v2(self.filePath.UTF8String, &db, SQLITE_OPEN_READWRITE | SQLITE_OPEN_CREATE, NULL) != SQLITE_OK) {
            NSLog(@"SQLite stmt prepare error: %s", sqlite3_errmsg(db));
            return;
        }
        char *error;
        // 创建数据库表
        NSString *sql = @"create table if not exists events (id integer primary key autoincrement, event_name text not null, event_time text not null, event_data blob, session_id text not null)";
        if (sqlite3_exec(db, sql.UTF8String, NULL, NULL, &error) != SQLITE_OK) {
            NSLog(@"create events failure: %s", error);
            return;
        }
        
        NSLog(@"open events success: %@", self.filePath);
    });
}

- (void)insertEvent:(NSDictionary *)event {
    dispatch_async(self.eventsQueue, ^{
        NSString *eventName = event[@"event"];
        NSString *eventTime = event[@"eventTime"];
        NSString *sessionId = event[@"sessionId"];
        NSDictionary *dataDict = event[@"data"];
        NSError *error;
        NSData *data = [NSJSONSerialization dataWithJSONObject:dataDict options:NSJSONWritingPrettyPrinted error:&error];
        if (error) {
            NSLog(@"inert event json parse failure: %@", error);
            return;
        }
        
        if (insertStmt) {
            sqlite3_reset(insertStmt);
        } else {
            NSString *sql = @"insert into events (event_name, event_time, event_data, session_id) values (?, ?, ?, ?)";
            if (sqlite3_prepare_v2(db, sql.UTF8String, -1, &insertStmt, NULL) != SQLITE_OK) {
                NSLog(@"insert event prepare failure: %s", sqlite3_errmsg(db));
                return;
            }
        }
        
        sqlite3_bind_text(insertStmt, 1, eventName.UTF8String, -1, NULL);
        sqlite3_bind_text(insertStmt, 2, eventTime.UTF8String, -1, NULL);
        sqlite3_bind_blob(insertStmt, 3, data.bytes, (int)data.length, NULL);
        sqlite3_bind_text(insertStmt, 4, sessionId.UTF8String, -1, NULL);
        
        if (sqlite3_step(insertStmt) != SQLITE_DONE) {
            NSLog(@"insert event step failure: %s", sqlite3_errmsg(db));
            return;
        }
        self.eventCount += 1;
    });
}

- (NSArray<NSDictionary *> *)selectEventsForCount:(NSUInteger)count {
    NSMutableArray<NSDictionary *> *events = [NSMutableArray arrayWithCapacity:count];
    dispatch_sync(self.eventsQueue, ^{
        if (self.eventCount == 0) {
            return;
        }
        if (lastSelectEventCount != count) {
            selectStmt = NULL;
            lastSelectEventCount = count;
        }
        if (selectStmt) {
            sqlite3_reset(selectStmt);
        } else {
            NSString *sql = [NSString stringWithFormat:@"select id, event_name, event_time, event_data, session_id from events order by id asc limit %lu", (unsigned long)count];
            if (sqlite3_prepare_v2(db, sql.UTF8String, -1, &selectStmt, NULL) != SQLITE_OK) {
                NSLog(@"select events prepare failure: %s", sqlite3_errmsg(db));
                return;
            }
        }
        while (sqlite3_step(selectStmt) == SQLITE_ROW) {
            char *_eventName = (char *)sqlite3_column_text(selectStmt, 1);
            NSString *eventName = [NSString stringWithUTF8String:_eventName];
            
            char *_eventTime = (char *)sqlite3_column_text(selectStmt, 2);
            NSString *eventTime = [NSString stringWithUTF8String:_eventTime];
            
            NSError *error;
            NSData *eventData = [[NSData alloc] initWithBytes:sqlite3_column_blob(selectStmt, 3) length:sqlite3_column_bytes(selectStmt, 3)];
            NSDictionary *eventDataDict = [NSJSONSerialization JSONObjectWithData:eventData options:NSJSONReadingFragmentsAllowed error:&error];
            if (error) {
                NSLog(@"select events json parse failure: %@", error);
                return;
            }
            
            char *_sessionId = (char *)sqlite3_column_text(selectStmt, 4);
            NSString *sessionId = [NSString stringWithUTF8String:_sessionId];
            
            NSDictionary *event = @{
                @"event": eventName ?: @"",
                @"eventTime": eventTime ?: @"",
                @"sessionId": sessionId ?: @"",
                @"data": eventDataDict ?: @{}
            };
            [events addObject:event];
        }
    });
    return events;
}

- (BOOL)deleteEventsForCount:(NSUInteger)count {
    __block BOOL res = YES;
    
    dispatch_sync(self.eventsQueue, ^{
        NSString *sql = [NSString stringWithFormat:@"delete from events where id in (select id from events order by id asc limit %lu)", (unsigned long)count];
        char * errMsg;
        if (sqlite3_exec(db, sql.UTF8String, NULL, NULL, &errMsg) != SQLITE_OK) {
            res = NO;
            NSLog(@"delete events failure: %s", errMsg);
            return;
        }
    });
    
    if (res) {
        self.eventCount -= count;
        NSInteger resultCount = self.eventCount - count;
        self.eventCount = MAX(resultCount, 0);
    }
    
    return res;
}

- (void)queryLocalDatabaseEventCount {
    dispatch_async(self.eventsQueue, ^{
        NSString *sql = @"select count(*) from events";
        sqlite3_stmt *stmt;
        if (sqlite3_prepare_v2(db, sql.UTF8String, -1, &stmt, NULL) != SQLITE_OK) {
            NSLog(@"SQLite stmt prepare error: %s", sqlite3_errmsg(db));
            return;
        }
        while (sqlite3_step(stmt) == SQLITE_ROW) {
            self.eventCount = sqlite3_column_int(stmt, 0);
        }
    });
}

@end
