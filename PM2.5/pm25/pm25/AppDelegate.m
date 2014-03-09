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

#pragma mark - UIApplicationDelegate
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
    
    if( [[NSUserDefaults standardUserDefaults] boolForKey: kUserDefaultsPushNotificationsEnabledKey] ) {
        [application registerForRemoteNotificationTypes: UIRemoteNotificationTypeAlert | UIRemoteNotificationTypeBadge | UIRemoteNotificationTypeSound];
    }
    else {
        [application unregisterForRemoteNotifications];
    }
    
    return YES;
}

- (void) application:(UIApplication *)application didRegisterForRemoteNotificationsWithDeviceToken:(NSData *)deviceToken {
    //TODO: Send to server
}

- (void) application:(UIApplication *)application didFailToRegisterForRemoteNotificationsWithError:(NSError *)error {
    
}

@end
