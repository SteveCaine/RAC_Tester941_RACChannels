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
	ROW_test_RAC,
	ROW_test_Timer,
	NUM_ROWS
};
static const char *row_titles[] = {
	"test RAC",
	"test Timer",
};
static NSUInteger NUM_STRS = sizeof(row_titles)/sizeof(row_titles[0]);

// ----------------------------------------------------------------------
#define TEST_INTERVAL	1 // sec
#define TEST_DELAY		1 // sec
// ----------------------------------------------------------------------

static NSString * const SegueID_DetailVC = @"showDetail";
static NSString * const CellID_BasicCell = @"Cell";

// ----------------------------------------------------------------------

@interface MasterViewController ()
@property (strong, nonatomic) NSArray *strs;
@property (strong, nonatomic) RACSignal	*signal_appActive;
@property (strong, nonatomic) RACSignal	*signal_appInactive;
@end

// ----------------------------------------------------------------------
#pragma mark -
// ----------------------------------------------------------------------
// some test code copied from project 'CIO_AIS_Tester10'

@implementation MasterViewController

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
			NSNotification *note = [NSNotification cio_cast:x];
			NSDate *date = [NSDate cio_cast:x];
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
												   delay:0];
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
	
	[self trackAppActive];
}

// ----------------------------------------------------------------------
- (void)viewWillAppear:(BOOL)animated {
	self.clearsSelectionOnViewWillAppear = self.splitViewController.isCollapsed;
	[super viewWillAppear:animated];
}
- (void)viewDidAppear:(BOOL)animated {
	MyLog(@"%s", __FUNCTION__);
	[super viewDidAppear:animated];
}
- (void)viewWillDisappear:(BOOL)animated {
	MyLog(@"%s", __FUNCTION__);
	[super viewWillDisappear:animated];
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
		case ROW_test_RAC:
			[self test_RAC];
			break;
		case ROW_test_Timer:
			[self testTimer];
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
