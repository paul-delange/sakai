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

@implementation AppDelegate

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
        NSString* listPath = @"particpants";
        NSString* individualPath = @"participants/:user_id";
        
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
- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions
{
    // Override point for customization after application launch.
    return YES;
}

- (void)applicationWillResignActive:(UIApplication *)application
{
    // Sent when the application is about to move from active to inactive state. This can occur for certain types of temporary interruptions (such as an incoming phone call or SMS message) or when the user quits the application and it begins the transition to the background state.
    // Use this method to pause ongoing tasks, disable timers, and throttle down OpenGL ES frame rates. Games should use this method to pause the game.
}

- (void)applicationDidEnterBackground:(UIApplication *)application
{
    // Use this method to release shared resources, save user data, invalidate timers, and store enough application state information to restore your application to its current state in case it is terminated later.
    // If your application supports background execution, this method is called instead of applicationWillTerminate: when the user quits.
}

- (void)applicationWillEnterForeground:(UIApplication *)application
{
    // Called as part of the transition from the background to the inactive state; here you can undo many of the changes made on entering the background.
}

- (void)applicationDidBecomeActive:(UIApplication *)application
{
    // Restart any tasks that were paused (or not yet started) while the application was inactive. If the application was previously in the background, optionally refresh the user interface.
}

- (void)applicationWillTerminate:(UIApplication *)application
{
    // Called when the application is about to terminate. Save data if appropriate. See also applicationDidEnterBackground:.
}

@end
