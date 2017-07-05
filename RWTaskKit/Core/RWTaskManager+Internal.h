//
//  RWTaskManager+Internal.h
//  RWTaskKit
//
//  Created by deput on 7/2/17.
//  Copyright © 2017 deput. All rights reserved.
//

#import "RWTaskManager.h"

#define RW_RUN_ONCE_WITH_TOKEN_BEGIN \
{\
static dispatch_once_t onceToken;\
dispatch_once(&onceToken,^{\

#define RW_RUN_ONCE_WITH_TOKEN_END \
});\
}

NSArray<NSString *>*ReadConfigurationsFromSection(const char *sectionName);

@interface RWTaskManager () {
    NSMutableDictionary<id, NSMutableArray<Class> *> *_groupedTasksByEvent;
    RWTaskContext *_context;
}

- (BOOL)isPausedForTask:(Class)taskCls;

@property(nonatomic, retain) NSMutableDictionary<NSString *, NSMutableArray<Class> *> *groupedTasksByNotification;

#ifdef DEBUG
@property(nonatomic, retain) NSMutableDictionary *performanceLog;

- (void)logTimeConsuming;
#endif


@end


@interface RWTaskManager (Event)
- (void)initEventTasks;
@end

@interface RWTaskManager (Internal)
- (void)initScheduledTasks;

- (void)internalDestroyScheduledTask:(Class)task;
@end

@interface RWTaskManager (NotificationHandler)
- (void)registerDelegateNotifications;
@end

@interface RWTaskManager (NotificationTask)
- (void)initNotificationTasks;

@end
