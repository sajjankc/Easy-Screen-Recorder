//
//  ESRAppDelegate.m
//  EasyScreenRecord
//
//  Created by Sajjan on 7/23/13.
//  Copyright (c) 2013 sajjankc. All rights reserved.
//

#import "ESRAppDelegate.h"
#import "ESRHomeVC.h"
#import "ESRMoreVC.h"
#import "ESRViewVideoHandler.h"

@implementation ESRAppDelegate

@synthesize tabBarController;

- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions{
    self.window = [[UIWindow alloc] initWithFrame:[[UIScreen mainScreen] bounds]];
    // Override point for customization after application launch.
    self.tabBarController = [[UITabBarController alloc]init];
    self.tabBarController.delegate = self;
    
    if ([[UIDevice currentDevice] userInterfaceIdiom] == UIUserInterfaceIdiomPhone) {
        ESRHomeVC *homeVC = [[ESRHomeVC alloc]initWithNibName:@"ESRHomeVC" bundle:nil];
        UINavigationController *homeNav = [[UINavigationController alloc]initWithRootViewController:homeVC];
        homeNav.tabBarItem.title = @"Home";
        homeNav.navigationBar.barStyle = UIBarStyleBlack;
        
        ESRMoreVC *moreVC = [[ESRMoreVC alloc]initWithNibName:@"ESRMoreVC" bundle:nil];
        UINavigationController *moreNav = [[UINavigationController alloc]initWithRootViewController:moreVC];
        moreNav.navigationBar.backgroundColor = [UIColor blackColor];
        moreNav.tabBarItem.title = @"More";
        moreNav.navigationBar.barStyle = UIBarStyleBlack;
        
        self.tabBarController.viewControllers = [NSArray arrayWithObjects:homeNav, moreNav, nil];
    } else {
        //load ViewControllers for iPad.
    }
    
    self.window.rootViewController = self.tabBarController;
    self.window.backgroundColor = [UIColor whiteColor];
    [self.window makeKeyAndVisible];
    return YES;
}

- (void)applicationWillResignActive:(UIApplication *)application {
    // Sent when the application is about to move from active to inactive state. This can occur for certain types of temporary interruptions (such as an incoming phone call or SMS message) or when the user quits the application and it begins the transition to the background state.
    // Use this method to pause ongoing tasks, disable timers, and throttle down OpenGL ES frame rates. Games should use this method to pause the game.
}

- (void)applicationDidEnterBackground:(UIApplication *)application {
    [ESRViewVideoHandler stopScreenRecording];
}

- (void)applicationWillEnterForeground:(UIApplication *)application {
    // Called as part of the transition from the background to the inactive state; here you can undo many of the changes made on entering the background.
}

- (void)applicationDidBecomeActive:(UIApplication *)application {
    [ESRViewVideoHandler startScreenRecording];
}

- (void)applicationWillTerminate:(UIApplication *)application {
    // Called when the application is about to terminate. Save data if appropriate. See also applicationDidEnterBackground:.
}

@end
