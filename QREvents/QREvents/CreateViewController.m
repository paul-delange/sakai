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
#import "Event.h"

#define     kSegueUnwind        @"UnwindCreateSegue"

@interface CreateViewController () <UITextFieldDelegate> {
    //kParticpationType _participationType;
}

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
    else if( self.companyField.text.length < 1 ) {
        title = NSLocalizedString(@"No Company", @"");
        msg = NSLocalizedString(@"This participant must belong to a company or other organization.", @"");
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
        newParticipant.qrcode = self.participantCode;
        if( self.participantCode ) {
            newParticipant.entryTime = [NSDate date];
        }
        
        //newParticipant.participationTypeValue = _participationType;
        newParticipant.company = self.companyField.text.length ? self.companyField.text : NSLocalizedString(@"Other", @"");
        newParticipant.department = self.affiliationField.text;
        newParticipant.on_the_dayValue = self.onTheDaySwitch.on;
        newParticipant.by_proxyValue = self.proxySwitch.on;
        
        //newParticipant.affiliation = self.affiliationField.text;
        
#if USING_PARSE_DOT_COM
        NSString* path = kWebServiceListPath;
#else
        NSString* path = [kWebServiceListPath stringByReplacingOccurrencesOfString: @":primaryKey" withString: [Event currentEvent].primaryKey];
#endif
        
        [[RKObjectManager sharedManager] postObject: newParticipant
                                               path: path
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
    self.companyLabel.text = NSLocalizedString(@"Company Name:", @"");
    self.affiliationlabel.text = NSLocalizedString(@"Department:", @"");
    [self.addButton setTitle: NSLocalizedString(@"Join", @"") forState: UIControlStateNormal];
    self.addButton.enabled = NO;
    
    NSString* participant = NSLocalizedString(@"Participant", @"sankasha");
    NSString* ontheday = NSLocalizedString(@"On the Day", @"toujitsu");
    NSString* proxy = NSLocalizedString(@"Representative", @"dairi");
    
    self.participantLabel.text = [NSString stringWithFormat: @"%@:", participant];
    self.onTheDayLabel.text = [NSString stringWithFormat: @"%@:", ontheday];
    self.proxyLabel.text = [NSString stringWithFormat: @"%@:", proxy];
    
    self.participantSwitch.on = YES;
    self.onTheDaySwitch.on = NO;
    self.proxySwitch.on = NO;
    
    //_participationType = kParticpationTypeParticipant;
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

#pragma mark - UIPickerViewDataSource
- (NSInteger)numberOfComponentsInPickerView:(UIPickerView *)pickerView {
    return 1;
}

- (NSInteger)pickerView:(UIPickerView *)pickerView numberOfRowsInComponent:(NSInteger)component {
    return kParticpationTypeCount;
}

@end
