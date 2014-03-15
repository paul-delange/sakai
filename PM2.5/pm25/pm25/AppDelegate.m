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
    [[UIApplication sharedApplication] setMinimumBackgroundFetchInterval: 60 * 60];
    
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
                                                            andTitle: NSLocalizedString(@"Version", @"")];
    
    container.menuItems = @[item1, item2, item3];
    
    if( [[NSUserDefaults standardUserDefaults] boolForKey: kUserDefaultsPushNotificationsEnabledKey] ) {
        [application registerForRemoteNotificationTypes: UIRemoteNotificationTypeAlert | UIRemoteNotificationTypeBadge | UIRemoteNotificationTypeSound];
    }
    else {
        [application unregisterForRemoteNotifications];
    }
    
    return YES;
}

- (void) applicationWillEnterForeground:(UIApplication *)application {
    application.applicationIconBadgeNumber = 0;
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

- (void) application:(UIApplication *)application performFetchWithCompletionHandler:(void (^)(UIBackgroundFetchResult))completionHandler {
    NSDictionary* lastUpdate = [[NSUserDefaults standardUserDefaults] objectForKey: kUserDefaultsLastUpdateKey];
    CGFloat lat = [lastUpdate[@"lat"] floatValue];
    CGFloat lon = [lastUpdate[@"lon"] floatValue];
    
    if( lat != 0 & lon != 0) {
        
        NSString* dataPath = [NSString stringWithFormat: @"http://api.airtrack.info/data/position?lat=%f&lon=%f", lat, lon];
        NSURL* dataURL = [NSURL URLWithString: dataPath];
        NSURLRequest* request = [NSURLRequest requestWithURL: dataURL];
        [NSURLConnection sendAsynchronousRequest: request
                                           queue: [NSOperationQueue currentQueue]
                               completionHandler: ^(NSURLResponse *response, NSData *data, NSError *connectionError) {
                                   if( connectionError ) {
                                        completionHandler(UIBackgroundFetchResultFailed);
                                   }
                                   else {
                                       id object = [NSJSONSerialization JSONObjectWithData: data options: 0 error: nil];
                                       if( [object objectForKey: @"pm25"] ) {  //Hope we are ok!
                                           [[NSUserDefaults standardUserDefaults] setObject: object forKey: kUserDefaultsLastUpdateKey];
                                           [[NSUserDefaults standardUserDefaults] setObject: [NSDate date] forKey: kUserDefaultsLastLocationUpdateTimeKey];
                                           [[NSUserDefaults standardUserDefaults] synchronize];
                                           
                                           NSUInteger value = [object[@"pm25"] integerValue];
                                           
                                           application.applicationIconBadgeNumber = value;
                                           
                                           completionHandler(UIBackgroundFetchResultNewData);
                                       }
                                       else {
                                           completionHandler(UIBackgroundFetchResultFailed);
                                       }
                                   }
                               }];
    }
    else {
        completionHandler(UIBackgroundFetchResultNoData);
    }
}

@end
