//
//  MasterViewController.m
//  RAC_Tester941
//
//  Created by Steve Caine on 11/20/21.
//  Copyright © 2021 Steve Caine. All rights reserved.
//

#import "MasterViewController.h"

#import "DetailViewController.h"

#import <ReactiveCocoa/ReactiveCocoa.h>

// ----------------------------------------------------------------------

enum {
	ROW_test_RAC,
	NUM_ROWS
};
static const char *row_titles[] = {
	"test RAC",
};
static NSUInteger NUM_STRS = sizeof(row_titles)/sizeof(row_titles[0]);

// ----------------------------------------------------------------------

static NSString * const SegueID_DetailVC = @"showDetail";
static NSString * const CellID_BasicCell = @"Cell";

// ----------------------------------------------------------------------

@interface MasterViewController ()
@property (strong, nonatomic) NSArray *strs;
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
#pragma mark -
// ----------------------------------------------------------------------

- (void)viewDidLoad {
	MyLog(@"%s", __FUNCTION__);
	[super viewDidLoad];
	// Do any additional setup after loading the view, typically from a nib.
	self.detailViewController = (DetailViewController *)[self.splitViewController.viewControllers.lastObject topViewController];
// 	self.strs = @[ @"one", @"two", @"three" ];
	NSCAssert(NUM_ROWS <= NUM_STRS, @"Missing titles for table rows.");
	
	NSMutableArray *strs = @[].mutableCopy;
	for (int i = 0; i < NUM_ROWS; ++i)
		[strs addObject:@(row_titles[i])];
	self.strs = strs.copy;
}

- (void)viewWillAppear:(BOOL)animated {
	self.clearsSelectionOnViewWillAppear = self.splitViewController.isCollapsed;
	[super viewWillAppear:animated];
}

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
