//
//  CoreDataStack.h
//  pm25
//
//  Created by Paul De Lange on 28/02/14.
//  Copyright (c) 2014 Chesterford. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface CoreDataStack : NSObject

+ (instancetype) stackWithStoreFilename: (NSString*) storeFilename;

- (BOOL) save;

- (NSManagedObjectContext*) persistentStoreManagedObjectContext;
- (NSManagedObjectContext*) mainQueueManagedObjectContext;
- (NSURL*) storeURL;

@end
