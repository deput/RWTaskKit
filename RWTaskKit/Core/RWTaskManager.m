//
//  RWTaskManager.m
//  RWTaskKit
//
//  Created by deput on 6/21/17.
//  Copyright © 2017 deput. All rights reserved.
//

#import "RWTaskManager.h"
#import "RWTaskObject.h"
#import "RWTaskManager+Internal.h"
#import <UIKit/UIKit.h>

@implementation RWTaskContext {
    NSDictionary *_launchOptions;
    NSMutableDictionary *_otherOptions;
}

- (UIApplication *)application {
    return [UIApplication sharedApplication];
}

- (void)internalSetLaunchOptions:(NSDictionary *)launchOptions {
    _launchOptions = launchOptions;
}

- (NSDictionary *)launchOptions {
    return _launchOptions;
}

- (NSMutableDictionary *)otherOptions {
    return _otherOptions;
}

- (id)objectForKeyedSubscript:(id)key {
    return _otherOptions[key];
}

- (void)setObject:(id)object forKeyedSubscript:(id <NSCopying>)key {
    if (key) {
        _otherOptions[key] = object;
    }
}

- (instancetype)init {
    self = [super init];
    _otherOptions = [@{} mutableCopy];
    return self;
}

@end

@implementation RWTaskManager
{
    NSMutableSet<Class> *_pausedTasks;
}

RW_SYNTHESIZE_SINGLETON_FOR_CLASS(RWTaskManager)

- (instancetype)init {
    self = [super init];
    [self initVars];
    
    [self initEventTasks];
    [self initScheduledTasks];
    [self initNotificationTasks];
    
    [self registerDelegateNotifications];
    
    return self;
}

- (void)updateContextWithLaunchOptions:(NSDictionary *)launchOptions {
    [_context internalSetLaunchOptions:launchOptions];
}

- (RWTaskContext *)context {
    return _context;
}

- (void)runEventTasksByTaskTriggerEvent:(RWTaskEvent)triggerEvent {
    
    void (^blk)()  = ^(){
        if (triggerEvent & RWTaskEventDidFinishLaunching) {
            RW_RUN_ONCE_WITH_TOKEN_BEGIN
            [self internalRunTasksByTaskTriggerEvent:triggerEvent];
            RW_RUN_ONCE_WITH_TOKEN_END
        }else if (triggerEvent & RWTaskEventWillFinishLaunching){
            RW_RUN_ONCE_WITH_TOKEN_BEGIN
            [self internalRunTasksByTaskTriggerEvent:triggerEvent];
            RW_RUN_ONCE_WITH_TOKEN_END
        }
        else {
            [self internalRunTasksByTaskTriggerEvent:triggerEvent];
        }
    };
    
    if ([NSThread isMainThread]) {
        blk();
    }else{
        dispatch_async(dispatch_get_main_queue(), blk);
    }
}

- (void)destroyTaskByName:(NSString *)taskName {
    dispatch_async(dispatch_get_main_queue(), ^{
        Class cls = NSClassFromString(taskName);
        if (cls) {
            if ([cls superclass] == [RWScheduledTask class]) {
                [self internalDestroyScheduledTask:cls];
            } else {
                [_groupedTasksByEvent.allValues enumerateObjectsUsingBlock:^(NSMutableArray<Class> *_Nonnull tasks, NSUInteger idx, BOOL *_Nonnull stop) {
                    [tasks removeObjectIdenticalTo:NSClassFromString(taskName)];
                }];
                objc_disposeClassPair(NSClassFromString(taskName));
            }
        }
    });
}

- (void)pauseTaskByName:(NSString *)taskName {
    dispatch_async(dispatch_get_main_queue(), ^{
        if (NSClassFromString(taskName)) {
            [_pausedTasks addObject:NSClassFromString(taskName)];
        }
    });
}

- (void)resumeTaskByName:(NSString *)taskName {
    dispatch_async(dispatch_get_main_queue(), ^{
        if (NSClassFromString(taskName)) {
            [_pausedTasks removeObject:NSClassFromString(taskName)];
        }
    });
}

#pragma mark - Internal methods

- (void)internalRunTasksByTaskTriggerEvent:(RWTaskEvent)triggerEvent {
    [_groupedTasksByEvent[@(triggerEvent)] enumerateObjectsUsingBlock:^(Class clz, NSUInteger idx, BOOL *_Nonnull stop) {
        if (![_pausedTasks containsObject:clz]) {
#ifdef DEBUG
            CFAbsoluteTime begin = CFAbsoluteTimeGetCurrent();
            [clz run];
            CFAbsoluteTime interval = CFAbsoluteTimeGetCurrent() - begin;
            if (NSStringFromClass(clz)) {
                self.performanceLog[NSStringFromClass(clz)] = @(interval);
            }
#else
            [clz run];
#endif
        }
    }];
}



- (BOOL)isOfficialCall {
    return YES;
}

- (BOOL)isPausedForTask:(Class)taskCls {
    return [_pausedTasks containsObject:taskCls];
}

- (void)logTimeConsuming {
#ifdef DEBUG
    NSLog(@"%@", self.performanceLog);
#endif
}

- (void)initVars {
    _context = [RWTaskContext new];
    _pausedTasks = [NSMutableSet set];
#ifdef DEBUG
    self.performanceLog = @{}.mutableCopy;
#endif
}

@end

#pragma mark - Utils

void withContext(RWTaskBlock block) {
    if (block) {
        block([[RWTaskManager sharedInstance] context]);
    }
}



#include <mach-o/getsect.h>
#include <mach-o/loader.h>
#include <mach-o/dyld.h>
#include <dlfcn.h>
#import <objc/runtime.h>
#import <objc/message.h>

NSArray<NSString *>*ReadConfigurationsFromSection(const char *sectionName){
    
    NSMutableArray *configs = [NSMutableArray array];
    
    Dl_info info;
    dladdr(ReadConfigurationsFromSection, &info);
    
#ifndef __LP64__
    const struct mach_header *mhp = (struct mach_header*)info.dli_fbase;
    unsigned long size = 0;
    uint32_t *memory = (uint32_t*)getsectiondata(mhp, "__DATA", sectionName, & size);
#else /* defined(__LP64__) */
    const struct mach_header_64 *mhp = (struct mach_header_64*)info.dli_fbase;
    unsigned long size = 0;
    uint64_t *memory = (uint64_t*)getsectiondata(mhp, "__DATA", sectionName, & size);
#endif /* defined(__LP64__) */
    
    for(int idx = 0; idx < size/sizeof(void*); ++idx){
        char *string = (char*)memory[idx];
        
        NSString *str = [NSString stringWithUTF8String:string];
        if(!str)continue;
        
        //NSLog(@"config = %@", str);
        if(str) [configs addObject:str];
    }
    
    return configs;
}

NSArray<NSString*>* read_config(const char* sectName, const struct mach_header *mhp)
{
    NSMutableArray* configs = @[].mutableCopy;
    
    unsigned long size = 0;
#ifndef __LP64__
    uintptr_t *memory = (uintptr_t*)getsectiondata(mhp, SEG_DATA, sectName,&size);
#else 
    const struct mach_header_64 *mhp64 = (const struct mach_header_64*)mhp;
    uintptr_t *memory = (uintptr_t*)getsectiondata(mhp64, SEG_DATA, sectName,&size);
#endif
    
    unsigned long c = size / sizeof(void*);
    for (int idx = 0; idx < c; ++idx) {
        char* s = (char*)memory[idx];
        NSString* string = [NSString stringWithUTF8String:s];
        if (!string) {
            continue;
        }else{
            [configs addObject:string];
        }
    }
    return configs;
}
