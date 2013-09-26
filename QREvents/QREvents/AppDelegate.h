//
//  AppDelegate.h
//  QREvents
//
//  Created by Paul De Lange on 25/09/13.
//  Copyright (c) 2013 Toshimoto Sakai. All rights reserved.
//

#import <UIKit/UIKit.h>

extern NSString* kApplicationResetNotification;

@interface AppDelegate : UIResponder <UIApplicationDelegate>

@property (strong, nonatomic) UIWindow *window;
@property (strong, nonatomic) RKObjectManager* objectManager;

- (RKObjectManager*) objectManagerWithBaseURL: (NSURL*) baseURL andEventName: (NSString*) uniqueEventName;

- (void) showConnectionViewController;
- (void) reset;

@end
