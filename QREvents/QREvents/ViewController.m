//
//  ViewController.m
//  QREvents
//
//  Created by Paul De Lange on 25/09/13.
//  Copyright (c) 2013 Toshimoto Sakai. All rights reserved.
//

#import "ViewController.h"
#import "AppDelegate.h"
#import "Participant.h"

#define kAlertViewTagCreateConnection   612321

@interface ViewController () <UIAlertViewDelegate> {
    RKObjectManager* _objectManager;
}

@end

@implementation ViewController

- (AppDelegate*) appDelegate {
    return  (AppDelegate*)[[UIApplication sharedApplication] delegate];
}

- (BOOL) readyToMakeRequests {
    if( _objectManager )
        return YES;
    else {
        NSString* candidateURLString = [self.baseURLField text];
        NSURL* candidateURL = [NSURL URLWithString: candidateURLString];
        if( candidateURL && candidateURL.scheme && candidateURL.host ) {
            
            NSString* format = @"You haven't connected to a server yet. Would you like to try to connect to '%@'?";
            NSString* msg = [NSString stringWithFormat: format, candidateURLString];
            
            UIAlertView* alert = [[UIAlertView alloc] initWithTitle: @"Hrm?"
                                                            message: msg
                                                           delegate: self
                                                  cancelButtonTitle: @"No"
                                                  otherButtonTitles: @"Yes", nil];
            alert.tag = kAlertViewTagCreateConnection;
            [alert show];
        }
        else {
            UIAlertView* alert = [[UIAlertView alloc] initWithTitle: @"You are not connected to a server yet."
                                                            message: @"First you need to enter a valid server URL in the field above"
                                                           delegate: self
                                                  cancelButtonTitle: @"OK"
                                                  otherButtonTitles: nil];
            [alert show];
        }
    }
    
    return NO;
}

- (IBAction)downloadListPushed:(id)sender {
    if( [self readyToMakeRequests] ) {
        [_objectManager getObjectsAtPath: kWebServiceListPath
                              parameters: nil
                                 success: ^(RKObjectRequestOperation *operation, RKMappingResult *mappingResult) {
                                     
                                     NSArray* objects = [mappingResult array];
                                     NSString* format = @"Successfully imported %d participants";
                                     UIAlertView* alert = [[UIAlertView alloc] initWithTitle: @"Success"
                                                                                     message: [NSString stringWithFormat: format, objects.count]
                                                                                    delegate: nil
                                                                           cancelButtonTitle: @"OK"
                                                                           otherButtonTitles: nil];
                                     [alert show];
                                     
                                     self.participantIdField.enabled = YES;
                                     
                                 } failure: ^(RKObjectRequestOperation *operation, NSError *error) {
                                     
                                     UIAlertView* alert = [[UIAlertView alloc] initWithTitle: @"Error"
                                                                                     message: [error localizedDescription]
                                                                                    delegate: nil
                                                                           cancelButtonTitle: @"OK"
                                                                           otherButtonTitles: nil];
                                     [alert show];
                                 }];
    }
}

- (IBAction)downloadParticipantPushed:(id)sender {
    if( [self readyToMakeRequests] ) {
        NSString* user_id = [self.participantIdField text];
        
        NSManagedObjectContext* context = [_objectManager.managedObjectStore mainQueueManagedObjectContext];
        NSFetchRequest* request = [NSFetchRequest fetchRequestWithEntityName: NSStringFromClass([Participant class])];
        [request setFetchLimit: 1];
        [request setPredicate: [NSPredicate predicateWithFormat: @"primaryKey = %@", user_id]];
        
        __autoreleasing NSError* error;
        NSArray* results = [context executeFetchRequest: request error: &error];
        if( error ) {
            UIAlertView* alert = [[UIAlertView alloc] initWithTitle: @"CoreData Error"
                                                            message: [error localizedDescription]
                                                           delegate: nil
                                                  cancelButtonTitle: @"OK"
                                                  otherButtonTitles: nil];
            [alert show];
        }
        else {
            if( results.count ) {
                Participant* participant = results.lastObject;
                
                [_objectManager getObject: participant
                                     path: kWebServiceIndividualPath
                               parameters: nil
                                  success: ^(RKObjectRequestOperation *operation, RKMappingResult *mappingResult) {
                                      
                                      //TODO:
                                      
                                  } failure: ^(RKObjectRequestOperation *operation, NSError *error) {
                                      UIAlertView* alert = [[UIAlertView alloc] initWithTitle: @"Error"
                                                                                      message: [error localizedDescription]
                                                                                     delegate: nil
                                                                            cancelButtonTitle: @"OK"
                                                                            otherButtonTitles: nil];
                                      [alert show];
                                  }];
            }
            else {
                NSString* format = @"Could not find user '%@' in the database";
                UIAlertView* alert = [[UIAlertView alloc] initWithTitle: @"Error"
                                                                message: [NSString stringWithFormat: format, user_id]
                                                               delegate: nil
                                                      cancelButtonTitle: @"OK"
                                                      otherButtonTitles: nil];
                [alert show];
            }
        }
        
    }
}

- (IBAction)modifyAndUpdatePushed:(id)sender {
    if( [self readyToMakeRequests] ) {
        //TODO
    }
}

- (IBAction)createRandomPushed:(id)sender {
    if( [self readyToMakeRequests] ) {
        NSManagedObjectContext* context = [_objectManager.managedObjectStore mainQueueManagedObjectContext];
        Participant* newParticipant = (Participant*)[context insertNewObjectForEntityForName: NSStringFromClass([Participant class])];
        
        NSArray* names = @[@"としもと酒井", @"Paul de Lange", @"Barrack Obama", @"John Lennon", @"ところジョージ", @"イライラ山方", @"安倍晋三"];
        NSUInteger nameIndex = arc4random() % names.count;
        newParticipant.name = names[nameIndex];
        newParticipant.entryTime = [NSDate date];
        newParticipant.exitTime = [NSDate dateWithTimeIntervalSinceNow: arc4random() % (int)DBL_MAX];
        
        __autoreleasing NSError* error;
        [context saveToPersistentStore: &error];
        
        [_objectManager putObject: newParticipant
                             path: kWebServiceListPath
                       parameters: nil
                          success: ^(RKObjectRequestOperation *operation, RKMappingResult *mappingResult) {
                              Participant* createdParticipant = [[mappingResult array] lastObject];
                              
                              NSString* format = @"'%@' now has user_id '%d'";
                              UIAlertView* alert = [[UIAlertView alloc] initWithTitle: @"Success"
                                                                              message: [NSString stringWithFormat: format, createdParticipant.name, createdParticipant.primaryKey]
                                                                             delegate: nil
                                                                    cancelButtonTitle: @"OK"
                                                                    otherButtonTitles: nil];
                              [alert show];
                              
                          } failure: ^(RKObjectRequestOperation *operation, NSError *error) {
                              UIAlertView* alert = [[UIAlertView alloc] initWithTitle: @"Error"
                                                                              message: [error localizedDescription]
                                                                             delegate: nil
                                                                    cancelButtonTitle: @"OK"
                                                                    otherButtonTitles: nil];
                              [alert show];
                          }];
    }
}

- (IBAction)resetPushed:(id)sender {
    RKManagedObjectStore* store = _objectManager.managedObjectStore;
    NSPersistentStoreCoordinator* psc = store.persistentStoreCoordinator;
    
    NSError *localError;
    for (NSPersistentStore *persistentStore in psc.persistentStores) {
        NSURL *URL = [psc URLForPersistentStore:persistentStore];
        BOOL success = [psc removePersistentStore:persistentStore error:&localError];
        if (success) {
            if ([URL isFileURL]) {
                if (![[NSFileManager defaultManager] removeItemAtURL:URL error:&localError]) {
                    NSAssert(!localError, @"Could not delete persistent store (%@): %@", URL, localError);
                    return;
                }
            }
        }
    }
    
    [RKManagedObjectStore setDefaultStore: nil];
    [RKObjectManager setSharedManager: nil];
    
    _objectManager = nil;
    
    self.baseURLField.enabled = YES;
    self.baseURLField.text = @"";
    self.participantIdField.text = @"";
    self.participantIdField.enabled = NO;
}

#pragma mark - UIAlertViewDelegate
- (void) alertView:(UIAlertView *)alertView clickedButtonAtIndex:(NSInteger)buttonIndex {
    switch (alertView.tag) {
        case kAlertViewTagCreateConnection:
        {
            if( buttonIndex != alertView.cancelButtonIndex ) {
                NSString* candidateURLString = [self.baseURLField text];
                NSURL* candidateURL = [NSURL URLWithString: candidateURLString];
                NSString* dbName = [NSString stringWithFormat: @"%d", [candidateURLString hash]];
                
                _objectManager = [[self appDelegate] objectManagerWithBaseURL: candidateURL andEventName: dbName];
                self.baseURLField.enabled = NO;
            
                UIAlertView* alert = [[UIAlertView alloc] initWithTitle: @"It's done"
                                                                message: nil
                                                               delegate: nil
                                                      cancelButtonTitle: @"OK"
                                                      otherButtonTitles: nil];
                [alert show];
            }
            
            break;
        }
        default:
            break;
    }
}

#pragma mark - UIViewController
- (void)viewDidLoad
{
    [super viewDidLoad];
	// Do any additional setup after loading the view, typically from a nib.
    self.participantIdField.enabled = NO;
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

@end
