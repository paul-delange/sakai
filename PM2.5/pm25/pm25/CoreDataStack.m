//
//  CoreDataStack.m
//  pm25
//
//  Created by Paul De Lange on 28/02/14.
//  Copyright (c) 2014 Chesteford. All rights reserved.
//

#import "CoreDataStack.h"

#import <CoreData/CoreData.h>


void SetExcludeFromBackupAttributeForItemAtPath(NSString *path)
{
    NSCParameterAssert(path);
    NSCAssert([[NSFileManager defaultManager] fileExistsAtPath:path], @"Cannot set Exclude from Backup attribute for non-existant item at path: '%@'", path);
    
    NSError *error = nil;
    NSURL *URL = [NSURL fileURLWithPath:path];
    
    BOOL success = [URL setResourceValue:@(YES) forKey:NSURLIsExcludedFromBackupKey error:&error];
    if (!success) {
        //DLogError(error);
    }
}

@interface CoreDataStack ()

- (id) initWithStoreFileName: (NSString*) storeFileName;
+ (NSPersistentStoreCoordinator*) createPersistentStoreCoordinator: (NSManagedObjectModel*) model atPath: (NSString*) storePath;

@property (strong, nonatomic) NSManagedObjectModel* managedObjectModel;
@property (strong, nonatomic) NSManagedObjectContext* mainQueueManagedObjectContext;
@property (strong, nonatomic) NSManagedObjectContext* persistentStoreManagedObjectContext;
@property (strong, nonatomic) NSPersistentStoreCoordinator* persistentStoreCoordinator;

@end

@implementation CoreDataStack

+ (instancetype) stackWithStoreFilename: (NSString*) storeFilename {
    return [[self alloc] initWithStoreFileName: storeFilename];
}

- (id) initWithStoreFileName: (NSString*) storeFileName {
    NSParameterAssert([NSThread isMainThread]);
    
    if( !storeFileName )
        storeFileName = @"data.sqlite";
    
    self = [super init];
    if( self ) {
        
#if TARGET_OS_IPHONE
        NSSearchPathDirectory domain = NSLibraryDirectory;
#else
        NSSearchPathDirectory domain = NSDocumentDirectory;
#endif
        NSArray *paths = NSSearchPathForDirectoriesInDomains(domain, NSUserDomainMask, YES);
        
        NSString* storeDirectoryPath = ([paths count] > 0) ? [paths objectAtIndex:0] : nil;
        NSString* storeFilePath = [storeDirectoryPath stringByAppendingPathComponent: storeFileName];
        
#if TARGET_OS_IPHONE
        if( ![[NSFileManager defaultManager] fileExistsAtPath: storeFilePath] ) {
            if( [[NSBundle mainBundle] pathForResource: storeFileName ofType: nil] ) {
                //Have a seed db
                NSError* error = nil;
                [[NSFileManager defaultManager] copyItemAtPath: [[NSBundle mainBundle] pathForResource: storeFileName ofType: nil]
                                                        toPath: storeFilePath
                                                         error: &error];
                //DLogError(error);
                
                SetExcludeFromBackupAttributeForItemAtPath(storeFilePath);
            }
        }
#else
        if( [[NSFileManager defaultManager] fileExistsAtPath: storeFilePath] ) {
            NSError* error;
            [[NSFileManager defaultManager] removeItemAtPath: storeFilePath
                                                       error: &error];
            
           // DLogError(error);
        }
#endif
        _managedObjectModel = [NSManagedObjectModel mergedModelFromBundles: nil];
        _persistentStoreCoordinator = [[self class] createPersistentStoreCoordinator: _managedObjectModel atPath: storeFilePath];
        
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

+ (NSPersistentStoreCoordinator*) createPersistentStoreCoordinator:(NSManagedObjectModel *)model atPath:(NSString *)storePath {
    NSURL* storeURL = [NSURL fileURLWithPath: storePath];
    NSParameterAssert(model);
    NSParameterAssert(storeURL);
    
    NSError* error;
    
    /* In iOS7 there is a new WAL journal mode. This mode is better for databases that are frequently written to while being read. For us,
     the database is almost never written to and so it is better to use the rollback method. Because WAL is the default, we need to explicitly turn
     it off here.
     
     References:
     
     https://developer.apple.com/library/ios/releasenotes/DataManagement/WhatsNew_CoreData_iOS/
     http://www.sqlite.org/wal.html
     
     */
    NSDictionary* options = @{
                              NSSQLitePragmasOption : @{ @"journal_mode" : @"DELETE" },
                              NSMigratePersistentStoresAutomaticallyOption : @YES,
                              NSInferMappingModelAutomaticallyOption : @YES
                              };
    
    NSPersistentStoreCoordinator* psc = [[NSPersistentStoreCoordinator alloc] initWithManagedObjectModel: model];
    if([psc addPersistentStoreWithType: NSSQLiteStoreType configuration: nil URL: storeURL options: options error: &error] ) {
        return psc;
    }
    else {
        switch (error.code) {
            case NSMigrationError:
            case NSMigrationCancelledError:
            case NSMigrationMissingSourceModelError:
            case NSMigrationMissingMappingModelError:
            case NSMigrationManagerSourceStoreError:
            case NSMigrationManagerDestinationStoreError:
            case NSEntityMigrationPolicyError:
            case NSInferredMappingModelError:
            case NSExternalRecordImportError:
            default:
                break;
        }
        
        //DLogError(error);
        
        return nil;
    }
}

- (NSManagedObjectContext*) mainQueueManagedObjectContext {
#if !TARGET_OS_MAC
    NSParameterAssert([NSThread isMainThread]);
#endif
    return _mainQueueManagedObjectContext;
}

- (BOOL) save {
#if !TARGET_OS_MAC
    NSParameterAssert([NSThread isMainThread]);
#endif
    
    NSManagedObjectContext* moc = self.mainQueueManagedObjectContext;
    
    while (moc) {
        [moc performBlockAndWait: ^{
            NSError* error;
            [moc save: &error];
            //DLogError(error);
        }];
        
        moc = moc.parentContext;
    }
    
    return YES;
}

- (void) dealloc {
    [[NSNotificationCenter defaultCenter] removeObserver: self];
}

- (void)handleManagedObjectContextDidSaveNotification:(NSNotification *)notification {
    NSAssert(notification.object == self.persistentStoreManagedObjectContext, @"Received NSManagedObjectContextDidSaveNotification on an unexpected context: %@", notification.object);
    
    [self.mainQueueManagedObjectContext performBlock: ^{
        [self.mainQueueManagedObjectContext mergeChangesFromContextDidSaveNotification: notification];
    }];
}

@end
