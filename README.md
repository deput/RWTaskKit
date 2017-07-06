# RWTaskKit

## Background
As we know, an UIApplication instance of an App calls delegate methods to notify developers implementing customizations. In these delegate methods, we can perform our tasks:

```objc
- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions {
    // do your massive stuff.....
    
    return YES;
}

```

For a sophisticated application, this would be a disaster for developer to maintain. 

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
method `run` will be invoked right after `application:willFinishLaunchingWithOptions:` is called by UIApplication.
This code snippet could be in any `.m` file only with importing `RWTask.h`

You can see that each task consists of three parts: `task identifier with parameters` `task body` `task end identifier`.
- `task identifier with parameters`

1. start with `@` character just like annotation in Java
2. followed by a keyword identifing type of task
3. followed by a set of parameters 

- `task body`

consists of one or two objective-c class method. 

- `task end identifier`

just an `end`

RWTaskKit supports three types of task:`event task` `schedule task` `notification task`

#### Event task
`Event task` is designed to handle common methods calling in UIApplicationDelegate. 

#### Schedule task

#### Notification task


#### Features 

#### To do


