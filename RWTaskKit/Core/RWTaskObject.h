//
//  RWTaskObject.h
//  RWTaskKit
//
//  Created by deput on 6/21/17.
//  Copyright © 2017 deput. All rights reserved.
//

#import <Foundation/Foundation.h>
#pragma mark - Types

typedef NS_ENUM(NSUInteger, RWTaskPriority) {
    RWTaskPriorityCritical = 0,
    RWTaskPriorityHigh,
    RWTaskPriorityDefault,
    RWTaskPriorityLow,
};

typedef NS_ENUM(NSUInteger, RWTaskEvent) {
    RWTaskEventWillFinishLaunching = 0x1,
    RWTaskEventDidFinishLaunching = 0x1 << 1,
    RWTaskEventWillEnterForeground = 0x1 << 2,
    RWTaskEventDidEnterBackground = 0x1 << 3,
    RWTaskEventDidBecomeActive = 0x1 << 4,
    RWTaskEventDidReceiveMemoryWarning = 0x1 << 5,
    RWTaskEventWillTerminate = 0x1 << 6,
    RWTaskEventWillResignActive = 0x1 << 7,
    RWTaskEventSignificantTimeChange = 0x1 << 8,
    RWTaskEventOpenURL = 0x1 << 9,
    RWTaskEventWillChangeStatusBarOrientation = 0x1 << 10,
    RWTaskEventDidChangeStatusBarOrientation = 0x1 << 11,
    RWTaskEventBackgroundRefreshStatusDidChange = 0x1 << 12,
    RWTaskEventUserDidTakeScreenshot = 0x1 << 13,
    RWTaskEventReserved1 = 0x1 << 14,
    RWTaskEventReserved2 = 0x1 << 15,
    RWTaskEventIdle = 0x1 << 16, // not implemented
    RWTaskEventNone = 0,
};

@interface RWTaskObject : NSObject
+ (void)run;
@end

@interface RWEventTask : RWTaskObject
+ (NSArray<Class> *)dependency;

+ (RWTaskPriority)priority;

+ (RWTaskEvent)triggerEvent;
@end

@interface RWScheduledTask : RWTaskObject
+ (NSUInteger)timeIntervalInSec;

+ (NSInteger)repeatCount;

+ (NSTimeInterval)scheduledDateTimeInterval;
@end

@interface RWNotificationTask : RWTaskObject
+ (void)runWithNotification:(NSNotification *)notification;

+ (NSString*) notificationKey;
@end

@interface RWNopTask : RWEventTask

@end
