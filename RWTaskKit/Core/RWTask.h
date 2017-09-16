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


