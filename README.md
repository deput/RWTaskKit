# RWTaskKit

## Background
As we know, a UIApplication instance of an App calls delegate methods to notify developers implementing customizations. In these delegate methods, we can perform our tasks:

```objc
- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions {
    // do your massive stuff.....
    
    return YES;
}
```

For a sophisticated application, this would be a disaster for a developer to maintain. 

RWTaskKit is born to solve this issue! It helps programmers to perform tasks separately. Forget AppDelegate from now on!

## Perform task neatly!

### Quick examle
Here is an examle for a task defined in a `.m` file:

```objc
@task(Task1, RWTaskPriorityCritical, RWTaskEventWillFinishLaunching)
+(void) run {
    NSLog(@"This is No.1 task we want to perform!");
}
@end
```
method `run` will be invoked right after `application:willFinishLaunchingWithOptions:` is called by UIApplication.
This code snippet could be in any `.m` file only with importing `RWTask.h`

You can see that each task consists of three parts: `task identifier with parameters` `task body` `task end identifier`.
- `task identifier with parameters`

1. start with `@` character just like annotation in Java
2. followed by a keyword identifying type of task
3. followed by a set of parameters 

- `task body`

  consists of one or two objective-c class method. 

- `task end identifier`

  just an `end`

RWTaskKit supports three types of task:`event task` `schedule task` `notification task`

#### Event task
Event task is designed to handle common methods calling in UIApplicationDelegate. 

Parameters in the brackets are :`Task Name`, `Priority`, `Event Name`

`Task Nanme` would be any unique string.
`Priority` would be enumeration value witch can be found in `RWTaskObject.h`, task (for a same event) with higher priority will be exexuted earlier.

`Event Name` would be enumeration value as following：


```objc
typedef NS_ENUM(NSUInteger, RWTaskEvent) {
  RWTaskEventWillFinishLaunching = 0x1,       //tasks will be performed only once
  RWTaskEventDidFinishLaunching = 0x1 << 1,   //tasks will be performed only once
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
```
Above event enumerations are mapped to coresponding delegate methods. see `UIApplication.h` in iOS SDK.

class method `run` is a must-have for any task.  Besides `event task` has an optional method `+(NSArray<Class>*)dependency` which denotes the dependency of the task. See the following example:

```objc
@task(Task2, RWTaskPriorityCritical, RWTaskEventWillFinishLaunching)
+(void) run {
    NSLog(@"This is No.2 task we want to perform!");
}
+(NSArray<Class>*)dependency{
  	// this task will be executed after Task1 and Task3 finish
	return @[task_name(Task1),task_name(Task3)];    
}
@end
```

Here `task_name` is a macro for convenience. Tasks specified in method `dependency` have nothing to do with the order inside the array. 



#### Schedule task

Schedule task is designed for the task should be executed right after a scheduled time or repeated with specified times.

examples:

```objective-c
@schedule(ScheduleTask1, 1448873913, 5, 1)
+ (void) run{
  NSLog(@"hello");
}
@end
 
@timer(ScheduleTask2, 10, 2)
+ (void) run{
  NSLog(@"hello");
}
@end
```

`ScheduleTask1` will be executed right after `1448873913`(timestamp, like `[[NSDate date] timeIntervalSince1970]`), it will be executed `5` times for every `1` second.

`ScheduleTask2` will be executed every `2` seconds, and it will repeat `10` times.

Schedule task has a built-in clock, the time interval is 1 second. Thus the `timeinterval` in paramters should be an integral multiple of built-in time interval. Besides the maximum `timeinterval` is 120 * built-in time interval.

> Note: developers can customize the built-in time interval by trigger a repeatedly notification implused by your own `NSTimer`.
>
> First, use `NO_RW_CLOCK` macro only once in any `.m` file. Second, post a notification with name `RWAppClockTicktockNotificationKey` in your customized timer.

#### Notification task

Notification task is designed for task should be triggered by a notification. Example:

```objc
@notification(NotiTask,@"NotificationKey")
+ (void) runWithNotification:(NSNotification*)noti{
  NSLog(@"hello");
}
@end
```


#### Runtime injection
Following interfaces can be used in runtime scenario to inject `event` tasks and `schedule` tasks.

```objc
- (void)injectEventTaskWithName:(NSString *)taskName
                  andBlock:(RWTaskBlock)block
                  priority:(RWTaskPriority)p
              triggerEvent:(RWTaskEvent)e
                dependency:(NSArray<Class> *)dependency
                autoRemove:(BOOL)autoRemove;
		
- (void)scheduleTaskWithName:(NSString *)taskName
                    andBlock:(RWTaskBlock)block
                 desiredDate:(NSDate *)date
                 repeatCount:(NSInteger)count
                timeInterval:(NSUInteger)timeInterval;

- (void)destroyTaskByName:(NSString *)taskName;

- (void)pauseTaskByName:(NSString *)taskName;

- (void)resumeTaskByName:(NSString *)taskName;

```
