//
//  CreateViewController.m
//  QREvents
//
//  Created by Paul De Lange on 26/09/13.
//  Copyright (c) 2013 Toshimoto Sakai. All rights reserved.
//

#import "CreateViewController.h"
#import "AppDelegate.h"

#import "Participant.h"

#define     kSegueUnwind        @"UnwindCreateSegue"

@interface CreateViewController () <UITextFieldDelegate>

@end

@implementation CreateViewController

- (AppDelegate*) appDelegate {
    return (AppDelegate*)[[UIApplication sharedApplication] delegate];
}

- (BOOL) validateInputOrDisplayError {
    NSString* title;
    NSString* msg;
    
    if( self.nameField.text.length < 1 ) {
        title = NSLocalizedString(@"Invalid Name", @"");
        msg = NSLocalizedString(@"Please input this participants name", @"");
    }
    
    if( msg || title ) {
        UIAlertView* alert = [[UIAlertView alloc] initWithTitle: title
                                                        message: msg
                                                       delegate: nil
                                              cancelButtonTitle: NSLocalizedString(@"OK", @"")
                                              otherButtonTitles: nil];
        [alert show];
        return NO;
    }
    else
        return YES;
}

- (IBAction)addPushed:(id)sender {
    if( [self validateInputOrDisplayError] ) {
        
        self.nameField.enabled = NO;
        self.addButton.enabled = NO;
        
        RKObjectManager* manager = [[self appDelegate] objectManager];
        NSManagedObjectContext* context = manager.managedObjectStore.mainQueueManagedObjectContext;
        
        Participant* newParticipant = [context insertNewObjectForEntityForName: NSStringFromClass([Participant class])];
        newParticipant.name = self.nameField.text;
        
        [[RKObjectManager sharedManager] postObject: newParticipant
                                               path: kWebServiceListPath
                                         parameters: nil
                                            success: ^(RKObjectRequestOperation *operation, RKMappingResult *mappingResult) {
                                                
                                                [self performSegueWithIdentifier: kSegueUnwind sender: nil];
                                                
                                            } failure: ^(RKObjectRequestOperation *operation, NSError *error) {
                                                
                                                NSString* title;
                                                NSString* msg;
                                                RKErrorMessage* errorMessage = [error userInfo][RKObjectMapperErrorObjectsKey];
                                                if( errorMessage ) {
                                                    title = NSLocalizedString(@"Creation Error", @"");
                                                    msg = errorMessage.errorMessage;
                                                }
                                                else {
                                                    title = NSLocalizedString(@"Unknown Error", @"");
                                                    msg = NSLocalizedString(@"Something has gone wrong. Please check your internet connection and try again", @"");
                                                }
                                                
                                                UIAlertView* alert = [[UIAlertView alloc] initWithTitle: title
                                                                                                message: msg
                                                                                               delegate: nil
                                                                                      cancelButtonTitle: NSLocalizedString(@"OK", @"")
                                                                                      otherButtonTitles: nil];
                                                [alert show];
                                                
                                                self.nameField.enabled = YES;
                                                self.addButton.enabled = YES;
                                            }];
    }
}

#pragma mark - NSObject
- (id) initWithCoder:(NSCoder *)aDecoder {
    self = [super initWithCoder: aDecoder];
    if( self ) {
        self.title = NSLocalizedString(@"Add a Participant", @"");
    }
    
    return self;
}

#pragma mark - UIViewController
- (void)viewDidLoad
{
    [super viewDidLoad];
    
    self.nameLabel.text = NSLocalizedString(@"Participant's Name:", @"");
    [self.addButton setTitle: NSLocalizedString(@"Join", @"") forState: UIControlStateNormal];
    self.addButton.enabled = NO;
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

#pragma mark - UITextFieldDelegate
- (BOOL) textField:(UITextField *)textField shouldChangeCharactersInRange:(NSRange)range replacementString:(NSString *)string {
    NSString* finalText = [textField.text stringByReplacingCharactersInRange: range withString: string];
    self.addButton.enabled = finalText.length > 1;
    return YES;
}

- (BOOL) textFieldShouldReturn:(UITextField *)textField {
    [textField resignFirstResponder];
    return YES;
}

- (BOOL) textFieldShouldClear:(UITextField *)textField {
    self.addButton.enabled = NO;
    return YES;
}

@end
