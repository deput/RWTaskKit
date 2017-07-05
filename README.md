# RWTaskKit

## Background
As we know, an UIApplication instance of an App calls delegate methods to notify developers implementing customizations. In these delegate methods, we can perform our tasks:

```objc
- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions {
    // do your massive stuff.....
    
    return YES;
}

```
For a sophisticated Application, this would be a disaster for developer to maintain. 

RWTaskKit is born to solve this issue! It helps programers to perform tasks seperately. Forget AppDelegate from now on!

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
`run`method will be invoked right after `application:willFinishLaunchingWithOptions:` is called by UIApplication.
This code piece could be in any `.m` file only with importing `RWTask.h`

You can see that each task consists of three parts: `task identifier with parameters` `task body` `end identifier`.


RWTaskKit supports three types of task:`event task` `schedule task` `notification task`

#### Event task

#### Schedule task

#### Notification task


#### Features 

#### To do


