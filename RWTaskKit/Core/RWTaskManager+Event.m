//
//  RWTaskManager+Event.m
//  RWTaskKit
//
//  Created by deput on 7/2/17.
//  Copyright © 2017 deput. All rights reserved.
//

#import "RWTaskManager+Internal.h"
#import <UIKit/UIKit.h>

const RWTaskEvent RWTaskEventStart = RWTaskEventWillFinishLaunching;
const RWTaskEvent RWTaskEventEnd = RWTaskEventReserved2;

NSString *const RWIdleNotificationKey = @"__RWIdleNotificationKey__";

static NSDictionary<NSString *, NSNumber *> *launchingDictionary = nil;
static CFMutableArrayRef eventTasks = NULL;

@implementation RWTaskManager (Event)

- (void)registerDelegateNotifications {
    // These notifications are sent out RWter the equivalent delegate message is called
    launchingDictionary = @{@"UIApplicationWillFinishLaunchingNotification" : @(RWTaskEventWillFinishLaunching),
                            UIApplicationDidFinishLaunchingNotification : @(RWTaskEventDidFinishLaunching),
                            UIApplicationWillEnterForegroundNotification : @(RWTaskEventWillEnterForeground),
                            UIApplicationDidEnterBackgroundNotification : @(RWTaskEventDidEnterBackground),
                            UIApplicationDidBecomeActiveNotification : @(RWTaskEventDidBecomeActive),
                            UIApplicationWillResignActiveNotification : @(RWTaskEventWillResignActive),
                            UIApplicationDidReceiveMemoryWarningNotification : @(RWTaskEventDidReceiveMemoryWarning),
                            UIApplicationWillTerminateNotification : @(RWTaskEventWillTerminate),
                            UIApplicationSignificantTimeChangeNotification : @(RWTaskEventSignificantTimeChange),
                            UIApplicationWillChangeStatusBarOrientationNotification : @(RWTaskEventWillChangeStatusBarOrientation),
                            UIApplicationDidChangeStatusBarOrientationNotification : @(RWTaskEventDidChangeStatusBarOrientation),
                            UIApplicationBackgroundRefreshStatusDidChangeNotification : @(RWTaskEventBackgroundRefreshStatusDidChange),
                            UIApplicationUserDidTakeScreenshotNotification : @(RWTaskEventUserDidTakeScreenshot),
                            @"UIApplicationOpenURLNotification":@(RWTaskEventOpenURL),
                            RWIdleNotificationKey:@(RWTaskEventIdle)
                            };
    [launchingDictionary.allKeys enumerateObjectsUsingBlock:^(NSString *_Nonnull notiKey, NSUInteger idx, BOOL *_Nonnull stop) {
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(handleLanchingNotifications:) name:notiKey object:nil];
    }];
}

- (void)handleLanchingNotifications:(NSNotification *)notification {
    RWTaskEvent e = [launchingDictionary[[notification name]] integerValue];
    if (e == RWTaskEventDidFinishLaunching || e == RWTaskEventWillFinishLaunching) {
        NSDictionary *launchOptions = [notification userInfo];
        [self updateContextWithLaunchOptions:launchOptions];
        [self runEventTasksByTaskTriggerEvent:e];
        [self updateContextWithLaunchOptions:nil];
    }else{
        [self.context.otherOptions addEntriesFromDictionary:notification.userInfo];
        [self runEventTasksByTaskTriggerEvent:e];
        [self.context.otherOptions removeObjectsForKeys:notification.userInfo.allKeys];
    }
}

- (void)initEventTasks {
    [self generateEventTasks];
    [self resortTasksByDependency];
}

- (void)generateEventTasks {
    NSArray<Class>* classes = (__bridge_transfer NSMutableArray*)eventTasks;
    _groupedTasksByEvent = [@{} mutableCopy];
    for (RWTaskEvent e = RWTaskEventStart; e <= RWTaskEventEnd; e = e << 1) {
        _groupedTasksByEvent[@(e)] = [@[] mutableCopy];
    }
    
    [classes enumerateObjectsUsingBlock:^(Class  _Nonnull cls, NSUInteger idx, BOOL * _Nonnull stop) {
        for (RWTaskEvent e = RWTaskEventStart; e <= RWTaskEventEnd; e = e << 1) {
            if (e & [cls triggerEvent]) {
                [_groupedTasksByEvent[@(e)] addObject:cls];
            }
        }
    }];
}

- (void)resortTasksByDependency {
    for (RWTaskEvent e = RWTaskEventStart; e <= RWTaskEventEnd; e = e << 1) {
        [self sortTasksByEvent:e];
    }
}

- (void)sortTasksByEvent:(RWTaskEvent)e {
    NSMutableArray<Class> *tasks = _groupedTasksByEvent[@(e)];
    NSMutableArray<Class> *taskWithOrder = [@[] mutableCopy];
    NSMutableSet *visited = [[NSMutableSet set] mutableCopy];
    while (taskWithOrder.count < tasks.count && tasks.count > 0) {
        NSInteger countBeforeLoop = taskWithOrder.count;
        [tasks enumerateObjectsUsingBlock:^(Class _Nonnull obj, NSUInteger idx, BOOL *_Nonnull stop) {
            if (![visited containsObject:obj]) {
                if ([[obj class] dependency] == nil) {
                    [taskWithOrder addObject:obj];
                    [visited addObject:obj];
                } else {
                    
                    __block BOOL clear = YES;
                    [[[obj class] dependency] enumerateObjectsUsingBlock:^(Class _Nonnull dependentCls, NSUInteger idx, BOOL *_Nonnull stop) {
                        
                        if (![visited containsObject:dependentCls] && [dependentCls triggerEvent] & e) {
                            clear = NO;
                            *stop = YES;
                        }
                    }];
                    
                    if (clear) {
                        [taskWithOrder addObject:obj];
                        [visited addObject:obj];
                    }
                }
            }
        }];
        
        if (countBeforeLoop == taskWithOrder.count) { // may have circular dependency!
            NSAssert(NO, @"might have circular dependency! please check your implementation!");
            break;
        }
    }
    [taskWithOrder sortUsingComparator:^NSComparisonResult(Class _Nonnull obj1, Class _Nonnull obj2) {
        if ([obj1 priority] < [obj2 priority]) {
            return NSOrderedAscending;
        } else if ([obj1 priority] > [obj2 priority]) {
            return NSOrderedDescending;
        } else {
            return NSOrderedSame;
        }
    }];
    _groupedTasksByEvent[@(e)] = taskWithOrder;
}

- (void)injectEventTaskWithName:(NSString *)taskName
                  andBlock:(RWTaskBlock)block
                  priority:(RWTaskPriority)p
              triggerEvent:(RWTaskEvent)event
                dependency:(NSArray<Class> *)dependency
                autoRemove:(BOOL)autoRemove {
    dispatch_async(dispatch_get_main_queue(), ^{
        if (NSClassFromString(taskName)) {
            
        } else {
            IMP runImp = imp_implementationWithBlock(^() {
                if (block) {
                    block(_context);
                }
                if (autoRemove) {
                    [self destroyTaskByName:taskName];
                }
            });
            IMP priorityImp = imp_implementationWithBlock(^RWTaskPriority() {
                return p;
            });
            IMP eventImp = imp_implementationWithBlock(^RWTaskEvent() {
                return event;
            });
            
            IMP depImp = imp_implementationWithBlock(^NSArray<Class> *() {
                return dependency;
            });
            
            @try {
                Class newClass = objc_allocateClassPair([RWEventTask class], [taskName UTF8String], 0);
                Class metaClass = object_getClass(newClass);
                
                BOOL ret = YES;
                Method runMthd = class_getClassMethod(newClass, @selector(run));
                const char *runtypes = method_getTypeEncoding(runMthd);
                ret = class_addMethod(metaClass, @selector(run), runImp, runtypes);
                
                Method priorityMthd = class_getClassMethod(newClass, @selector(priority));
                const char *prioritytypes = method_getTypeEncoding(priorityMthd);
                ret = class_addMethod(metaClass, @selector(priority), priorityImp, prioritytypes);
                
                
                Method eventMthd = class_getClassMethod(newClass, @selector(triggerEvent));
                const char *eventtypes = method_getTypeEncoding(eventMthd);
                ret = class_addMethod(metaClass, @selector(triggerEvent), eventImp, eventtypes);
                
                Method depMthd = class_getClassMethod(newClass, @selector(dependency));
                const char *deptypes = method_getTypeEncoding(depMthd);
                ret = class_addMethod(metaClass, @selector(dependency), depImp, deptypes);
                
                for (RWTaskEvent e = RWTaskEventStart; e <= RWTaskEventEnd; e = e << 1) {
                    if (event & e) {
                        [_groupedTasksByEvent[@(e)] addObject:newClass];
                        [self sortTasksByEvent:e];
                    }
                }
                objc_registerClassPair(newClass);
            }
            @catch (NSException *exception) {
                
            }
        }
    });
}
@end

void registerEventTask(Class taskClass)
{
    if (eventTasks == NULL) {
        eventTasks = CFArrayCreateMutable(kCFAllocatorDefault, 0, NULL);
    }
    if ([taskClass triggerEvent] != RWTaskEventNone) {
        CFArrayAppendValue(eventTasks, CFBridgingRetain(taskClass));
    }
}
