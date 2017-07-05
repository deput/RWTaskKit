# RWTaskKit

## Background
As we know, the instance of UIApplication in an iOS App calls delegate methods to notify developers implemnting customizations. 



## Perform task neatly!

## Quick examle
Here is an examle for a task defined in m file:

```objd
@task(Task1, RWTaskPriorityCritical, RWTaskEventWillFinishLaunching)
+(void) run {
    NSLog(@"This is No.1 task we want to perform!");
}
@end
```

### Event task


### Schedule task

### Notification task

