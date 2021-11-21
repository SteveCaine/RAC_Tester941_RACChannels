//
//  AppDelegate.m
//  RAC_Tester941
//
//  Created by Steve Caine on 11/20/21.
//  Copyright © 2021 Steve Caine. All rights reserved.
//

#import "AppDelegate.h"
#import "DetailViewController.h"

// ----------------------------------------------------------------------

@interface AppDelegate () <UISplitViewControllerDelegate>

@end

// ----------------------------------------------------------------------
#pragma mark -
// ----------------------------------------------------------------------

@implementation AppDelegate

- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions {
	// Override point for customization after application launch.
	UISplitViewController *splitVC = (UISplitViewController *)self.window.rootViewController;
	UINavigationController *navigationController = splitVC.viewControllers.lastObject;
	navigationController.topViewController.navigationItem.leftBarButtonItem = splitVC.displayModeButtonItem;
	splitVC.delegate = self;
	return YES;
}

- (void)applicationWillResignActive:(UIApplication *)application {
	// Sent when the application is about to move from active to inactive state. This can occur for certain types of temporary interruptions (such as an incoming phone call or SMS message) or when the user quits the application and it begins the transition to the background state.
	// Use this method to pause ongoing tasks, disable timers, and throttle down OpenGL ES frame rates. Games should use this method to pause the game.
}

- (void)applicationDidEnterBackground:(UIApplication *)application {
	// Use this method to release shared resources, save user data, invalidate timers, and store enough application state information to restore your application to its current state in case it is terminated later.
	// If your application supports background execution, this method is called instead of applicationWillTerminate: when the user quits.
}

- (void)applicationWillEnterForeground:(UIApplication *)application {
	// Called as part of the transition from the background to the inactive state; here you can undo many of the changes made on entering the background.
}

- (void)applicationDidBecomeActive:(UIApplication *)application {
	// Restart any tasks that were paused (or not yet started) while the application was inactive. If the application was previously in the background, optionally refresh the user interface.
}

- (void)applicationWillTerminate:(UIApplication *)application {
	// Called when the application is about to terminate. Save data if appropriate. See also applicationDidEnterBackground:.
}

// ----------------------------------------------------------------------
#pragma mark - Split view
// ----------------------------------------------------------------------

- (BOOL)splitViewController:(UISplitViewController *)splitVC collapseSecondaryViewController:(UIViewController *)secondVC ontoPrimaryViewController:(UIViewController *)primaryViewController {
	if ([secondVC isKindOfClass:UINavigationController.class] &&
		[[(UINavigationController *)secondVC topViewController] isKindOfClass:DetailViewController.class]
//		&& ([(DetailViewController *)[(UINavigationController *)secondVC topViewController] detailItem] == nil)
		) {
		// Return YES to indicate that we have handled the collapse by doing nothing; the secondary controller will be discarded.
		return YES;
	} else {
		return NO;
	}
}

@end

// ----------------------------------------------------------------------
