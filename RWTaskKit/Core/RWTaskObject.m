//
//  RWTaskObject.m
//  RWTaskKit
//
//  Created by deput on 6/21/17.
//  Copyright © 2017 deput. All rights reserved.
//

#import "RWTaskObject.h"

#pragma mark - RWTaskObject

@implementation RWTaskObject

+ (void)run {
    //do nothing
}
@end

@implementation RWNopTask

+ (RWTaskPriority)priority {
    return RWTaskPriorityDefault;
}

@end

@implementation RWEventTask

+ (NSArray<Class> *)dependency {
    return nil;
}

+ (RWTaskPriority)priority {
    return RWTaskPriorityDefault;
}

+ (RWTaskEvent)triggerEvent {
    return RWTaskEventNone;
}

@end

@implementation RWScheduledTask

+ (NSUInteger)timeIntervalInSec {
    return 0;
}

+ (NSInteger)repeatCount {
    return 1;
}

+ (NSTimeInterval)scheduledDateTimeInterval {
    return 0.f;
}

@end

@implementation RWNotificationTask
+ (void)runWithNotification:(NSNotification *)notification {
    
}

+ (NSString*) notificationKey{
    return @"";
}
@end
