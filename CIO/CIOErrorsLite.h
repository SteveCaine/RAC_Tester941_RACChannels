//
//  CIOErrorsLite.h
//  CIOPhotosPicker2
//
//  Created by Steve Caine on 12/20/16.
//  Copyright © 2016 Steve Caine. All rights reserved.
//

#import <Foundation/Foundation.h>

// ----------------------------------------------------------------------

@interface CIOErrorsLite : NSObject

+ (NSError *)errorWithMessage:(NSString *)message;
+ (NSError *)errorWithMessage:(NSString *)message domain:(NSString *)domain;

+ (NSError *)errorWithCode:(NSInteger)code message:(NSString *)message;
+ (NSError *)errorWithCode:(NSInteger)code message:(NSString *)message domain:(NSString *)domain;

+ (NSError *)userCancelledError;

@end

// ----------------------------------------------------------------------
