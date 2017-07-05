//
//  RWTask.h
//  RWTaskKit
//
//  Created by deput on 6/21/17.
//  Copyright © 2017 deput. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "RWTaskManager.h"
#import "RWTaskObject.h"

#define RWTaskAutomatic 1

#if RWTaskAutomatic
RWTaskManagerOn
#endif

#define NO_RW_CLOCK \
@interface NOInternalClockPlaceHolderClass : NSObject @end\
@implementation NOInternalClockPlaceHolderClass @end


//Samples
/*
 ## Task triggered by event
 
 ### Staitc task
 ```
 @task(Task1, RWTaskPriorityCritical, AFTaskEvent_DidFinishLaunching)
 +(void) run {
    NSLog(@"This is No.1 task we want to perform!");
 withContext(^(AFTaskContext *context) {
 UIApplication* application = [context application];
 NSDictionary* dict = [context launchOptions];
 [[context otherOptions] setObject:value forKey:key];
 });
 }
 @end
 
 @task(AFTask2, AFTaskPriority_High, AFTaskEvent_DidFinishLaunching)
 +(void) run {
 NSLog(@"This is No.2 task we want to perform!");
 }
 
 + (NSArray<Class>*) dependency
 {
 return @[task_name(AFTask3),task_name(AFTask4)];
 }
 @end
 
 @task(AFTask3, AFTaskPriority_High, AFTaskEvent_DidFinishLaunching)
 +(void) run {
 NSLog(@"This is No.3 task we want to perform!");
 }
 
 @end
 
 @task(AFTask4, AFTaskPriority_High, AFTaskEvent_DidFinishLaunching)
 +(void) run {
 NSLog(@"This is No.4 task we want to perform!");
 }
 ```
 
 ###runtime injection
 ```
 [[AFTaskManager sharedInstance] injectTaskWithName:@"Hello" andBlock:^(AFTaskContext *context) {
 NSLog(@"yoyo check now");
 } priority:AFTaskPriority_Default triggerEvent:AFTaskEvent_WillEnterForeground dependency:@[task_name(AFTaskEnterForeground)]];
 ```
 
 ## Task triggered by timer or schedule
 ```
 @schedule(Try1, 1448873913.33f, 5, 1)
 
 + (void) run
 {
 NSLog(@"hello");
 }
 @end
 
 @timer(Try2, AFSchduleTaskRepeatForever, 2)
 
 + (void) run
 {
 NSLog(@"hello forever");
 }
 @end
 ```
 
 ### runtime injection
 ```
 [[AFTaskManager sharedInstance] scheduleTaskWithName:@"Hey" andBlock:^(AFTaskContext *context) {
 NSLog(@"hello: this is scheduled!");
 } desiredDate:[NSDate dateWithTimeIntervalSinceNow:5] repeatCount:2 timeInterval:2];
 ```
 */




