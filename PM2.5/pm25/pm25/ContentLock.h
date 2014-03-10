//
//  ContentLock.h
//  pm25
//
//  Created by Paul De Lange on 28/02/14.
//  Copyright (c) 2014 Chesterford. All rights reserved.
//

#import <Foundation/Foundation.h>

extern NSString * const kContentUnlockProductIdentifier;
extern NSString * const kContentUnlockedNotification;

typedef void (^kContentLockRemovedHandler)(NSError* error);

@interface ContentLock : NSObject

+ (BOOL) unlockWithCompletion: (kContentLockRemovedHandler) completionHandler;
+ (BOOL) lock;

+ (BOOL) tryLock;

@end
