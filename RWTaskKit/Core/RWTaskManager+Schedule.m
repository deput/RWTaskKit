//
//  RWTaskManager+Schedule.m
//  RWTaskKit
//
//  Created by deput on 7/2/17.
//  Copyright © 2017 deput. All rights reserved.
//

#import "RWTaskManager+Internal.h"
#import "RWTaskObject.h"

NSString *const RWAppClockTicktockNotificationKey = @"RWAppClockTicktockNotificationKey";

static NSMutableArray<NSMutableArray *> *_groupedScheduleTasks = nil;
static NSMutableArray<Class> *_readyToFireTasks = nil;
static NSMutableDictionary<NSString *, NSNumber *> *_repeatedCount = nil;
static CFMutableArrayRef scheduledTasks = NULL;
const NSUInteger maxTimeIntervalCount = 120;
static NSUInteger _tick = 0;

#define RUN_SCHEDULE_TASK(task) \
if(![self isPausedForTask:task]){\
    [task run];\
    _repeatedCount[NSStringFromClass(task)] = @([_repeatedCount[NSStringFromClass(task)] integerValue] + 1);\
}

#define ADD_SCHEDULE_TASK(task) \
[_groupedScheduleTasks[(_tick + [task timeIntervalInSec]) % maxTimeIntervalCount] addObject:task];

@implementation RWTaskManager (Schedule)

- (void)initScheduledTasks {
    [self initVarsForSchedule];
    [self generateScheduledTasks];
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(tickTock:)
                                                 name:RWAppClockTicktockNotificationKey
                                               object:nil];
}

- (void)initVarsForSchedule {
    if (_groupedScheduleTasks == nil) {
        _groupedScheduleTasks = [@[] mutableCopy];
        
        for (NSUInteger i = 0; i < maxTimeIntervalCount; i++) {
            [_groupedScheduleTasks addObject:[@[] mutableCopy]];
        }
    }
    
    if (_readyToFireTasks == nil) {
        _readyToFireTasks = [@[] mutableCopy];
    }
    
    if (_repeatedCount == nil) {
        _repeatedCount = [@{} mutableCopy];
    }
}

- (void)generateScheduledTasks {
    NSArray<Class>* classes = (__bridge_transfer NSMutableArray*)scheduledTasks;
   
    [classes enumerateObjectsUsingBlock:^(Class cls, NSUInteger idx, BOOL *_Nonnull stop) {
        if ([cls scheduledDateTimeInterval] == 0.f) {
            [_groupedScheduleTasks[([cls timeIntervalInSec] + _tick) % maxTimeIntervalCount] addObject:cls];
        } else {
            [_readyToFireTasks addObject:cls];
        }
    }];
    
    [_readyToFireTasks sortUsingComparator:^NSComparisonResult(Class _Nonnull clz1, Class _Nonnull clz2) {
        return [clz1 scheduledDateTimeInterval] < [clz2 scheduledDateTimeInterval];
    }];
    
}

- (void)tickTock:(NSNotification *)notification {
    dispatch_async(dispatch_get_main_queue(), ^{
        _tick++;
        
        NSMutableArray<Class> *tasksToRun = _groupedScheduleTasks[_tick % maxTimeIntervalCount];
        [tasksToRun enumerateObjectsUsingBlock:^(Class taskClz, NSUInteger idx, BOOL *stop) {
            RUN_SCHEDULE_TASK(taskClz);
        }];
        
        [tasksToRun enumerateObjectsUsingBlock:^(Class _Nonnull taskClz, NSUInteger idx, BOOL *_Nonnull stop) {
            if ([_repeatedCount[NSStringFromClass(taskClz)] integerValue] < [taskClz repeatCount] || [taskClz repeatCount] == RWScheduleTaskRepeatForever) {
                [_groupedScheduleTasks[(_tick + [taskClz timeIntervalInSec]) % maxTimeIntervalCount] addObject:taskClz];
            } else {
                [_repeatedCount removeObjectForKey:NSStringFromClass(taskClz)];
            }
        }];
        
        [tasksToRun removeAllObjects];
        
        NSTimeInterval currentTime = [[NSDate date] timeIntervalSince1970];
        NSMutableArray<Class> *fireNowTasks = [@[] mutableCopy];
        
        [_readyToFireTasks enumerateObjectsUsingBlock:^(Class _Nonnull clz, NSUInteger idx, BOOL *_Nonnull stop) {
            NSTimeInterval time = [clz scheduledDateTimeInterval];
            if (time <= currentTime && time > currentTime - 5) {
                [fireNowTasks addObject:clz];
            }
        }];
        
        [_readyToFireTasks removeObjectsInArray:fireNowTasks];
        
        [fireNowTasks enumerateObjectsUsingBlock:^(Class _Nonnull clz, NSUInteger idx, BOOL *_Nonnull stop) {
            RUN_SCHEDULE_TASK(clz);
            if ([clz repeatCount] > 1) {
                ADD_SCHEDULE_TASK(clz);
            }
        }];
    });
}

- (void)scheduleTaskWithName:(NSString *)taskName
                    andBlock:(RWTaskBlock)block
                 desiredDate:(NSDate *)date
                 repeatCount:(NSInteger)count
                timeInterval:(NSUInteger)timeInterval {
    dispatch_async(dispatch_get_main_queue(), ^{
        if (NSClassFromString(taskName)) {
            //ADD_SCHEDULE_TASK(NSClassFromString(taskName));
        } else {
            IMP runImp = imp_implementationWithBlock(^() {
                if (block) {
                    block(_context);
                }
            });
            
            IMP dateImp = imp_implementationWithBlock(^NSTimeInterval() {
                return [date timeIntervalSince1970];
            });
            
            IMP countImp = imp_implementationWithBlock(^NSInteger() {
                return count;
            });
            
            IMP timeImp = imp_implementationWithBlock(^NSUInteger() {
                return timeInterval;
            });
            
            @try {
                Class newClass = objc_allocateClassPair([RWScheduledTask class], [taskName UTF8String], 0);
                Class metaClass = object_getClass(newClass);
                
                BOOL ret = YES;
                Method runMthd = class_getClassMethod(newClass, @selector(run));
                const char *runtypes = method_getTypeEncoding(runMthd);
                ret = class_addMethod(metaClass, @selector(run), runImp, runtypes);
                
                Method dateMthd = class_getClassMethod(newClass, @selector(scheduledDateTimeInterval));
                const char *datetypes = method_getTypeEncoding(dateMthd);
                ret = class_addMethod(metaClass, @selector(scheduledDateTimeInterval), dateImp, datetypes);
                
                
                Method countMthd = class_getClassMethod(newClass, @selector(repeatCount));
                const char *counttypes = method_getTypeEncoding(countMthd);
                ret = class_addMethod(metaClass, @selector(repeatCount), countImp, counttypes);
                
                
                Method timeMthd = class_getClassMethod(newClass, @selector(timeIntervalInSec));
                const char *timetypes = method_getTypeEncoding(timeMthd);
                ret = class_addMethod(metaClass, @selector(timeIntervalInSec), timeImp, timetypes);
                
                if ([newClass scheduledDateTimeInterval] == 0.f) {
                    ADD_SCHEDULE_TASK(newClass);
                } else {
                    [_readyToFireTasks addObject:newClass];
                }
                
                objc_registerClassPair(newClass);
                
            }
            @catch (NSException *exception) {
                
            }
        }
    });
}

- (void)internalDestroyScheduledTask:(Class)task {
    if (task) {
        [_readyToFireTasks removeObjectIdenticalTo:task];
        
        for (NSUInteger tick = _tick; tick < _tick + [task timeIntervalInSec] + 1; tick++) {
            [_groupedScheduleTasks[tick % maxTimeIntervalCount] removeObjectIdenticalTo:task];
        }
    }
}

- (void)timerTickTock {
    NSNotificationCenter *defaultCenter = [NSNotificationCenter defaultCenter];
    [defaultCenter postNotificationName:RWAppClockTicktockNotificationKey
                                 object:nil
                               userInfo:nil];
}

@end

@task(RWInitInternalTimerForScheduleTask, RWTaskPriorityCritical, RWTaskEventDidFinishLaunching)

+ (void)run {
    if (NSClassFromString(@"NOInternalClockPlaceHolderClass") != nil){
        return;
    }
    
    NSTimeInterval timeInterval = 1.0;
    NSTimer *_internalTimer = [NSTimer scheduledTimerWithTimeInterval:timeInterval
                                                               target:[RWTaskManager sharedInstance]
                                                             selector:@selector(timerTickTock)
                                                             userInfo:nil
                                                              repeats:YES];
    [[NSRunLoop currentRunLoop] addTimer:_internalTimer forMode:NSRunLoopCommonModes];
    [_internalTimer fire];
}

@end


void registerScheduledTask(Class taskClass)
{
    if (scheduledTasks == NULL) {
        scheduledTasks = CFArrayCreateMutable(kCFAllocatorDefault, 0, NULL);
    }
    CFArrayAppendValue(scheduledTasks, CFBridgingRetain(taskClass));
}
