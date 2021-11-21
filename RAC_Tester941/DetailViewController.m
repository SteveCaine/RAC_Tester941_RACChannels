//
//  DetailViewController.m
//  RAC_Tester941
//
//  Created by Steve Caine on 11/20/21.
//  Copyright © 2021 Steve Caine. All rights reserved.
//

#import "DetailViewController.h"

// ----------------------------------------------------------------------

@interface DetailViewController ()

@end

// ----------------------------------------------------------------------
#pragma mark -
// ----------------------------------------------------------------------

@implementation DetailViewController

- (void)configureView {
	// Update the user interface for the detail item.
	if (self.detailItem) {
	    self.detailDescriptionLabel.text = [self.detailItem description];
	}
}


- (void)viewDidLoad {
	[super viewDidLoad];
	// Do any additional setup after loading the view, typically from a nib.
	[self configureView];
}


- (void)didReceiveMemoryWarning {
	[super didReceiveMemoryWarning];
	// Dispose of any resources that can be recreated.
}


#pragma mark - Managing the detail item

- (void)setDetailItem:(NSString *)newDetailItem {
	if (_detailItem != newDetailItem) {
	    _detailItem = newDetailItem;
	    
	    // Update the view.
	    [self configureView];
	}
}

@end

// ----------------------------------------------------------------------
