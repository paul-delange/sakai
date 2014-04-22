//
//  CoreDataStack.m
//  CustomerCounter
//
//  Created by Paul De Lange on 28/02/14.
//  Copyright (c) 2014 Chesterford. All rights reserved.
//

#import "CoreDataStack.h"

#import <CoreData/CoreData.h>

#include <objc/runtime.h>

#if TARGET_OS_IPHONE
#define SEARCH_PATH_FROM_APPLE_GUIDELINES   NSDocumentDirectory
#else
#define SEARCH_PATH_FROM_APPLE_GUIDELINES   NSDocumentDirectory
#endif

#define     ASSOCIATIVE_KEY_DATA_STACK      "core.data.stack"

@interface NSManagedObjectContext (CoreDataStackInternal)
@property (strong, nonatomic) CoreDataStack* stack;
@end

@interface CoreDataStack ()

@property (strong, nonatomic) NSManagedObjectModel* managedObjectModel;
@property (strong, nonatomic) NSManagedObjectContext* mainQueueManagedObjectContext;
@property (strong, nonatomic) NSManagedObjectContext* persistentStoreManagedObjectContext;

@property (strong) NSPersistentStore* dataStore;
@property (strong, nonatomic) NSPersistentStoreCoordinator* persistentStoreCoordinator;

@end

@implementation CoreDataStack

+ (instancetype) initAppDomain:(NSString *)appDomain userDomain:(NSString *)userDomain {
    return [[self alloc] initAppDomain: appDomain userDomain: userDomain];
}

- (instancetype) initAppDomain: (NSString*) appDomain userDomain: (NSString*) userDomain {
    NSParameterAssert([NSThread isMainThread]);
    
    self = [super init];
    if( self ) {
        
        //1. Create the managed object model
        _managedObjectModel = [NSManagedObjectModel mergedModelFromBundles: nil];
        
        //2. Create the persistent store coordinator
        NSDictionary* readwriteOptions = @{
                                           NSMigratePersistentStoresAutomaticallyOption : @YES,
                                           NSInferMappingModelAutomaticallyOption : @YES
                                           };
        
#if DEBUG
        readwriteOptions = @{
                             NSMigratePersistentStoresAutomaticallyOption : @YES,
                             NSInferMappingModelAutomaticallyOption : @YES,
                             NSSQLitePragmasOption : @{ @"journal_mode" : @"DELETE" }
#if USE_CORE_DATA_CLOUD
                             , NSPersistentStoreUbiquitousContentNameKey : kAppName()
#endif
                             };
#endif
        
        NSPersistentStoreCoordinator* psc = [[NSPersistentStoreCoordinator alloc] initWithManagedObjectModel: _managedObjectModel];
        
        //3. Add the metadata store
        NSSearchPathDirectory domain = SEARCH_PATH_FROM_APPLE_GUIDELINES;
        NSArray *paths = NSSearchPathForDirectoriesInDomains(domain, NSUserDomainMask, YES);
        NSString* writeableDirectoryPath = ([paths count] > 0) ? [paths objectAtIndex:0] : nil;
        
        NSError* error;
        
        if( appDomain ) {
            NSString* writeableStoreFileName = [NSString stringWithFormat: @"%@.sqlite", appDomain];
            NSString* writeableStorePath = [writeableDirectoryPath stringByAppendingPathComponent: writeableStoreFileName];
            NSURL* writeableStoreURL = [NSURL fileURLWithPath: writeableStorePath];
            
            [psc addPersistentStoreWithType: NSSQLiteStoreType
                              configuration: nil
                                        URL: writeableStoreURL
                                    options: readwriteOptions
                                      error: &error];
            DLogError(error);
            
            [writeableStoreURL setResourceValue: @YES forKey: NSURLIsExcludedFromBackupKey error: &error];
            DLogError(error);
        }
        
        //4. Add the data store
        if( userDomain ) {
            NSMutableDictionary* mutableOptions = [readwriteOptions mutableCopy];
            mutableOptions[NSSQLitePragmasOption] = @{ @"journal_mode" : @"DELETE" };
            
            [mutableOptions removeObjectForKey: NSPersistentStoreUbiquitousContentNameKey];
            
            NSString* readableStoreFileName = [NSString stringWithFormat: @"%@.sqlite", userDomain];
            
#if TARGET_OS_IPHONE
            NSURL* readableStoreURL = [[NSBundle mainBundle] URLForResource: readableStoreFileName withExtension: nil];
            mutableOptions[NSReadOnlyPersistentStoreOption] = @YES;
#else
            NSString* readableStorePath = [writeableDirectoryPath stringByAppendingPathComponent: readableStoreFileName];
            if( [[NSFileManager defaultManager] fileExistsAtPath: readableStorePath] ) {
                [[NSFileManager defaultManager] removeItemAtPath: readableStorePath
                                                           error: &error];
                DLogError(error);
            }
            
            NSString* supportPath = [NSString stringWithFormat: @".%@_SUPPORT", userDomain];
            NSString* readableSupportPath = [writeableDirectoryPath stringByAppendingPathComponent: supportPath];
            if( [[NSFileManager defaultManager] fileExistsAtPath: readableSupportPath] ) {
                [[NSFileManager defaultManager] removeItemAtPath: readableSupportPath
                                                           error: &error];
                DLogError(error);
            }
            
            
            NSURL* readableStoreURL = [NSURL fileURLWithPath: readableStorePath];
#endif
            NSDictionary* readOptions = mutableOptions;
            _dataStore = [psc addPersistentStoreWithType: NSSQLiteStoreType
                                           configuration: userDomain
                                                     URL: readableStoreURL
                                                 options: readOptions
                                                   error: &error];
            DLogError(error);
        }
        
        _persistentStoreCoordinator = psc;
        
        self.persistentStoreManagedObjectContext = [[NSManagedObjectContext alloc] initWithConcurrencyType: NSPrivateQueueConcurrencyType];
        self.persistentStoreManagedObjectContext.persistentStoreCoordinator = _persistentStoreCoordinator;
        self.persistentStoreManagedObjectContext.mergePolicy = NSMergeByPropertyStoreTrumpMergePolicy;
        self.persistentStoreManagedObjectContext.undoManager = nil;
        
        self.mainQueueManagedObjectContext = [[NSManagedObjectContext alloc] initWithConcurrencyType: NSMainQueueConcurrencyType];
        self.mainQueueManagedObjectContext.parentContext = self.persistentStoreManagedObjectContext;
        self.mainQueueManagedObjectContext.mergePolicy = NSMergeByPropertyStoreTrumpMergePolicy;
        self.mainQueueManagedObjectContext.undoManager = nil;
        
        [[NSNotificationCenter defaultCenter] addObserver: self
                                                 selector: @selector(handleManagedObjectContextDidSaveNotification:)
                                                     name: NSManagedObjectContextDidSaveNotification
                                                   object: self.persistentStoreManagedObjectContext];
        
        self.mainQueueManagedObjectContext.stack = self;
        self.persistentStoreManagedObjectContext.stack = self;
        
#if USE_CORE_DATA_CLOUD
        [[NSNotificationCenter defaultCenter] addObserver:self
                                                 selector:@selector(storesWillChange:)
                                                     name:NSPersistentStoreCoordinatorStoresWillChangeNotification
                                                   object:self.persistentStoreCoordinator];
        
        [[NSNotificationCenter defaultCenter] addObserver:self
                                                 selector:@selector(storesDidChange:)
                                                     name:NSPersistentStoreCoordinatorStoresDidChangeNotification
                                                   object:self.persistentStoreCoordinator];
        
        [[NSNotificationCenter defaultCenter] addObserver:self
                                                 selector:@selector(persistentStoreDidImportUbiquitousContentChanges:)
                                                     name:NSPersistentStoreDidImportUbiquitousContentChangesNotification
                                                   object:self.persistentStoreCoordinator];
#endif
    }
    
    return self;
}

- (NSURL*) storeURL {
    for(NSPersistentStore* store in self.persistentStoreCoordinator.persistentStores) {
        if( [store.type isEqualToString: NSSQLiteStoreType] ) {
            return [self.persistentStoreCoordinator URLForPersistentStore: store];
        }
    }
    
    return nil;
}

- (NSManagedObjectContext*) mainQueueManagedObjectContext {
    NSParameterAssert([NSThread isMainThread]);
    return _mainQueueManagedObjectContext;
}

- (BOOL) save {
    NSParameterAssert([NSThread isMainThread]);
    
    NSManagedObjectContext* moc = self.mainQueueManagedObjectContext;
    
    while (moc) {
        [moc performBlockAndWait: ^{
            NSError* error;
            [moc save: &error];
            DLogError(error);
        }];
        
        moc = moc.parentContext;
    }
    
    return YES;
}

#pragma mark - Notifications
- (void)handleManagedObjectContextDidSaveNotification:(NSNotification *)notification {
    NSAssert(notification.object == self.persistentStoreManagedObjectContext, @"Received NSManagedObjectContextDidSaveNotification on an unexpected context: %@", notification.object);
    
    if( self.mergeNotificationBlock ) {
        self.mergeNotificationBlock(notification);
    }
    
    [self.mainQueueManagedObjectContext performBlock: ^{
        [self.mainQueueManagedObjectContext mergeChangesFromContextDidSaveNotification: notification];
    }];
}

- (void) dealloc {
    [[NSNotificationCenter defaultCenter] removeObserver: self];
}

@end

@implementation NSManagedObjectContext (CoreDataStack)

- (BOOL) threadSafeSave: (__autoreleasing NSError**) error {
    CoreDataStack* stack = self.stack;
    NSParameterAssert(stack);
    return [stack save];
}

- (void) setStack:(CoreDataStack *)stack {
    objc_setAssociatedObject(self, ASSOCIATIVE_KEY_DATA_STACK, stack, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
}

- (CoreDataStack*) stack {
    return objc_getAssociatedObject(self, ASSOCIATIVE_KEY_DATA_STACK);
}

- (NSFetchRequest *)fetchRequestFromTemplateWithName:(NSString *)name substitutionVariables:(NSDictionary *)variables {
    CoreDataStack* stack = self.stack;
    NSParameterAssert(stack);
    
    NSManagedObjectModel* mom = stack.managedObjectModel;
    return [mom fetchRequestFromTemplateWithName: name substitutionVariables: variables];
}

@end
