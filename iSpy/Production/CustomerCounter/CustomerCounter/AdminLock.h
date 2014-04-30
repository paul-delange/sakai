//
//  AdminLock.h
//  CustomerCounter
//
//  Created by Paul de Lange on 29/04/2014.
//  Copyright (c) 2014 Chesterford. All rights reserved.
//

#import <Foundation/Foundation.h>

extern NSString * kAdminLockPasswordChangedNotification;

@interface AdminLock : NSObject

+ (BOOL) lockWithPassword: (NSString*) password;
+ (BOOL) unlockWithPassword: (NSString*) password;

+ (BOOL) tryLock; //Yes if admin lock is in effect

+ (NSUInteger) lockLength;

@end
