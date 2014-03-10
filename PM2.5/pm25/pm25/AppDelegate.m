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
#import "VersionComparator.h"

@implementation AppDelegate

#pragma mark - UIApplicationDelegate
- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions
{
    AppContainerViewController* container = (AppContainerViewController*)self.window.rootViewController;
    
    UIViewController* vc1 = [container.storyboard instantiateViewControllerWithIdentifier: @"CurrentLocationViewController"];
    UIViewController* vc2 = [container.storyboard instantiateViewControllerWithIdentifier: @"MapViewController"];
    UIViewController* vc3 = [container.storyboard instantiateViewControllerWithIdentifier: @"SettingsViewController"];
    
    AppMenuItem* item1 = [[AppMenuItem alloc] initWithViewController: vc1
                                                               image: @"current-icon"
                                                            andTitle: NSLocalizedString(@"Current Location", @"")];
    AppMenuItem* item2 = [[AppMenuItem alloc] initWithViewController: vc2
                                                               image: @"maps-icon"
                                                            andTitle: NSLocalizedString(@"Global readings", @"")];
    AppMenuItem* item3 = [[AppMenuItem alloc] initWithViewController: vc3
                                                               image: @"settings-icon"
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

- (BOOL) application:(UIApplication *)application shouldSaveApplicationState:(NSCoder *)coder {
    return YES;
}

- (BOOL) application:(UIApplication *)application shouldRestoreApplicationState:(NSCoder *)coder {
    NSString *restorationBundleVersion = [coder decodeObjectForKey:UIApplicationStateRestorationBundleVersionKey];
    NSString* applicationBundleVersion = [[NSBundle mainBundle] infoDictionary][(id)kCFBundleVersionKey];
    return [VersionComparator isVersion: restorationBundleVersion greaterThanOrEqualToVersion: applicationBundleVersion];
}

@end
