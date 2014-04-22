//
//  AppDelegate.m
//  CustomerCounter
//
//  Created by Paul de Lange on 20/04/2014.
//  Copyright (c) 2014 Chesterford. All rights reserved.
//

#import "AppDelegate.h"
#import "SettingsViewController.h"

#import "CoreDataStack.h"

@interface AppDelegate ()

@end

@implementation AppDelegate

- (CoreDataStack*) stack {
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        _stack = [CoreDataStack initAppDomain: @"Default" userDomain: nil];
    });
    return _stack;
}

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

NSManagedObjectContext * NSManagedObjectContextGetMainThreadContext(void) {
    NSCParameterAssert([NSThread isMainThread]);
    
    AppDelegate* delegate = (AppDelegate*)[[UIApplication sharedApplication] delegate];
    return delegate.stack.mainQueueManagedObjectContext;
}
