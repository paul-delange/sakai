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
    
    
    [[NSNotificationCenter defaultCenter] postNotificationName: kApplicationResetNotification
                                                        object: nil
                                                      userInfo: nil];
}

- (RKObjectManager*) objectManagerWithBaseURL: (NSURL*) baseURL andEventName: (NSString*) uniqueEventName {
    __autoreleasing NSError* error;
    
    [AFNetworkActivityIndicatorManager sharedManager].enabled = YES;
    
    AFHTTPClient* client = [AFHTTPClient clientWithBaseURL: baseURL];
    NSParameterAssert(client);
    
    RKObjectManager* manager = [[RKObjectManager alloc] initWithHTTPClient: client];
    NSParameterAssert(manager);
    
    //Configure the local store
    RKManagedObjectStore* store;
    {
        NSManagedObjectModel* mom = [NSManagedObjectModel mergedModelFromBundles: nil];
        NSParameterAssert(mom);
        
        store = [[RKManagedObjectStore alloc] initWithManagedObjectModel: mom];
        NSParameterAssert(store);
        
        NSString* storeName = [uniqueEventName stringByAppendingPathExtension: @"sqlite"];
        NSString* storePath = [RKApplicationDataDirectory() stringByAppendingString: storeName];
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
        
        RKEntityMapping* getMapping = [RKEntityMapping mappingForEntityForName: NSStringFromClass([Participant class])
                                                          inManagedObjectStore: store];
        getMapping.identificationAttributes = @[@"primaryKey"];
        [getMapping addAttributeMappingsFromArray: @[
                                                     @"name"
                                                     ]];
        [getMapping addAttributeMappingsFromDictionary: @{
                                                          @"user_id": @"primaryKey",
                                                          @"entry_time" : @"entryTime",
                                                          @"exit_time" : @"exitTime"
                                                          }];
        
        
        RKObjectMapping* postMapping = [getMapping inverseMapping];
        
        NSIndexSet* successStatusCodes = RKStatusCodeIndexSetForClass(RKStatusCodeClassSuccessful);
        
        //TODO: Error codes...
        
        //GET participant list
        RKResponseDescriptor* listResponse = [RKResponseDescriptor responseDescriptorWithMapping: getMapping
                                                                                          method: RKRequestMethodGET
                                                                                     pathPattern: listPath
                                                                                         keyPath: nil
                                                                                     statusCodes: successStatusCodes];
        
        //GET participant
        RKResponseDescriptor* participantResponse = [RKResponseDescriptor responseDescriptorWithMapping: getMapping
                                                                                                 method: RKRequestMethodGET
                                                                                            pathPattern: individualPath
                                                                                                keyPath: nil
                                                                                            statusCodes: successStatusCodes];
        
        //PUT participant
        RKRequestDescriptor* createRequest = [RKRequestDescriptor requestDescriptorWithMapping: postMapping
                                                                                   objectClass: [Participant class]
                                                                                   rootKeyPath: nil
                                                                                        method: RKRequestMethodPUT];
        
        //POST participant
        RKRequestDescriptor* updateRequest = [RKRequestDescriptor requestDescriptorWithMapping: postMapping
                                                                                   objectClass: [Participant class]
                                                                                   rootKeyPath: nil
                                                                                        method: RKRequestMethodPOST];
        
        [manager addResponseDescriptorsFromArray: @[listResponse, participantResponse]];
        [manager addRequestDescriptorsFromArray: @[createRequest, updateRequest]];
    }
    
    return manager;
}

#pragma mark - UIApplicationDelegate
- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions {
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
