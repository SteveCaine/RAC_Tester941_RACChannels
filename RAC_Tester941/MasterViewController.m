//
//  MasterViewController.m
//  RAC_Tester941
//
//  Created by Steve Caine on 11/20/21.
//  Copyright © 2021 Steve Caine. All rights reserved.
//

#import "MasterViewController.h"

#import "DetailViewController.h"

#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wstrict-prototypes"
#import <ReactiveCocoa/ReactiveCocoa.h>
#pragma clang diagnostic pop

#import "CIOCategories.h"
#import "CIOSignals.h"

// ----------------------------------------------------------------------

enum {
	ROW_doQuickie,
	ROW_test_RAC,
	ROW_test_Timer,
	ROW_bump_Age,
	NUM_ROWS
};
static const char *row_titles[] = {
	"do Quickie",
	"test RAC",
	"test Timer",
	"bump Age",
};
static NSUInteger NUM_STRS = sizeof(row_titles)/sizeof(row_titles[0]);

// ----------------------------------------------------------------------
typedef enum : NSUInteger {
//	sightings4last_ALL,
	sightings4last_year, // == ALL
	sightings4last_month,
	sightings4last_week,
	sightings4last_2days
} SightingsAge;
//static const SightingsAge WHALE_SIGHTINGS_DEFAULT_AGE = sightings4last_year;
  static const SightingsAge WHALE_SIGHTINGS_DEFAULT_AGE = sightings4last_month;
//static const SightingsAge WHALE_SIGHTINGS_DEFAULT_AGE = sightings4last_week;
//static const SightingsAge WHALE_SIGHTINGS_DEFAULT_AGE = sightings4last_2days;
// ----------------------------------------------------------------------

// ----------------------------------------------------------------------
#define TEST_INTERVAL	1 // sec
#define TEST_DELAY		1 // sec
// ----------------------------------------------------------------------
static NSString * const OUR_KEY_PREFIX = @"KEY_CIOSettingsBundle_"; // iOS Settings prefs only
// WHALE SIGHTINGS AGE FILTER
static NSString * const KEY_CIOSettingsBundle_SightingsAge
					= @"KEY_CIOSettingsBundle_SightingsAge";
// ----------------------------------------------------------------------
static NSString * const KEY_CIO_pref_added   = @"KEY_CIO_pref_added";
static NSString * const KEY_CIO_pref_removed = @"KEY_CIO_pref_removed";
static NSString * const KEY_CIO_pref_changed = @"KEY_CIO_pref_changed";
// ----------------------------------------------------------------------

static NSString * const SegueID_DetailVC = @"showDetail";
static NSString * const CellID_BasicCell = @"Cell";

// ----------------------------------------------------------------------

@interface MasterViewController ()
@property (strong, nonatomic) NSArray *strs;
@property (strong, nonatomic) RACSignal	*signal_appActive;
@property (strong, nonatomic) RACSignal	*signal_appInactive;
//@property (strong, nonatomic) RACSignal	*signal_prefsChanged;
//@property (strong, nonatomic) RACSignal	*signal_prefsChanged_SightingsAge;
@property (assign, nonatomic) BOOL isTracking;

@property (strong, nonatomic) NSDictionary *ourPrefs;
@end

// ----------------------------------------------------------------------
#pragma mark -
// ----------------------------------------------------------------------
// some test code copied from project 'CIO_AIS_Tester10'

@implementation MasterViewController

- (void)doQuickie {
//	NSArray *ourPrefKeys = self.class.ourPrefKeys;
//	MyLog(@" ourPrefKeys = %@", ourPrefKeys);
//	NSDictionary *ourPrefValues = self.class.ourPrefValues;
//	MyLog(@" ourPrefValues = %@", ourPrefValues);
	[self test_rac];
}

// ----------------------------------------------------------------------

- (void)test_RAC {
	MyLog(@"%s", __FUNCTION__);
	
	NSMutableArray *ma = @[].mutableCopy;
	
	NSArray *lower = @[ @"a", @"b", @"c", ];
	[[[[[lower rac_sequence] signal]
	   map:^id(NSString *ch) {
		   return [self signal2upper:ch];
	   }]
	  concat]
	 subscribeNext:^(id x) {
		 MyLog(@" x = %@", x);
		 [ma addObject:x];
	 } completed:^{
		 MyLog(@" done");
		 MyLog(@" ma => %@", ma);
	 }];
}

// ----------------------------------------------------------------------

- (RACSignal *)signal2upper:(NSString *)s {
	RACSignal *sig = nil;
	sig = [RACSignal createSignal:^RACDisposable *(id<RACSubscriber> subscriber) {
		dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.5 * NSEC_PER_SEC)),
					   dispatch_get_main_queue(), ^{
						   [subscriber sendNext:s.uppercaseString];
						   [subscriber sendCompleted];
					   });
		return nil;
	}];
	sig.name = s;
	//	return nil;
	return sig;
}

// ----------------------------------------------------------------------

- (void)testTimer {
		[[self newTestTimer] subscribeNext:^(id x) {
			MyLog(@"NEXT: %@", x);
		} error:^(NSError *error) {
			MyLog(@"ERRR: %@", error);
		} completed:^{
			MyLog(@"completed");
		}];
}

// ----------------------------------------------------------------------
#pragma mark -
// ----------------------------------------------------------------------

- (void)bumpAge {
	NSNumber *pref = [NSUserDefaults.standardUserDefaults objectForKey:KEY_CIOSettingsBundle_SightingsAge];
	if (pref != nil)
		[NSUserDefaults.standardUserDefaults setInteger:1 + pref.integerValue forKey:KEY_CIOSettingsBundle_SightingsAge];
	else
		[NSUserDefaults.standardUserDefaults setInteger:0 forKey:KEY_CIOSettingsBundle_SightingsAge];
	[NSUserDefaults.standardUserDefaults synchronize];
	
	MyLog(@" age = %li", [NSUserDefaults.standardUserDefaults integerForKey:KEY_CIOSettingsBundle_SightingsAge]);
}

// ----------------------------------------------------------------------

- (void)trackPrefsChange {
	[CIOSignals.instance.signal_prefsChanged subscribeNext:^(id x) {
		MyLog(@"NEXT: %@", x);
#if 0
#else
//		NSArray *allKeys = NSUserDefaults.standardUserDefaults.dictionaryRepresentation.allKeys;
//		MyLog(@" app pref keys = %@", allKeys);
//		NSDictionary *allPrefs = NSUserDefaults.standardUserDefaults.dictionaryRepresentation;
//		MyLog(@" app pref values = %@", allPrefs);
		// check for changes
		if (self.ourPrefs.count) {
			NSDictionary *changes = [self.class changedPrefs:self.ourPrefs];
			if (changes.count) {
				MyLog(@" added:   %@", changes[KEY_CIO_pref_added]);
				MyLog(@" removed: %@", changes[KEY_CIO_pref_removed]);
				MyLog(@" changed: %@", changes[KEY_CIO_pref_changed]);
			}
		}
#endif
		// update our saved (or not here?)
		self.ourPrefs = self.class.ourPrefValues;
	}];
}

// ----------------------------------------------------------------------

- (RACSignal *)signal_prefsChanged_SightingsAge {
//	if (_signal_prefsChanged == nil) {
//		_signal_prefsChanged = [[[NSNotificationCenter defaultCenter] rac_addObserverForName:NSUserDefaultsDidChangeNotification object:nil]
//							 takeUntil:[self rac_willDeallocSignal]];
//	}
//	return _signal_prefsChanged;
	return nil;
}

// ----------------------------------------------------------------------
#pragma mark -
// ----------------------------------------------------------------------

- (void)trackWhaleSightings { // _next: (no error: or completion: for timers)
	static BOOL trackingWhaleSightings;
	if (trackingWhaleSightings == NO) {
		trackingWhaleSightings = YES;
		
		static NSDate *startDate;
		if (startDate == nil)
			startDate = NSDate.date;
		
		static NSDate *lastFire;
		if (lastFire == nil)
			lastFire = NSDate.date;
		
		// once
		static SightingsAge sightingsAge = WHALE_SIGHTINGS_DEFAULT_AGE;
		NSNumber *pref = [NSUserDefaults.standardUserDefaults objectForKey:KEY_CIOSettingsBundle_SightingsAge];
		if (pref != nil)
			sightingsAge = pref.integerValue;
				
		// repeats
		[[[RACSignal merge:@[
			[CIOSignals.instance new_fireForever_interval:15],
			CIOSignals.instance.signal_prefsChanged,
		]
		  ]
		 filter:^BOOL(id value) {
			BOOL result = YES;
			// signal is either timer or *some* pref(s) have changed
			NSDate *date = [NSDate cio_cast:value];
			if (date != nil) {
				MyLog(@" %+4.1f TIMER", -startDate.timeIntervalSinceNow);
//				return YES; // timer fired
				result = YES; // timer fired
} else {
				NSNotification *note = [NSNotification cio_cast:value];
				MyLog(@" note -> '%@'", note.name);
				MyLog(@" %+4.1f PREFS", -lastFire.timeIntervalSinceNow);
			// else prefs-change fired; does it include age pref?
			NSNumber *pref = [NSUserDefaults.standardUserDefaults objectForKey:KEY_CIOSettingsBundle_SightingsAge];
			if (pref == nil || pref.integerValue == sightingsAge) {
				MyLog(@" not age");
//				return NO; // some other pref(s) changed
				result = NO; // some other pref(s) changed
} else {
				MyLog(@" %+4.1f *AGE*", -lastFire.timeIntervalSinceNow);

				sightingsAge = pref.integerValue;
				MyLog(@" age -> %lu", sightingsAge);
}
//			return YES;
}
			MyLog(@" filter returns %s", (result ? "YES":"NO"));
			return result;
		}]
		 subscribeNext:^(id x) {
//			MyLog(@"NEXT: %@", x);
			MyLog(@"NEXT: => FETCH (%lu) WHALES!", sightingsAge);
			lastFire = NSDate.date;
		} error:^(NSError *error) {
			MyLog(@"ERRR: %@", error);
		} completed:^{
			MyLog(@"completed");
		}];
	}
}

// ----------------------------------------------------------------------
#pragma mark -
// ----------------------------------------------------------------------
// from https://coderedirect.com/questions/267634/nsuserdefaultsdidchangenotification-whats-the-name-of-the-key-that-changed
// answer by 'sharjeel' on Monday, August 2, 2021

- (void)watchAge {
//	NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
	[NSUserDefaults.standardUserDefaults addObserver:self
			   forKeyPath:KEY_CIOSettingsBundle_SightingsAge
				  options:NSKeyValueObservingOptionNew
				  context:NULL];
}

- (void)unwatchAge {
//	NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
	[NSUserDefaults.standardUserDefaults removeObserver:self forKeyPath:KEY_CIOSettingsBundle_SightingsAge];
}

-(void)observeValueForKeyPath:(NSString *)keyPath
					 ofObject:(id)object
					   change:(NSDictionary *)change
					  context:(void *)context
{
	// keys are NSString*, values are NSNumber*, object is NSUserDefaults
	MyLog(@"KVO: %@ changed property %@ to value %@", object, keyPath, change);
//	NSArray *allKeys = change.allKeys;
//	NSObject *kind = change[@"kind"];
//	NSObject *new_ = change[@"new"];
	MyLog(@"DONE");
}

// ----------------------------------------------------------------------
#pragma mark -
// ----------------------------------------------------------------------

- (void)test_rac {
	RACChannelTerminal *channel =
		[NSUserDefaults.standardUserDefaults rac_channelTerminalForKey:KEY_CIOSettingsBundle_SightingsAge];
	MyLog(@" channel = %@", channel);
	
	[channel subscribeNext:^(id x) {
		MyLog(@"channel -> %@", x);
	}];
}

// ----------------------------------------------------------------------

- (void)trackSightingAge {
	static BOOL trackingSightingAge;
	if (trackingSightingAge == NO) {
		trackingSightingAge = YES;

		static NSDate *startDate;
		if (startDate == nil)
			startDate = NSDate.date;

		// once
//		static SightingsAge sightingsAge = WHALE_SIGHTINGS_DEFAULT_AGE;
//		NSNumber *pref = [NSUserDefaults.standardUserDefaults objectForKey:KEY_CIOSettingsBundle_SightingsAge];
//		if (pref != nil)
//			sightingsAge = pref.integerValue;
		static NSNumber *sightingsAge;
		if (sightingsAge == nil)
			sightingsAge = @(WHALE_SIGHTINGS_DEFAULT_AGE);

		// repeats
		[[[RACSignal merge:@[
			// TIMER
			[CIOSignals.instance new_fireForever_interval:30],
			// PREF
			[NSUserDefaults.standardUserDefaults rac_channelTerminalForKey:KEY_CIOSettingsBundle_SightingsAge],
		]
		  ]
		 filter:^BOOL(NSObject *value) { // ^BOOL(id value)
			MyLog(@" now age = %@", sightingsAge);
			if (!self.isTracking) return NO;
			// is timer?
			NSDate *date = [NSDate cio_cast:value];
			if (date != nil) {
				MyLog(@" %+4.1f TIMER", -startDate.timeIntervalSinceNow);
				return YES; // TIMER
			}
			// else is age pref! (nil if never set)
			MyLog(@" %+4.1f PREFS", -startDate.timeIntervalSinceNow);
			NSNumber *age = [NSNumber cio_cast:value];
			if (age == nil) {
				MyLog(@" no! age");
				return NO; // pref never set
			}
			if (age.integerValue == sightingsAge.integerValue)
				return NO; // startup value matches default
			// else this MUST be a change in pref
			MyLog(@" new age = %@", age);
			sightingsAge = @(age.integerValue);
			return YES;
		}]
		 subscribeNext:^(NSObject *x) { // ^(id x)
			MyLog(@"NEXT: %@", NSStringFromClass(x.class));
			MyLog(@" fetch whale sightings for last (%lu)", sightingsAge.integerValue);
		} error:^(NSError *error) {
			MyLog(@"ERRR: %@", error);
		} completed:^{
			MyLog(@"completed");
		}];
	}
}

// ----------------------------------------------------------------------
#pragma mark -
// ----------------------------------------------------------------------

- (void)trackAppActive {
	static BOOL trackingActive;
	if (trackingActive == NO) {
		trackingActive = YES;
		
		[[[RACSignal merge:@[
			CIOSignals.instance.signal_appActive,
			CIOSignals.instance.signal_appInactive,
//			[CIOSignals.instance new_fireForever_interval:5]
		]
		  ]
		 filter:^BOOL(id value) {
			return YES;
		}]
		 subscribeNext:^(id x) {
			static NSUInteger count;
            // either/or
			NSNotification  *note = [NSNotification cio_cast:x];
			NSDate          *date = [NSDate cio_cast:x];
			if (note)
				MyLog(@" note -> '%@'", note.name);
			else if (date) {
				count += 1;
				MyLog(@" time -> %@ (%lu)", date, count);
			}
			else
				MyLog(@"NEXT: %@", x);
		} error:^(NSError *error) {
			MyLog(@"ERRR: %@", error);
		} completed:^{
			MyLog(@"completed");
		}];
	}
}

// ----------------------------------------------------------------------

- (RACSignal *)newTestTimer {
	return [CIOSignals.instance new_fireForever_interval:TEST_INTERVAL
												   start:nil
												   delay:TEST_DELAY];
}

// ----------------------------------------------------------------------
#pragma mark -
// ----------------------------------------------------------------------

+ (NSPredicate *)predicate_ourPrefKeys {
	static NSPredicate *predicate;
	static dispatch_once_t onceToken;
	dispatch_once(&onceToken, ^{
		predicate = [NSPredicate predicateWithBlock:^BOOL(id obj, NSDictionary<NSString *,id> *bindings) {
			NSString *key = [NSString cio_cast:obj];
			if ([key hasPrefix:OUR_KEY_PREFIX])
				return YES;
//			MyLog(@" obj = %@, bindings = %@", obj, bindings);
			return NO;
		}];
	});
	return predicate;
}

// ----------------------------------------------------------------------

+ (NSArray *)ourPrefKeys {
//	NSArray *allKeys = NSUserDefaults.standardUserDefaults.dictionaryRepresentation.allKeys;
//	NSArray *ourKeys = [allKeys filteredArrayUsingPredicate:self.class.predicate_ourPrefKeys];
	
	NSDictionary *allPrefs = NSUserDefaults.standardUserDefaults.dictionaryRepresentation;
	NSSet *ourKeysSet = [allPrefs keysOfEntriesPassingTest:^BOOL(id key, id obj, BOOL *stop) {
		NSString *str_key = [NSString cio_cast:key];
		if ([str_key hasPrefix:OUR_KEY_PREFIX])
			return YES;
		return NO;
	}];
	NSArray *ourKeys = ourKeysSet.allObjects;
	
	return ourKeys;
}

// ----------------------------------------------------------------------

+ (NSDictionary *)ourPrefValues {
	NSMutableDictionary *result = @{}.mutableCopy;
//	NSArray *allKeys = NSUserDefaults.standardUserDefaults.dictionaryRepresentation.allKeys;
//	NSArray *ourKeys = [allKeys filteredArrayUsingPredicate:self.class.predicate_ourPrefKeys];
	NSArray *ourKeys = self.class.ourPrefKeys;
	for (NSString *key in ourKeys) {
		NSObject *obj = [NSUserDefaults.standardUserDefaults objectForKey:key];
		if (obj)
			result[key] = obj;
	}
	return result.copy;
}

// ----------------------------------------------------------------------

+ (NSDictionary *)changedPrefs:(NSDictionary *)oldPrefs {
	NSMutableDictionary *result = @{}.mutableCopy;
	
	NSDictionary *newPrefs = self.class.ourPrefValues;
	
	MyLog(@" => oldPrefs: %@", oldPrefs);
	MyLog(@" => newPrefs: %@", newPrefs);

	// NO CHANGE?
	if ([newPrefs isEqualToDictionary:oldPrefs])
		return @{};
	
	NSArray *oldKeys = [oldPrefs.allKeys filteredArrayUsingPredicate:self.class.predicate_ourPrefKeys];
	// we just filtered this ourselves
	NSArray *newKeys = newPrefs.allKeys;
	
	NSMutableSet *set_allKeys = [NSSet setWithArray:oldKeys].mutableCopy;
	[set_allKeys addObjectsFromArray:newKeys];
	NSArray *allKeys = set_allKeys.allObjects;
	
	for (NSString *key in allKeys) {
		// ADDED?
		if (YES == [newKeys containsObject:key] && NO == [oldKeys containsObject:key]) {
			NSObject *addedValue = newPrefs[key];
			result[KEY_CIO_pref_added] = @{ key : addedValue };
		}
//		else
		// REMOVED?
		if (NO == [newKeys containsObject:key] && YES == [oldKeys containsObject:key]) {
			NSObject *removedValue = oldPrefs[key];
			result[KEY_CIO_pref_removed] = @{ key : removedValue };
		}
//		else
		// CHANGED?
		if (YES == [newKeys containsObject:key] && YES == [oldKeys containsObject:key]) {
			NSObject *oldValue = oldPrefs[key];
			NSObject *newValue = newPrefs[key];
			if (![newValue isEqual:oldValue])
				result[KEY_CIO_pref_changed] = @{ key : newValue };
		}
	}
	
	return result.copy;
}

// ----------------------------------------------------------------------
#pragma mark -
// ----------------------------------------------------------------------

- (void)viewDidLoad {
	MyLog(@"%s", __FUNCTION__);
	[super viewDidLoad];
	// Do any additional setup after loading the view, typically from a nib.
	self.detailViewController = (DetailViewController *)
		[self.splitViewController.viewControllers.lastObject topViewController];
// 	self.strs = @[ @"one", @"two", @"three" ];
	NSCAssert(NUM_ROWS <= NUM_STRS, @"Missing titles for table rows.");
	
	NSMutableArray *strs = @[].mutableCopy;
	for (int i = 0; i < NUM_ROWS; ++i)
		[strs addObject:@(row_titles[i])];
	self.strs = strs.copy;
	
	self.ourPrefs = self.class.ourPrefValues;
	MyLog(@" orig prefs: %@", self.ourPrefs);
	
	[self trackAppActive];
//	[self trackPrefsChange];
//	[self trackWhaleSightings];
	
//	[self watchAge];
	
	self.isTracking = YES;
	[self trackSightingAge];
	
//	NSArray *allKeys = NSUserDefaults.standardUserDefaults.dictionaryRepresentation.allKeys;
////	MyLog(@" app pref keys = %@", allKeys);
//	MyLog(@" our pref keys = %@", [allKeys filteredArrayUsingPredicate:self.class.predicate_ourPrefKeys]);
//	NSDictionary *allPrefs = NSUserDefaults.standardUserDefaults.dictionaryRepresentation;
//	MyLog(@" app pref values = %@", allPrefs);
}

// ----------------------------------------------------------------------
- (void)viewWillAppear:(BOOL)animated {
    MyLog(@"%s", __FUNCTION__);
	self.clearsSelectionOnViewWillAppear = self.splitViewController.isCollapsed;
	[super viewWillAppear:animated];
}
- (void)viewDidAppear:(BOOL)animated {
	MyLog(@"%s", __FUNCTION__);
	[super viewDidAppear:animated];
//	// check for changes
//	if (self.ourPrefs.count) {
//		NSDictionary *changes = [self.class changedPrefs:self.ourPrefs];
//		if (changes.count) {
//			MyLog(@" added:   %@", changes[KEY_CIO_pref_added]);
//			MyLog(@" removed: %@", changes[KEY_CIO_pref_removed]);
//			MyLog(@" changed: %@", changes[KEY_CIO_pref_changed]);
//		}
//	}
//	// update our saved (or not here?)
//	self.ourPrefs = self.class.ourPrefValues;
}
- (void)viewWillDisappear:(BOOL)animated {
	MyLog(@"%s", __FUNCTION__);
	[super viewWillDisappear:animated];
	// update our saved (again?)
//	self.ourPrefs = self.class.ourPrefValues;
}
- (void)viewDidDisappear:(BOOL)animated {
	MyLog(@"%s", __FUNCTION__);
	[super viewDidDisappear:animated];
}
// ----------------------------------------------------------------------

- (void)didReceiveMemoryWarning {
	[super didReceiveMemoryWarning];
	// Dispose of any resources that can be recreated.
}

- (void)dealloc {
	// release any observers we have created
	[self unwatchAge];
}

// ----------------------------------------------------------------------
#pragma mark - UITableViewDataSource
// ----------------------------------------------------------------------

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
	return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
	return self.strs.count;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
	UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:CellID_BasicCell forIndexPath:indexPath];

	cell.textLabel.text = self.strs[indexPath.row];
//	cell.selectionStyle = UITableViewCellSelectionStyleNone; // or 'setSelected:NO' below
	return cell;
}

// ----------------------------------------------------------------------
#pragma mark - UITableViewDelegate
// ----------------------------------------------------------------------

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
	UITableViewCell *cell = [self.tableView cellForRowAtIndexPath:indexPath];
	[cell setSelected:NO animated:YES];
	
	switch (indexPath.row) {
		case ROW_doQuickie:
			[self doQuickie];
			break;
		case ROW_test_RAC:
			[self test_RAC];
			break;
		case ROW_test_Timer:
			[self testTimer];
			break;
		case ROW_bump_Age:
			[self bumpAge];
			break;
		default:
			break;
	}
}

// ----------------------------------------------------------------------
#pragma mark - Segues
// ----------------------------------------------------------------------

- (BOOL)shouldPerformSegueWithIdentifier:(NSString *)identifier sender:(id)sender {
// 	UITableViewCell *cell = (UITableViewCell *)sender;
// 	NSIndexPath *indexPath = [self.tableView indexPathForCell:cell];
//	return YES; // default
	return NO;
}

- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
	if ([segue.identifier isEqualToString:SegueID_DetailVC]) {
		NSIndexPath *indexPath = [self.tableView indexPathForSelectedRow];
		NSString *str = self.strs[indexPath.row];
		DetailViewController *controller = (DetailViewController *)[segue.destinationViewController topViewController];
		controller.detailItem = str;
		controller.navigationItem.leftBarButtonItem = self.splitViewController.displayModeButtonItem;
		controller.navigationItem.leftItemsSupplementBackButton = YES;
	}
}

@end

// ----------------------------------------------------------------------
