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
    NSArray* dateFormatters;
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

- (IBAction)onTheDayValueChanged:(UISwitch *)sender {
    if( sender.on ) {
        [self.participantSwitch setOn: YES animated: YES];
        [self.proxySwitch setOn: NO animated: YES];
    }
    
    self.addButton.enabled = YES;
}

- (IBAction)proxyValueChanged:(UISwitch *)sender {
    if( sender.on ) {
        [self.participantSwitch setOn: YES animated: YES];
        [self.onTheDaySwitch setOn: NO animated: YES];
    }
    
    self.addButton.enabled = YES;
}

- (IBAction)addPushed:(id)sender {
    if( [self validateInputOrDisplayError] ) {
        
        self.nameField.enabled = NO;
        self.addButton.enabled = NO;
        
        RKObjectManager* manager = [[self appDelegate] objectManager];
        NSManagedObjectContext* context = manager.managedObjectStore.mainQueueManagedObjectContext;
        if( self.participant ) {
            //Going to update
            self.participant.name = self.nameField.text;
            self.participant.qrcode = self.qrCodeField.text;
            self.participant.company = self.companyField.text;
            self.participant.department = self.affiliationField.text;
            self.participant.on_the_dayValue = self.onTheDaySwitch.on;
            self.participant.by_proxyValue = self.proxySwitch.on;
            //self.participant.participatingValue = self.participantSwitch.on;
            
            NSString* path = [self.participant resourcePath];
            [manager putObject: self.participant
                          path: path
                    parameters: nil
                       success: ^(RKObjectRequestOperation *operation, RKMappingResult *mappingResult) {
                           [self performSegueWithIdentifier: kSegueUnwind sender: nil];
                       } failure:^(RKObjectRequestOperation *operation, NSError *error) {
                           NSString* title;
                           NSString* msg;
                           RKErrorMessage* errorMessage = [error userInfo][RKObjectMapperErrorObjectsKey];
                           if( errorMessage ) {
                               title = NSLocalizedString(@"Update Error", @"");
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
        else {
            //Going to create new
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
            newParticipant.qrcode = self.qrCodeField.text;
            //newParticipant.participatingValue = self.participantSwitch.on;
            newParticipant.atama_moji = newParticipant.company.length > 0 ? [newParticipant.company substringToIndex: 1] : @"";
            
            
            for(NSDateFormatter* formatter in dateFormatters) {
                if( !newParticipant.entryTime )
                    newParticipant.entryTime = [formatter dateFromString: self.entryTimeField.text];
                
                if( !newParticipant.exitTime )
                    newParticipant.exitTime = [formatter dateFromString: self.exitTimeField.text];
            }
            
#if USING_PARSE_DOT_COM
            NSString* path = kWebServiceListPath;
#else
            NSString* path = [[Event currentEvent] resourcePathParticipants];
#endif
            
            [manager postObject: newParticipant
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
}

- (IBAction)participantValueChanged:(UISwitch *)sender {
    if( !sender.on ) {
        [self.onTheDaySwitch setOn: NO animated: YES];
        [self.proxySwitch setOn: NO animated: YES];
    }
    
    self.addButton.enabled = YES;
}

- (IBAction) entryTimePickerValueChanged:(UIDatePicker*)sender {
    NSDateFormatter* formatter = dateFormatters.count ? dateFormatters[0] : nil;
    self.entryTimeField.text = [formatter stringFromDate: sender.date];
    
    self.addButton.enabled = YES;
}

- (IBAction) exitTimePickerValueChanged:(UIDatePicker*)sender {
    NSDateFormatter* formatter = dateFormatters.count ? dateFormatters[0] : nil;
    self.exitTimeField.text = [formatter stringFromDate: sender.date];
    
    self.addButton.enabled = YES;
}

#pragma mark - NSObject
- (id) initWithCoder:(NSCoder *)aDecoder {
    self = [super initWithCoder: aDecoder];
    if( self ) {
        self.title = NSLocalizedString(@"Add a Participant", @"");
        
        NSString* format = [NSDateFormatter dateFormatFromTemplate: @"hhmm" options: 0 locale: [NSLocale currentLocale]];
        NSLog(@"Local date format: %@", format);
        
        NSDate* date = [NSDate date];
        NSTimeZone* timezone = [NSTimeZone timeZoneForSecondsFromGMT: 0];
        
        //NSLog(@"Timezone: %@", timezone);
        
        NSDateFormatter* localFormatter = [NSDateFormatter new];
        [localFormatter setDateFormat: format];
        [localFormatter setLocale: [NSLocale currentLocale]];
        [localFormatter setDefaultDate: date];
        [localFormatter setTimeZone: timezone];
        
        NSDateFormatter* timeFormatter = [NSDateFormatter new];
        [timeFormatter setDateFormat: @"hh:mm"];
        [timeFormatter setLenient: YES];
        [timeFormatter setDefaultDate: date];
        [timeFormatter setTimeZone: timezone];
        
        NSLog(@"Time date format: %@", [timeFormatter dateFormat]);
        
        dateFormatters = @[localFormatter, timeFormatter];
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
    self.qrcodeLabel.text = NSLocalizedString(@"QR code:", @"");
    self.entryTimeLabel.text = NSLocalizedString(@"Entry time:", @"");
    self.exitTimeLabel.text = NSLocalizedString(@"Exit time:", @"");
    
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
    self.entryTimeField.placeholder = NSLocalizedString(@"Enter an entry time…", @"");
    self.exitTimeField.placeholder = NSLocalizedString(@"Enter an exit time…", @"");
    
    NSDate* now = [NSDate date];
    self.entryTimeField.text = [NSDateFormatter localizedStringFromDate: now
                                                              dateStyle: NSDateFormatterNoStyle
                                                              timeStyle: NSDateFormatterShortStyle];
    
    if( self.participant ) {
        self.nameField.text = self.participant.name;
        self.companyField.text = self.participant.company;
        self.affiliationField.text = self.participant.department;
        self.participantSwitch.on = [self.participant participatingValue];
        self.onTheDaySwitch.on = self.participant.on_the_dayValue;
        self.proxySwitch.on = self.participant.by_proxyValue;
        self.qrCodeField.text = self.participant.qrcode;
        
        if( self.participant.entryTime )
            self.entryTimeField.text =[NSDateFormatter localizedStringFromDate: self.participant.entryTime
                                                                     dateStyle: NSDateFormatterNoStyle
                                                                     timeStyle: NSDateFormatterShortStyle];
        else
            self.entryTimeField.text = @"";
        
        if( self.participant.exitTime )
            self.exitTimeField.text =[NSDateFormatter localizedStringFromDate: self.participant.exitTime
                                                                    dateStyle: NSDateFormatterNoStyle
                                                                    timeStyle: NSDateFormatterShortStyle];
        else
            self.exitTimeField.text = @"";
        
        //self.exitTimeField.enabled = NO;
        //self.entryTimeField.enabled = NO;
        
        [self.addButton setTitle: NSLocalizedString(@"Update", @"") forState: UIControlStateNormal];
    }
    
    UIDatePicker* entryPicker = [UIDatePicker new];
    entryPicker.datePickerMode = UIDatePickerModeTime;
    entryPicker.timeZone = [NSTimeZone timeZoneForSecondsFromGMT: 0];
    [entryPicker setDate: [NSDate date]];
    entryPicker.locale = [NSLocale currentLocale];
    [entryPicker addTarget: self action: @selector(entryTimePickerValueChanged:) forControlEvents: UIControlEventValueChanged];
    
    self.entryTimeField.inputView = entryPicker;
    
    UIDatePicker* exitPicker = [UIDatePicker new];
    exitPicker.minimumDate = entryPicker.date;
    exitPicker.datePickerMode = UIDatePickerModeTime;
    exitPicker.timeZone = [NSTimeZone timeZoneForSecondsFromGMT: 0];
    exitPicker.locale = [NSLocale currentLocale];
    [exitPicker addTarget: self action: @selector(exitTimePickerValueChanged:) forControlEvents: UIControlEventValueChanged];
    
    self.exitTimeField.inputView = exitPicker;
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
    
    return (textField == self.entryTimeField || textField == self.exitTimeField ) ? NO : YES;
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
