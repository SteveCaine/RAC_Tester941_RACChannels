//
//  CIOCategories.h
//  oceanalert3
//
//	collection of various convenience categories
//
//  Created by Steve Caine on 08/20/15.
//  Copyright © 2015 ConserveIO. All rights reserved.
//

// SPC 2016-10-25 renamed with 'CIO' prefix for Conserve.IO work

#import <Foundation/Foundation.h>

// ----------------------------------------------------------------------

@interface NSObject (CIOCast)

+ (instancetype)cio_cast:(id)object;

@end

// ----------------------------------------------------------------------

@interface NSError (Smart)

- (NSString *)smartDescription;

@end

// ----------------------------------------------------------------------
