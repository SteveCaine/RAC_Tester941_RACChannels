//
//  DetailViewController.h
//  RAC_Tester941
//
//  Created by Steve Caine on 11/20/21.
//  Copyright © 2021 Steve Caine. All rights reserved.
//

#import <UIKit/UIKit.h>

// ----------------------------------------------------------------------

@interface DetailViewController : UIViewController

@property (  weak, nonatomic) IBOutlet UILabel *detailDescriptionLabel;

@property (  copy, nonatomic) NSString *detailItem;

@end

// ----------------------------------------------------------------------
