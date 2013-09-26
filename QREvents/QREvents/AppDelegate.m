//
//  AppDelegate.m
//  QREvents
//
//  Created by Paul De Lange on 25/09/13.
//  Copyright (c) 2013 Toshimoto Sakai. All rights reserved.
//

#import "AppDelegate.h"
#import "Participant.h"

#import <RestKit/RKManagedObjectStore.h>

#define kSegueConnectModal @"ConnectSegue"

NSString* kApplicationResetNotification =  @"ApplicationReset";

@implementation AppDelegate

- (void) showConnectionViewController {
    UINavigationController* navigationController = (UINavigationController*)self.window.rootViewController;
    UIViewController* topLevelController = navigationController.viewControllers.lastObject;
    NSParameterAssert(!topLevelController.presentedViewController);
    [topLevelController performSegueWithIdentifier: kSegueConnectModal sender: nil];
}

- (void) reset {
    NSParameterAssert([NSThread isMainThread]);
    
    //Do the tricky stuff here
    self.objectManager = nil;
    [RKObjectManager setSharedManager: nil];
    [RKManagedObjectStore setDefaultStore: nil];
    
    [[NSNotificationCenter defaultCenter] postNotificationName: kApplicationResetNotification
                                                        object: nil
                                                      userInfo: nil];
}

- (RKObjectManager*) objectManagerWithBaseURL: (NSURL*) baseURL andEventName: (NSString*) uniqueEventName {
    __autoreleasing NSError* error;
    
    [AFNetworkActivityIndicatorManager sharedManager].enabled = YES;
    
    AFHTTPClient* client = [AFHTTPClient clientWithBaseURL: baseURL];
    NSParameterAssert(client);
    
#if USING_PARSE_DOT_COM
    [client setDefaultHeader: @"X-Parse-Application-Id" value: @"ZThZP9VzlTd9YiLzeX1LP5QlstqRkRzWI95qfOGB"];
    [client setDefaultHeader: @"X-Parse-REST-API-Key" value: @"81WAqdMD2xtOo93FMtTFnGX5o3a6LUf5z19RgXPM"];
#endif
    
    RKObjectManager* manager = [[RKObjectManager alloc] initWithHTTPClient: client];
    NSParameterAssert(manager);
    manager.requestSerializationMIMEType = RKMIMETypeJSON;
    
    //Configure the local store
    RKManagedObjectStore* store;
    {
        NSManagedObjectModel* mom = [NSManagedObjectModel mergedModelFromBundles: nil];
        NSParameterAssert(mom);
        
        store = [[RKManagedObjectStore alloc] initWithManagedObjectModel: mom];
        NSParameterAssert(store);
        
        NSString* storeName = [uniqueEventName stringByAppendingPathExtension: @"sqlite"];
        NSString* storePath = [RKApplicationDataDirectory() stringByAppendingPathComponent: storeName];
        [store addSQLitePersistentStoreAtPath: storePath
                       fromSeedDatabaseAtPath: nil
                            withConfiguration: nil
                                      options: nil
                                        error: &error];
        NSAssert(!error, @"Error creating persistent store: %@", error);
        
        [store createManagedObjectContexts];
        
        manager.managedObjectStore = store;
    }
    
    //Configure the endpoints
    {
        NSString* listPath = kWebServiceListPath;
        NSString* individualPath = kWebServiceIndividualPath;
        NSString* serverPrimaryKeyName = USING_PARSE_DOT_COM ? @"objectId" : @"user_id";
        
        RKEntityMapping* getMapping = [RKEntityMapping mappingForEntityForName: NSStringFromClass([Participant class])
                                                          inManagedObjectStore: store];
        getMapping.identificationAttributes = @[@"primaryKey"];
        [getMapping addAttributeMappingsFromArray: @[
                                                     @"name",
                                                     @"updatedAt"
                                                     ]];
        [getMapping addAttributeMappingsFromDictionary: @{
                                                          serverPrimaryKeyName : @"primaryKey",
                                                          @"entry_time" : @"entryTime",
                                                          @"exit_time" : @"exitTime"
                                                          }];
        [getMapping setModificationAttributeForName: @"updatedAt"];
        getMapping.deletionPredicate = [NSPredicate predicateWithFormat: @"primaryKey == nil"];
        
        RKObjectMapping* postMapping = [getMapping inverseMappingWithPropertyMappingsPassingTest: ^BOOL(RKPropertyMapping *propertyMapping) {
            return ![propertyMapping.sourceKeyPath isEqualToString: serverPrimaryKeyName];
        }];
        
        RKObjectMapping* putMapping = [getMapping inverseMapping];
        RKObjectMapping* errorMapping = [RKObjectMapping mappingForClass: [RKErrorMessage class]];
        [errorMapping addPropertyMapping: [RKAttributeMapping attributeMappingFromKeyPath: @"msg" toKeyPath: @"errorMessage"]];
        
        NSIndexSet* successStatusCodes = RKStatusCodeIndexSetForClass(RKStatusCodeClassSuccessful);
        NSIndexSet* creationFailedCodes = RKStatusCodeIndexSetForClass(RKStatusCodeClassClientError);
        
        //GET participant list
        RKResponseDescriptor* listResponse = [RKResponseDescriptor responseDescriptorWithMapping: getMapping
                                                                                          method: RKRequestMethodGET
                                                                                     pathPattern: listPath
                                                                                         keyPath: USING_PARSE_DOT_COM ? @"results" : nil
                                                                                     statusCodes: successStatusCodes];
        
        //GET participant
        RKResponseDescriptor* participantResponse = [RKResponseDescriptor responseDescriptorWithMapping: getMapping
                                                                                                 method: RKRequestMethodGET
                                                                                            pathPattern: individualPath
                                                                                                keyPath: nil
                                                                                            statusCodes: successStatusCodes];
        
        //PUT participant
        RKRequestDescriptor* createRequest = [RKRequestDescriptor requestDescriptorWithMapping: putMapping
                                                                                   objectClass: [Participant class]
                                                                                   rootKeyPath: nil
                                                                                        method: RKRequestMethodPUT];
        
        RKResponseDescriptor* createResponse = [RKResponseDescriptor responseDescriptorWithMapping: getMapping
                                                                                            method: RKRequestMethodPOST
                                                                                       pathPattern: kWebServiceListPath
                                                                                           keyPath: nil
                                                                                       statusCodes: successStatusCodes];
        //POST participant
        RKRequestDescriptor* updateRequest = [RKRequestDescriptor requestDescriptorWithMapping: postMapping
                                                                                   objectClass: [Participant class]
                                                                                   rootKeyPath: nil
                                                                                        method: RKRequestMethodPOST];
        
        //Errors
        RKResponseDescriptor* errorResponse = [RKResponseDescriptor responseDescriptorWithMapping: errorMapping
                                                                                           method: RKRequestMethodAny
                                                                                      pathPattern: nil
                                                                                          keyPath: @"error"
                                                                                      statusCodes: creationFailedCodes];
        
        [manager addResponseDescriptorsFromArray: @[listResponse, participantResponse, createResponse, errorResponse]];
        [manager addRequestDescriptorsFromArray: @[createRequest, updateRequest]];
    }
    
    return manager;
}

#pragma mark - UIApplicationDelegate
- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions {
    
    NSString* uniqueEventName = kAppName();
    NSString* storeName = [uniqueEventName stringByAppendingPathExtension: @"sqlite"];
    NSString* storePath = [RKApplicationDataDirectory() stringByAppendingPathComponent: storeName];
    if( [[NSFileManager defaultManager] fileExistsAtPath: storePath] ) {
        __autoreleasing NSError* error;
        [[NSFileManager defaultManager] removeItemAtPath: storePath error: &error];
        NSAssert(!error, @"Could not delete old database at %@. Error %@", storePath, error);
    }
    
    return YES;
}

- (void)applicationWillResignActive:(UIApplication *)application {
    UINavigationController* navigationController = (UINavigationController*)self.window.rootViewController;
    UIViewController* topLevelController = navigationController.viewControllers.lastObject;
    [topLevelController dismissViewControllerAnimated: NO completion: nil];
}

- (void)applicationDidBecomeActive:(UIApplication *)application {
    if( !self.objectManager ) {
        [self showConnectionViewController];
    }
}

@end
