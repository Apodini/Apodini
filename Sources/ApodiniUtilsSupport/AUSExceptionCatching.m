//
//  AUSExceptionCatching.h
//  ApodiniUtilsSupport
//
//  Created by Lukas Kollmer on 2021-03-18.
//  Copyright © 2021 Lukas Kollmer. All rights reserved.
//

#import "AUSExceptionCatching.h"

@implementation NSException (ApodiniUtilsSupport)

+ (NSException *)tryCatch:(void (NS_NOESCAPE ^)(void))block {
    @try {
        block();
    } @catch (NSException *exception) {
        return exception;
    }
    return nil;
}

@end
