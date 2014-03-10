//
//  VersionComparator.h
//
//  Created by Dan Hanly on 12/06/2012.
//  Copyright (c) 2012 Celf Creative. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface VersionComparator : NSObject

+ (BOOL)isVersion:(NSString *)versionA greaterThanVersion:(NSString *)versionB;
+ (BOOL)isVersion:(NSString *)versionA greaterThanOrEqualToVersion:(NSString *)versionB;
+ (NSArray *)normaliseValuesFromArray:(NSArray *)array;

@end
