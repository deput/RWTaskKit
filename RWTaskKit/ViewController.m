//
//  ViewController.m
//  RWTaskKit
//
//  Created by deput on 6/21/17.
//  Copyright © 2017 deput. All rights reserved.
//

#import "ViewController.h"
#import "RWTask.h"

@interface ViewController ()

@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view, typically from a nib.
}


- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}


@end

//@timer(TestTimer1, RWScheduleTaskRepeatForever, 1)
//+ (void) run
//{
//    static int counter = 1;
//    NSLog(@"%@:%d",@"Say Hi from TestTimer1",counter++);
//}
//@end
//
//@timer(TestTimer2, 5, 2)
//+ (void) run
//{
//    static int counter = 1;
//    NSLog(@"%@:%d",@"Say Hi from TestTimer2",counter++);
//}
//@end

@task(Task1, RWTaskPriorityCritical, RWTaskEventWillFinishLaunching)
+(void) run {
    NSLog(@"This is No.1 task we want to perform!");
    
    withContext(^(RWTaskContext *context) {
        UIApplication* application = [context application];
        NSDictionary* dict = [context launchOptions];
        [[context otherOptions] setObject:@1 forKey:@"key"];
    });
}
@end

@task(Task2, RWTaskPriorityHigh, RWTaskEventWillFinishLaunching)
+(void) run {
    NSLog(@"This is No.2 task we want to perform!");
}

+ (NSArray<Class>*) dependency
{
    return @[task_name(AFTask3),task_name(AFTask4)];
}
@end

@task(Task3, RWTaskPriorityHigh, RWTaskEventDidFinishLaunching)
+(void) run {
    NSLog(@"This is No.3 task we want to perform! it depends on No.4 task");
}

+ (NSArray<Class>*) dependency
{
    return @[task_name(Task4)];
}

@end

@task(Task4, RWTaskPriorityHigh, RWTaskEventDidFinishLaunching)
+(void) run {
    NSLog(@"This is No.4 task we want to perform!");
}
@end

