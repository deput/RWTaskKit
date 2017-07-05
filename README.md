# RWTaskKit

## Background
As we know, the instance of UIApplication in an iOS App calls delegate methods to notify developers implementing customizations: 

```objc
- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions {
    // do your massive stuff.....
    
    return YES;
}

```
For a sophisticated Application, this would be a disaster for developer to maintain. 

RWTaskKit is born to solve this issue! It helps programers to perform tasks seperately.


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

#### Event task

#### Schedule task

#### Notification task


#### Features 

#### To do


