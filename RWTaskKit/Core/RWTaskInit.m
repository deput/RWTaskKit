//
//  RWTaskInit.m
//  RWTaskKit
//
//  Created by deput on 6/21/17.
//  Copyright © 2017 deput. All rights reserved.
//

#import "rwfishhook.h"
#import <objc/runtime.h>
#import <UIKit/UIKit.h>
#import <Foundation/Foundation.h>
#import "RWTask.h"

@implementation RWTaskManager (RWTaskInit)
@end

@class UIApplication;

int (*origUIApplicationMain)(int argc, char *argv[], NSString * __nullable principalClassName, NSString * __nullable delegateClassName);
int rwtaskUIApplicationMain(int argc, char *argv[], NSString * __nullable principalClassName, NSString * __nullable delegateClassName);

__unused __attribute__((constructor)) void _(){
    rw_rebind_symbols((struct rw_rebinding[1]){{"UIApplicationMain", rwtaskUIApplicationMain, (void *)&origUIApplicationMain}}, 1);
}

static Class delegateClass = nil;

BOOL (*origWillFinishLaunchingWithOptions)(id zelf,SEL cmd, UIApplication * application,NSDictionary *dictionary);
BOOL rwtaskWillFinishLaunchingWithOptions(id zelf,SEL cmd, UIApplication * application,NSDictionary *dictionary);

BOOL (*origOpenURL)(id zelf,SEL cmd, UIApplication * application, NSURL * url, NSDictionary *dictionary);
BOOL rwtaskOpenURL(id zelf,SEL cmd, UIApplication * application, NSURL * url, NSDictionary *dictionary);

BOOL (*origOpenURLiOS8)(id zelf,SEL cmd, UIApplication * application, NSURL * url, NSString* sourceApplication, id annotation);
BOOL rwtaskOpenURLiOS8(id zelf,SEL cmd, UIApplication * application, NSURL * url, NSString* sourceApplication, id annotation);

BOOL rwtaskReplaceApplictionDelegateMethod(Class delegateCls, SEL cmd, const char* types, IMP newImp, IMP* oriImp);

int rwtaskUIApplicationMain(int argc, char *argv[], NSString * __nullable principalClassName, NSString * __nullable delegateClassName)
{
    delegateClass = NSClassFromString(delegateClassName);
    if (delegateClassName) {
        rwtaskReplaceApplictionDelegateMethod(delegateClass,
                                              @selector(application:willFinishLaunchingWithOptions:),
                                              "B32@0:8@16@24",(IMP)&(rwtaskWillFinishLaunchingWithOptions),
                                              (IMP*)&origWillFinishLaunchingWithOptions);
        
        BOOL useOldMethod = [[[UIDevice currentDevice] systemVersion] floatValue] < 9.0 ||
        (class_getInstanceMethod(delegateClass,@selector(application:openURL:sourceApplication:annotation:)) != nil
         && class_getInstanceMethod(delegateClass,@selector(application:openURL:options:)) == nil);
        
        if (!useOldMethod) {
            rwtaskReplaceApplictionDelegateMethod(delegateClass,
                                                  @selector(application:openURL:options:),
                                                  "B40@0:8@16@24@32",(IMP)&(rwtaskOpenURL),
                                                  (IMP*)(&origOpenURL));
        }else{
            rwtaskReplaceApplictionDelegateMethod(delegateClass,
                                                  @selector(application:openURL:sourceApplication:annotation:),
                                                  "B48@0:8@16@24@32@40",(IMP)&(rwtaskOpenURLiOS8),
                                                  (IMP*)&origOpenURLiOS8);
        }
    }
    
    return origUIApplicationMain(argc,argv,principalClassName,delegateClassName);
}

BOOL rwtaskWillFinishLaunchingWithOptions(id zelf,SEL cmd, UIApplication * application,NSDictionary *dictionary)
{
    BOOL retValue = YES;
    if (origWillFinishLaunchingWithOptions != NULL) {
        retValue = origWillFinishLaunchingWithOptions(zelf,cmd,application,dictionary);
    }
    
    [[NSNotificationCenter defaultCenter] postNotificationName:@"UIApplicationWillFinishLaunchingNotification" object:nil userInfo:dictionary];
    return retValue;
}

BOOL rwtaskOpenURL(id zelf,SEL cmd, UIApplication * application, NSURL* url, NSDictionary *dictionary)
{
    BOOL retValue = YES;
    if (origOpenURL != NULL) {
        retValue = origOpenURL(zelf,cmd,application,url,dictionary);
    }
    
    NSMutableDictionary* tmpDict = dictionary.mutableCopy;
    tmpDict[@"openURL"] = url;
    [[NSNotificationCenter defaultCenter] postNotificationName:@"UIApplicationOpenURLNotification" object:nil userInfo:tmpDict];
    return retValue;
}

BOOL rwtaskOpenURLiOS8(id zelf,SEL cmd, UIApplication * application, NSURL * url, NSString* sourceApplication, id annotation)
{
    BOOL retValue = YES;
    if (origOpenURLiOS8 != NULL) {
        retValue = origOpenURLiOS8(zelf,cmd,application,url,sourceApplication,annotation);
    }
    
    [[NSNotificationCenter defaultCenter] postNotificationName:@"UIApplicationOpenURLNotification" object:nil userInfo:@{@"sourceApplication":sourceApplication,@"annotaion":annotation,@"openURL":url}];
    return retValue;
}

BOOL rwtaskReplaceApplictionDelegateMethod(Class delegateCls, SEL cmd, const char* types, IMP newImp, IMP* oriImp)
{
    BOOL retVal = NO;
    if (delegateCls) {
        Method origMethod = class_getInstanceMethod(delegateCls, cmd);
        //const char *runtypes = method_getTypeEncoding(origMethod);
        if (origMethod) {
            *oriImp = method_setImplementation(origMethod,newImp);
            retVal = oriImp != NULL;
        }else{
            retVal = class_addMethod(delegateCls, cmd, newImp, types);
        }
    }
    return retVal;
}
