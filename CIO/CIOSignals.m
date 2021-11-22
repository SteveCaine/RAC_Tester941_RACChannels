//
//  CIOSignals.m
//  oceanalert3
//
//  Created by Steve Caine on 10/21/18.
//  Copyright © 2018 Conserve.IO. All rights reserved.
//

#import "CIOSignals.h"

#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wstrict-prototypes"
//@import ReactiveCocoa;
#import <ReactiveCocoa/ReactiveCocoa.h>
#pragma clang diagnostic pop

// ----------------------------------------------------------------------

@interface CIOSignals ()
@property (strong, nonatomic, readwrite) RACSignal	*signal_appActive;
@property (strong, nonatomic, readwrite) RACSignal	*signal_appInactive;
@end

// ----------------------------------------------------------------------
#pragma mark -
// ----------------------------------------------------------------------

@implementation CIOSignals

+ (CIOSignals *)instance {
	static CIOSignals *instance;
	static dispatch_once_t onceToken;
	dispatch_once(&onceToken, ^{
		instance = [[self alloc] init];
	});
	return instance;
}
// ----------------------------------------------------------------------
// continuous signals: fire when app becomes active/inactive

- (RACSignal *)signal_appActive {
	if (_signal_appActive == nil) {
		_signal_appActive = [[[NSNotificationCenter defaultCenter] rac_addObserverForName:UIApplicationDidBecomeActiveNotification object:nil]
							 takeUntil:[self rac_willDeallocSignal]];
	}
	return _signal_appActive;
}

- (RACSignal *)signal_appInactive {
	if (_signal_appInactive == nil) {
		_signal_appInactive = [[[NSNotificationCenter defaultCenter] rac_addObserverForName:UIApplicationDidEnterBackgroundNotification object:nil]
							   takeUntil:[self rac_willDeallocSignal]];
	}
	return _signal_appInactive;
}

// ----------------------------------------------------------------------
#pragma mark -
// ----------------------------------------------------------------------
// start now w/ no delay

- (RACSignal *)new_fireForever_interval:(NSTimeInterval)interval {
	return [self new_fireForever_interval:interval start:nil delay:0];
}

// ----------------------------------------------------------------------

- (RACSignal *)new_fireForever_interval:(NSTimeInterval)interval
								  start:(nullable NSDate *)start
								  delay:(NSTimeInterval)delay {
	if (start == nil)
		start  = NSDate.date; // now
	
	return [[[[RACSignal interval:interval
					  onScheduler:[RACScheduler mainThreadScheduler]]
			  startWith:start]
			 takeUntil:[self rac_willDeallocSignal]]
			delay:delay];
}

// ----------------------------------------------------------------------
// sends -next: 'count' times then sends -completed and stops

- (RACSignal *)new_fireSeveral_interval:(NSTimeInterval)interval
								  start:(nullable NSDate *)start
								  delay:(NSTimeInterval)delay
								  count:(NSUInteger)count {
	if (delay < 0)
		delay = 0;
	
	__block NSUInteger remaining = count;
	
	RACSignal *signal = [RACSignal createSignal:^RACDisposable *(id<RACSubscriber> subscriber) {
		RACSignal *timer = [self new_fireForever_interval:interval start:start delay:delay];
		[[timer
		  takeUntilBlock:^BOOL(id x) {
			  return (remaining == 0);
		  }]
		 
		 subscribeNext:^(id x) {
			 if (remaining > 0) {
				 [subscriber sendNext:@(1 + count - remaining)];
				 remaining -= 1;
				 // or, like a timer, just send 'next:' until done?
				 if (remaining == 0)
					 [subscriber sendCompleted];
			 }
		 }];
		return nil;
	}];
	return signal;
}

// ----------------------------------------------------------------------

- (RACSignal *)new_fireOnce_delay:(NSTimeInterval)delay {
	return [self new_fireSeveral_interval:1 start:nil delay:delay count:1];
}

// ----------------------------------------------------------------------
#pragma mark - DEBUGGING
// ----------------------------------------------------------------------
// simulates a network request that takes time to complete and sometimes fails with error
// failure_rate 0-to-1 = 'never' to 100%

- (RACSignal *)new_fauxRequest_delay:(NSTimeInterval)delay
						failure_rate:(float)failure_rate {
	if (delay < 0)
		delay = 0;
	NSTimeInterval interval = (delay > 0 ? delay/3.1 : 0.1);
	
	// set up failure_rate
	uint32_t tries_per_error;
	uint32_t try_that_errors; // it's request X that fails
	
	if (failure_rate <= 0) {
		tries_per_error = UINT32_MAX - 1;
		try_that_errors = UINT32_MAX;
	} else if (failure_rate >= 1) {
		tries_per_error = 1;
		try_that_errors = 0;
	} else {
		tries_per_error = (uint32_t) roundf( 1.0/failure_rate );
		try_that_errors = arc4random_uniform( tries_per_error );
	}
	MyLog(@" %i/error - #%i is error", tries_per_error, try_that_errors);
	
	static NSInteger count;
	
	//	NSDate *start = NSDate.date;
	
	__block BOOL done = NO;
	
	RACSignal *signal = [RACSignal createSignal:^RACDisposable *(id<RACSubscriber> subscriber) {
		RACSignal *timer = [self new_fireForever_interval:interval start:nil delay:delay];
		[[timer
		  takeUntilBlock:^BOOL(id x) {
			  // stop on NEXT pass
			  BOOL result = done;
			  done = YES;
			  return result;
		  }]
		 
		 subscribeNext:^(id x) {
			 //			 MyLog(@" fire at +%4.1f sec", -[start timeIntervalSinceNow]);
			 if ((count++ % tries_per_error) == try_that_errors)
				 [subscriber sendError:[self errorWithMessage:@"oops"]];
			 else
				 [subscriber sendNext:@(count)];
			 [subscriber sendCompleted];
		 }];
		return nil;
	}];
	return signal;
}

// ----------------------------------------------------------------------

- (NSError *)errorWithMessage:(NSString *)message {
	if (message.length == 0)
		message = NSLocalizedString(@"Unknown error.", @"Unknown error.");
	NSDictionary *userInfo = @{ NSLocalizedDescriptionKey : message };
	return [NSError errorWithDomain:@"CIOSignals_fauxErrorDomain" code:1 userInfo:userInfo];
}

@end

// ----------------------------------------------------------------------
