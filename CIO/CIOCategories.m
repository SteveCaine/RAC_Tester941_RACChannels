//
//  CIOCategories.m
//  oceanalert3
//
//  Created by Steve Caine on 08/20/15.
//  Copyright © 2015 ConserveIO. All rights reserved.
//

#import "CIOCategories.h"

// ----------------------------------------------------------------------

@implementation NSObject (CIOCast)

+ (instancetype)cio_cast:(id)object {
	return [object isKindOfClass:self] ? object : nil;
}

@end

// ----------------------------------------------------------------------

@implementation NSError (Smart)

- (NSString *)smartDescription {
#if DEBUG
	return [self debugDescription];
#else
	return [self localizedDescription];
#endif
}

@end

// ----------------------------------------------------------------------
