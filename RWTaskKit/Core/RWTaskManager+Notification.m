//
//  RWTaskManager+Notification.m
//  RWTaskKit
//
//  Created by deput on 7/2/17.
//  Copyright © 2017 deput. All rights reserved.
//

#import "RWTaskManager+Internal.h"
#import "RWTaskObject.h"

static CFMutableArrayRef notficationTasks = NULL;

@implementation RWTaskManager (Notification)

- (void)initNotificationTasks {
    NSArray<NSArray*>* array = (__bridge_transfer NSMutableArray*)notficationTasks;
    RW_RUN_ONCE_WITH_TOKEN_BEGIN
        self.groupedTasksByNotification = @{}.mutableCopy;
    RW_RUN_ONCE_WITH_TOKEN_END
    [array enumerateObjectsUsingBlock:^(NSArray * _Nonnull pair, NSUInteger idx, BOOL * _Nonnull stop) {
        if (self.groupedTasksByNotification[pair[0]] == nil) {
            self.groupedTasksByNotification[pair[0]] = @[].mutableCopy;
            [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(handleCustomNotification:) name:pair[0] object:nil];
        }
        [self.groupedTasksByNotification[pair[0]] addObject:pair[1]];
    }];
}

- (void)handleCustomNotification:(NSNotification *)notification {
    [self.groupedTasksByNotification[[notification name]] enumerateObjectsUsingBlock:^(Class cls, NSUInteger idx, BOOL *stop) {
#ifdef DEBUG
        CFAbsoluteTime begin = CFAbsoluteTimeGetCurrent();
        [cls runWithNotification:notification];
        CFAbsoluteTime interval = CFAbsoluteTimeGetCurrent() - begin;
        self.performanceLog[NSStringFromClass(cls)] = @(interval);
#else
        [cls runWithNotification:notification];
#endif
    }];
}
@end


void registerNotificationTask(Class taskClass, NSString* notificationKey)
{
    if (notficationTasks == NULL) {
        notficationTasks = CFArrayCreateMutable(kCFAllocatorDefault, 0, NULL);
    }

    CFArrayAppendValue(notficationTasks, CFBridgingRetain(@[notificationKey,taskClass]));
}
