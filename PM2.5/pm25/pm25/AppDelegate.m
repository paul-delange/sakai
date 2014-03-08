//
//  AppDelegate.m
//  pm25
//
//  Created by Paul de Lange on 9/03/2014.
//  Copyright (c) 2014 Chesterford. All rights reserved.
//

#import "AppDelegate.h"

#import "AppContainerViewController.h"

#import "AppMenuItem.h"

@implementation AppDelegate

- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions
{

    AppContainerViewController* container = (AppContainerViewController*)self.window.rootViewController;
    UIViewController* vc1 = [container.storyboard instantiateViewControllerWithIdentifier: @"CurrentLocationViewController"];
    UIViewController* vc2 = [container.storyboard instantiateViewControllerWithIdentifier: @"MapViewController"];
    UIViewController* vc3 = [container.storyboard instantiateViewControllerWithIdentifier: @"SettingsViewController"];
    
    AppMenuItem* item1 = [[AppMenuItem alloc] initWithViewController: vc1
                                                               image: [UIImage imageNamed: @"current-icon"]
                                                            andTitle: NSLocalizedString(@"Current Location", @"")];
    AppMenuItem* item2 = [[AppMenuItem alloc] initWithViewController: vc2
                                                               image: [UIImage imageNamed: @"maps-icon"]
                                                            andTitle: NSLocalizedString(@"Global readings", @"")];
    AppMenuItem* item3 = [[AppMenuItem alloc] initWithViewController: vc3
                                                               image: [UIImage imageNamed: @"settings-icon"]
                                                            andTitle: NSLocalizedString(@"Settings", @"")];
    
    container.menuItems = @[item1, item2, item3];
    
    return YES;
}

- (void)applicationWillResignActive:(UIApplication *)application
{
    // Sent when the application is about to move from active to inactive state. This can occur for certain types of temporary interruptions (such as an incoming phone call or SMS message) or when the user quits the application and it begins the transition to the background state.
    // Use this method to pause ongoing tasks, disable timers, and throttle down OpenGL ES frame rates. Games should use this method to pause the game.
}

- (void)applicationDidEnterBackground:(UIApplication *)application
{
    // Use this method to release shared resources, save user data, invalidate timers, and store enough application state information to restore your application to its current state in case it is terminated later. 
    // If your application supports background execution, this method is called instead of applicationWillTerminate: when the user quits.
}

- (void)applicationWillEnterForeground:(UIApplication *)application
{
    // Called as part of the transition from the background to the inactive state; here you can undo many of the changes made on entering the background.
}

- (void)applicationDidBecomeActive:(UIApplication *)application
{
    // Restart any tasks that were paused (or not yet started) while the application was inactive. If the application was previously in the background, optionally refresh the user interface.
}

- (void)applicationWillTerminate:(UIApplication *)application
{
    // Called when the application is about to terminate. Save data if appropriate. See also applicationDidEnterBackground:.
}

@end
