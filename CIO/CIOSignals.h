//
//  CIOSignals.h
//  oceanalert3
//
//  Created by Steve Caine on 10/21/18.
//  Copyright © 2018 Conserve.IO. All rights reserved.
//

#import <Foundation/Foundation.h>

// ----------------------------------------------------------------------
@class RACSignal;
// ----------------------------------------------------------------------
NS_ASSUME_NONNULL_BEGIN

@interface CIOSignals : NSObject

@property (strong, nonatomic, readonly) RACSignal *signal_appActive;
@property (strong, nonatomic, readonly) RACSignal *signal_appInactive;
@property (strong, nonatomic, readonly) RACSignal *signal_prefsChanged;

+ (CIOSignals *)instance;

- (RACSignal *)new_fireForever_interval:(NSTimeInterval)interval;

- (RACSignal *)new_fireForever_interval:(NSTimeInterval)interval
								  start:(nullable NSDate *)start // nil == now
								  delay:(NSTimeInterval)delay;

- (RACSignal *)new_fireSeveral_interval:(NSTimeInterval)interval
								  start:(nullable NSDate *)start // nil == now
								  delay:(NSTimeInterval)delay
								  count:(NSUInteger)count;

- (RACSignal *)new_fireOnce_delay:(NSTimeInterval)delay;

// DEBUGGING
// simulates a network request that takes time to complete and sometimes fails with error
// failure_rate = 0.0 to 1.0 == 'never' to 100%

- (RACSignal *)new_fauxRequest_delay:(NSTimeInterval)delay
						failure_rate:(float)failure_rate;

@end

NS_ASSUME_NONNULL_END
// ----------------------------------------------------------------------
