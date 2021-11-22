//
//  CIOErrorsLite.m
//  CIOPhotosPicker2
//
//  Created by Steve Caine on 12/20/16.
//  Copyright © 2016 Steve Caine. All rights reserved.
//

#import "CIOErrorsLite.h"

//#import "CIOAppUtil.h"

// ----------------------------------------------------------------------

@implementation CIOErrorsLite

+ (NSError *)errorWithMessage:(NSString *)message {
	return [self errorWithCode:1 message:message domain:nil];
}

+ (NSError *)errorWithMessage:(NSString *)message domain:(NSString *)domain {
	return [self errorWithCode:1 message:message domain:domain];
}

+ (NSError *)errorWithCode:(NSInteger)code message:(NSString *)message {
	return [self errorWithCode:code message:message domain:nil];
}

// ----------------------------------------------------------------------

+ (NSError *)errorWithCode:(NSInteger)code message:(NSString *)message domain:(NSString *)domain {
	if (code) {
		if (message.length == 0)
			message = NSLocalizedString(@"Unknown error.",
										@"Unknown error.");
		if (domain.length == 0)
			domain = self.domain;
		NSDictionary *userInfo = @{ NSLocalizedDescriptionKey : message };
		return [NSError errorWithDomain:domain code:code userInfo:userInfo];
	}
	return nil;
}

// ----------------------------------------------------------------------

+ (NSError *)userCancelledError {
	NSDictionary *userInfo = @{ NSLocalizedDescriptionKey : NSLocalizedString(@"User cancelled.",
																			  @"(non)error message")  };
	NSError *error = [NSError errorWithDomain:NSCocoaErrorDomain code:NSUserCancelledError userInfo:userInfo];
	return error;
}

// ----------------------------------------------------------------------
// default "{app-name}ErrorDomain"

+ (NSString *)domain {
	NSString *name = [self appNameFromBundle];
	// remove spaces - "Whale Alert" => "WhaleAlert"
	name = [name stringByReplacingOccurrencesOfString:@" " withString:@""];
	if (name.length == 0)
		name = @"CIOGeneric";
	
	NSString *result = [NSString stringWithFormat:
						NSLocalizedString(@"%@ErrorDomain",
										  @"'{app-name}ErrorDomain'"),
						name];
	return result;
}

// ----------------------------------------------------------------------
static NSString * const KEY_appName_Display	= @"CFBundleDisplayName";
static NSString * const KEY_appName_Bundle	= @"CFBundleName";
// ----------------------------------------------------------------------

+ (NSString *)appNameFromBundle {
	NSString *result = nil;
	
	NSDictionary *info = NSBundle.mainBundle.infoDictionary;
	result = info[KEY_appName_Display];
	if (result == nil)
		result = info[KEY_appName_Bundle];
	
	return result;
}

@end

// ----------------------------------------------------------------------
