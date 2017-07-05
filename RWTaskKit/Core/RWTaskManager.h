//
//  RWTaskManager.h
//  RWTaskKit
//
//  Created by deput on 6/21/17.
//  Copyright © 2017 deput. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "RWTaskObject.h"
#import "RWSingletonMacro.h"

@class UIApplication;
@class RWTaskContext;

typedef void (^RWTaskBlock )(RWTaskContext *context);

#pragma mark - RWTask Clock Ticktock Notification Key
extern NSString *const RWAppClockTicktockNotificationKey;


#pragma mark -
void registerEventTask(Class taskClass);
void registerScheduledTask(Class taskClass);
void registerNotificationTask(Class taskClass, NSString* notificationKey);

void withContext(RWTaskBlock block);

//#define ContainsString(s,other) ([s rangeOfString:other].length != 0)

#define RWTaskSectionDATA(sectionName) __attribute((used, section("__DATA,"#sectionName" ")))

#pragma mark - Interface macros

#define task(Task, TaskPriority, TaskTriggerEvent) \
interface Task: RWEventTask @end\
@implementation Task\
+ (void) load{\
    registerEventTask(self);\
}\
+ (RWTaskPriority) priority\
{\
    return TaskPriority;\
}\
\
+ (RWTaskEvent) triggerEvent\
{\
    return TaskTriggerEvent;\
}

#define task_name(task) NSClassFromString(@#task)?:NSClassFromString(@"RWNopTask")

#pragma mark - Internal macros


#define RWTaskManagerOn __attribute__((constructor)) static void task_manager_instance_create(void) {\
    [RWTaskManager sharedInstance];\
}

#define RW_DECLARE_NOTIFICATION(notification) \
FOUNDATION_EXTERN NSString* const notification;

#define RW_SYNTHESIZE_NOTIFICATION(notification)\
NSString* const notification = @#notification;

@interface RWTaskManager : NSObject
RW_DECLARE_SINGLETON_FOR_CLASS(RWTaskManager)

#pragma mark - Execute task methods

- (void)runEventTasksByTaskTriggerEvent:(RWTaskEvent)triggerEvent;

#pragma mark - Runtime tasks(event tasks) injection methods

- (void)injectEventTaskWithName:(NSString *)taskName
                  andBlock:(RWTaskBlock)block
                  priority:(RWTaskPriority)p
              triggerEvent:(RWTaskEvent)e
                dependency:(NSArray<Class> *)dependency
                autoRemove:(BOOL)autoRemove;

- (void)destroyTaskByName:(NSString *)taskName;

- (void)pauseTaskByName:(NSString *)taskName;

- (void)resumeTaskByName:(NSString *)taskName;

#pragma mark - RWTaskManager context related utility methods

- (void)updateContextWithLaunchOptions:(NSDictionary *)launchOptions;

- (RWTaskContext *)context;

@end

#pragma mark - Schedule task

#define RWScheduleTaskRepeatForever -1

#define schedule(Task, Date, RepeatCount, TimeInterval) \
interface Task: RWScheduledTask @end\
@implementation Task\
+ (void) load{\
    registerScheduledTask(self);\
}\
+ (NSUInteger) timeIntervalInSec\
{\
    return TimeInterval;\
}\
+ (NSInteger) repeatCount\
{\
    return RepeatCount;\
}\
+ (NSTimeInterval) scheduledDateTimeInterval\
{\
    return Date;\
}

#define timer(Task, RepeatCount, TimeInterval) schedule(Task,0.f,RepeatCount,TimeInterval)

@interface RWTaskManager (Schedule)

- (void)scheduleTaskWithName:(NSString *)taskName
                    andBlock:(RWTaskBlock)block
                 desiredDate:(NSDate *)date
                 repeatCount:(NSInteger)count
                timeInterval:(NSUInteger)timeInterval;
@end


#define notification(Task, TaskPriority, NotificationKey) \
interface Task: RWNotificationTask @end\
@implementation Task\
+ (void) load{\
    registerNotificationTask(self,NotificationKey);\
}\
+ (RWTaskPriority) priority\
{\
    return TaskPriority;\
}\
+ (RWTaskEvent) triggerEvent\
{\
    return RWTaskEvent_Custom;\
}\
+ (NSString*) notificationKey\
{\
    return NotificationKey;\
}

#pragma mark - RWTaskContext

@interface RWTaskContext : NSObject

- (UIApplication *)application;

- (NSDictionary *)launchOptions;

- (id)objectForKeyedSubscript:(id)key;

- (void)setObject:(id)object forKeyedSubscript:(id <NSCopying>)key;

- (NSMutableDictionary *)otherOptions;

@end

