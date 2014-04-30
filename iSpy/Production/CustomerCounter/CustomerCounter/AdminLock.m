//
//  AdminLock.m
//  CustomerCounter
//
//  Created by Paul de Lange on 29/04/2014.
//  Copyright (c) 2014 Chesterford. All rights reserved.
//

#import "AdminLock.h"

NSString * kAdminLockPasswordChangedNotification = @"PasswordChangedNotification";
NSString * NSUserDefaultsHasResetPassword = @"ResetPassword";

@import Security;

static inline NSString* NSStringFromOSStatus(OSStatus status) {
    switch (status) {
        case errSecSuccess:
            return @"errSecSuccess : No error";
        case errSecUnimplemented:
            return @"errSecUnimplemented : Function or operation not implemented";
        case errSecParam:
            return @"errSecParam : One or more parameters passed to the function were not valid";
        case errSecAllocate:
            return @"errSecAllocate : Failed to allocate memory";
        case errSecNotAvailable:
            return @"errSecNotAvailable : No trust results are available";
        case errSecAuthFailed:
            return @"errSecAuthFailed : Authorization/Authentication failed";
        case errSecDuplicateItem:
            return @"errSecDuplicateItem : The item already exists";
        case errSecItemNotFound:
            return @"errSecItemNotFound : The item cannot be found";
        case errSecInteractionNotAllowed:
            return @"errSecInteractionNotAllowed : Interaction with the Security Server is not allowed";
        case errSecDecode:
            return @"errSecDecode : Unable to decode the provided data";
        default:
            return [NSString stringWithFormat: @"%d : Unknown OSStatus code", (int)status];
    }
}

@implementation AdminLock

+ (BOOL) lockWithPassword: (NSString*) password {
    if( [password length] ) {
        CFMutableDictionaryRef query = CFDictionaryCreateMutable(NULL, 5, NULL, NULL);
        
        CFDictionaryAddValue(query, kSecClass, kSecClassGenericPassword);
        CFDictionaryAddValue(query, kSecAttrAccount, CFSTR("CustomerCounter"));
        CFDictionaryAddValue(query, kSecAttrService, CFSTR("AdminLock"));
        CFDictionaryAddValue(query, kSecReturnData, kCFBooleanTrue);
        
        OSStatus status = SecItemCopyMatching(query, NULL);
        
        if( status == errSecSuccess ) {
            CFMutableDictionaryRef update = CFDictionaryCreateMutable(NULL, 2, NULL, NULL);
            
            CFDataRef data = (__bridge CFDataRef)[password dataUsingEncoding: NSUTF8StringEncoding];
            CFDictionaryAddValue(update, kSecValueData, data);
            
            CFDictionaryRemoveValue(query, kSecReturnData);
            
            status = SecItemUpdate(query, update);
            CFRelease(query);
            CFRelease(update);
            
            if( status != errSecSuccess ) {
                DLog(@"Error updating password: %@", NSStringFromOSStatus(status));
                return NO;
            }
        }
        else if( status == errSecItemNotFound ) {
            CFRelease(query);
            
            CFMutableDictionaryRef add = CFDictionaryCreateMutable(NULL, 5, NULL, NULL);
            
            CFDictionaryAddValue(add, kSecClass, kSecClassGenericPassword);
            CFDictionaryAddValue(add, kSecAttrAccount, CFSTR("CustomerCounter"));
            CFDictionaryAddValue(add, kSecAttrService, CFSTR("AdminLock"));
            
            CFDataRef data = (__bridge CFDataRef)[password dataUsingEncoding: NSUTF8StringEncoding];
            CFDictionaryAddValue(add, kSecValueData, data);
            
            status = SecItemAdd(add, NULL);
            CFRelease(add);
            
            if( status != errSecSuccess ) {
                DLog(@"Error adding initial coins to keychain: %@", NSStringFromOSStatus(status));
                return NO;
            }
        }
        else {
            CFRelease(query);
            
            DLog(@"Error adding : %@", NSStringFromOSStatus(status));
            return NO;
        }
    }
    else {
        CFMutableDictionaryRef query = CFDictionaryCreateMutable(NULL, 5, NULL, NULL);
        
        CFDictionaryAddValue(query, kSecClass, kSecClassGenericPassword);
        CFDictionaryAddValue(query, kSecAttrAccount, CFSTR("CustomerCounter"));
        CFDictionaryAddValue(query, kSecAttrService, CFSTR("AdminLock"));
        
        OSStatus status = SecItemDelete(query);
        CFRelease(query);
        
        if( status != errSecSuccess ) {
            DLog(@"Error deleting password: %@", NSStringFromOSStatus(status));
            return NO;
        }
    }

    [[NSNotificationCenter defaultCenter] postNotificationName: kAdminLockPasswordChangedNotification
                                                        object: nil];
    
    return YES;
}

+ (BOOL) unlockWithPassword: (NSString*) password {
    CFMutableDictionaryRef query = CFDictionaryCreateMutable(NULL, 5, NULL, NULL);
    
    CFDictionaryAddValue(query, kSecClass, kSecClassGenericPassword);
    CFDictionaryAddValue(query, kSecAttrAccount, CFSTR("CustomerCounter"));
    CFDictionaryAddValue(query, kSecAttrService, CFSTR("AdminLock"));
    CFDictionaryAddValue(query, kSecReturnData, kCFBooleanTrue);
    
    CFTypeRef result = NULL;
    OSStatus status = SecItemCopyMatching(query, &result);
    CFRelease(query);
    
    if( status == errSecSuccess ) {
        NSData* data = (__bridge_transfer NSData*)result;
        NSString* storedPassword = [[NSString alloc] initWithData: data encoding: NSUTF8StringEncoding];
        
        if( [storedPassword isEqualToString: password] ) {
            return YES;
        }
    }
    else {
        DLog(@"Failed to find password: %@", NSStringFromOSStatus(status));
    }
    
    return NO;
}

+ (BOOL) tryLock {
    CFMutableDictionaryRef query = CFDictionaryCreateMutable(NULL, 5, NULL, NULL);
    
    CFDictionaryAddValue(query, kSecClass, kSecClassGenericPassword);
    CFDictionaryAddValue(query, kSecAttrAccount, CFSTR("CustomerCounter"));
    CFDictionaryAddValue(query, kSecAttrService, CFSTR("AdminLock"));
    CFDictionaryAddValue(query, kSecReturnData, kCFBooleanTrue);
    
    CFTypeRef result = NULL;
    OSStatus status = SecItemCopyMatching(query, &result);
    CFRelease(query);
    
    if( result )
        CFRelease(result);
    
    return status == errSecSuccess;
}

+ (NSUInteger) lockLength {
    CFMutableDictionaryRef query = CFDictionaryCreateMutable(NULL, 5, NULL, NULL);
    
    CFDictionaryAddValue(query, kSecClass, kSecClassGenericPassword);
    CFDictionaryAddValue(query, kSecAttrAccount, CFSTR("CustomerCounter"));
    CFDictionaryAddValue(query, kSecAttrService, CFSTR("AdminLock"));
    CFDictionaryAddValue(query, kSecReturnData, kCFBooleanTrue);
    
    CFTypeRef result = NULL;
    OSStatus status = SecItemCopyMatching(query, &result);
    CFRelease(query);
    
    if( status == errSecSuccess ) {
        NSData* data = (__bridge_transfer NSData*)result;
        NSString* storedPassword = [[NSString alloc] initWithData: data encoding: NSUTF8StringEncoding];
        return [storedPassword length];
    }
    
    return 0;
}

#pragma mark - NSObject
+ (void) initialize {
    if( ![[NSUserDefaults standardUserDefaults] boolForKey: NSUserDefaultsHasResetPassword] ) {
        [self lockWithPassword: nil];
        
        [[NSUserDefaults standardUserDefaults] setBool: YES forKey: NSUserDefaultsHasResetPassword];
        [[NSUserDefaults standardUserDefaults] synchronize];
    }
}

@end
