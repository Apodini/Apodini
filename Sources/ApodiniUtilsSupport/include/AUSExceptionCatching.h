//
//  AUSExceptionCatching.h
//  ApodiniUtilsSupport
//
//  Created by Lukas Kollmer on 2021-03-18.
//  Copyright © 2021 Lukas Kollmer. All rights reserved.
//

@import Foundation;


@interface NSException (ApodiniUtilsSupport)

+ (NSException * _Nullable)tryCatch:(void(NS_NOESCAPE ^ _Nonnull)(void))block;

@end

