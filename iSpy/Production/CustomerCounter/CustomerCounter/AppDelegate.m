//
//  AppDelegate.m
//  CustomerCounter
//
//  Created by Paul de Lange on 20/04/2014.
//  Copyright (c) 2014 Chesterford. All rights reserved.
//

#import "AppDelegate.h"
#import "SettingsViewController.h"

@implementation AppDelegate

#pragma mark - NSObject
+ (void) initialize {
    NSDictionary* params = @{ NSUserDefaultsSlideShowIntervalKey : @(DEFAULT_SLIDESHOW_INTERVAL_SECS)};
    [[NSUserDefaults standardUserDefaults] registerDefaults: params];
    [[NSUserDefaults standardUserDefaults] synchronize];
}

#pragma mark - UIApplicationDelegate
- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions
{
    return YES;
}

@end
