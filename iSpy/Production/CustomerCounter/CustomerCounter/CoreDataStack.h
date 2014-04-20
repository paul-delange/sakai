//
//  CoreDataStack.h
//  CustomerCounter
//
//  Created by Paul De Lange on 28/02/14.
//  Copyright (c) 2014 Chesterford. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>

typedef BOOL (^MergeChangesFromContextDidSaveNotification)(NSNotification* notification);

extern NSString * const NSManagedObjectContextLocaleDidChangeNotification;

@interface CoreDataStack : NSObject

/** Create a thread safe, sql backed data stack. This method will merge any scheme models found in the app bundle. It will create two persistent stores to back the contexts.
 
 The first store is for application metadata that is not localizable and will be optimized for write access. This database will not be seeded and will exist in the app library directory (iOS) or the app data directory (OSX).
 
 The second store is for localizable app data that can be changed without modifying the first store. This database will be seeded from the app bundle without copying to another directory.
 
 @param appDomain The configuration name for the app metadata store
 @param userDomain The configuration name for the app data store
 
 */
+ (instancetype) initAppDomain: (NSString*) appDomain userDomain: (NSString*) userDomain;

@property (copy, nonatomic) MergeChangesFromContextDidSaveNotification mergeNotificationBlock;

/** Safely propogate a save from the main thread to the database
 
 @return YES if successful
 
 */
- (BOOL) save;

/** The private database context
 
 @warning Never use on the main thread
 */
- (NSManagedObjectContext*) persistentStoreManagedObjectContext;

/** The main thread context
 */
- (NSManagedObjectContext*) mainQueueManagedObjectContext;

/** The store URL in the app data directory (OSX) or library directory (iOS) */
- (NSURL*) storeURL;

@end

/** Category to add save functionality to NSManagedObjectContext directly */
@interface NSManagedObjectContext (CoreDataStack)

/** Save a managed object context in a thread safe manner */
- (BOOL) threadSafeSave: (__autoreleasing NSError**) error;

/** Access Xcode created fetch templates with an optional substitution dictionary.
 
 //TODO: It seems mogenerator (somewhat) supports this automatically. Look inside the _Entity classes for the +fetch... methods. It seems the variable types are not correctly predicted though. It also relies on the managed object context having a persistent store coordinator but our main context does not have one.
 
 @param name The fetch request 'name' specified in the Xcode Core Data editor
 @param variables The substitution variables or nil
 @return The fetch request ready to execute
 
 */
- (NSFetchRequest *)fetchRequestFromTemplateWithName:(NSString *)name substitutionVariables:(NSDictionary *)variables;

@end
