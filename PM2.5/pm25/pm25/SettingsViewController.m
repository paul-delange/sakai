//
//  SettingsViewController.m
//  pm25
//
//  Created by Paul de Lange on 9/03/2014.
//  Copyright (c) 2014 Chesterford. All rights reserved.
//

#import "SettingsViewController.h"

static bool isValidPMValue(NSInteger newAlertLevel) {
    return newAlertLevel > 10 && newAlertLevel < 100;
}

@interface SettingsViewController () <UIAlertViewDelegate>

@end

@implementation SettingsViewController

#pragma mark - Actions
- (IBAction)pushNotificationValueChanged:(id)sender {

}

- (IBAction) doneEditingAlertLevelPushed:(id)sender {
    NSInteger newAlertLevel = [self.alertLevelField.text integerValue];
    if( isValidPMValue(newAlertLevel) ) {
        [[NSUserDefaults standardUserDefaults] setInteger: newAlertLevel forKey: kUserDefaultsAlertLevelKey];
        [[NSUserDefaults standardUserDefaults] synchronize];
        
        [self.alertLevelField resignFirstResponder];
    }
    else {
        NSString* title = NSLocalizedString(@"Are you sure?", @"");
        NSString* msg = NSLocalizedString(@"Red text indicates you trying to set an Alert Level outside the normal daily range. Please confirm.", @"");
        UIAlertView* alert = [[UIAlertView alloc] initWithTitle: title
                                                        message: msg
                                                       delegate: self
                                              cancelButtonTitle: NSLocalizedString(@"Cancel", @"")
                                              otherButtonTitles: NSLocalizedString(@"Confirm", @""), nil];
        [alert show];
    }
}

- (IBAction) cancelEditingAlertLevelPushed:(id)sender {
    self.alertLevelField.text = [[NSUserDefaults standardUserDefaults] stringForKey: kUserDefaultsAlertLevelKey];
    
    [self.alertLevelField resignFirstResponder];
}

#pragma mark - NSObject
+ (void) initialize {
    NSDictionary* defaults = @{ kUserDefaultsPushNotificationsEnabledKey : @NO, kUserDefaultsAlertLevelKey : @(10) };
    [[NSUserDefaults standardUserDefaults] registerDefaults: defaults];
    [[NSUserDefaults standardUserDefaults] synchronize];
}

#pragma mark - UIViewController
- (void)viewDidLoad
{
    [super viewDidLoad];
	// Do any additional setup after loading the view.
    
    self.pushNotificationLabel.text = NSLocalizedString(@"Push Notifications:", @"");
    self.alertLevellabel.text = NSLocalizedString(@"Alert Level", @"");
    
    self.explanationLabel.text = NSLocalizedString(@"When the PM2.5 at your current location goes over the Alert Level, you can choose to receive a Push Notification", @"");
    self.alertLevelField.text = [[NSUserDefaults standardUserDefaults] stringForKey: kUserDefaultsAlertLevelKey];
    self.alertLevelField.enabled = [[NSUserDefaults standardUserDefaults] boolForKey: kUserDefaultsPushNotificationsEnabledKey];
    self.pushNotificationSwitch.on = [[NSUserDefaults standardUserDefaults] boolForKey: kUserDefaultsPushNotificationsEnabledKey];
    
    UIToolbar* toolbar = [[UIToolbar alloc] initWithFrame: CGRectMake(0, 0, CGRectGetWidth(self.view.bounds), 32.)];
    UIBarButtonItem* doneButton = [[UIBarButtonItem alloc] initWithBarButtonSystemItem: UIBarButtonSystemItemDone
                                                                                target: self
                                                                                action: @selector(doneEditingAlertLevelPushed:)];
    UIBarButtonItem* cancelButton = [[UIBarButtonItem alloc] initWithBarButtonSystemItem: UIBarButtonSystemItemCancel
                                                                                  target: self
                                                                                  action:@selector(cancelEditingAlertLevelPushed:)];
    toolbar.items = @[cancelButton,
                      [[UIBarButtonItem alloc] initWithBarButtonSystemItem: UIBarButtonSystemItemFlexibleSpace target: NULL action: NULL],
                      doneButton];
    toolbar.barStyle = UIBarStyleBlackTranslucent;
    toolbar.translucent = YES;
    
    self.alertLevelField.inputAccessoryView = toolbar;
    
}

#pragma mark - UITextFieldDelegate
- (BOOL)textField:(UITextField *)textField shouldChangeCharactersInRange:(NSRange)range replacementString:(NSString *)string {
    NSString* finalString = [textField.text stringByReplacingCharactersInRange: range withString: string];
    
    NSInteger newAlertLevel = [finalString integerValue];
    
    textField.textColor = isValidPMValue(newAlertLevel) || [finalString length] < 2 ? [UIColor darkTextColor] : [UIColor redColor];
    
    return YES;
}

#pragma mark - UIAlertViewDelegate 
- (void) alertView:(UIAlertView *)alertView didDismissWithButtonIndex:(NSInteger)buttonIndex {
    if( alertView.cancelButtonIndex != buttonIndex ) {
        NSInteger newAlertLevel = [self.alertLevelField.text integerValue];
        
        self.alertLevelField.textColor = [UIColor darkTextColor];
        [[NSUserDefaults standardUserDefaults] setInteger: newAlertLevel forKey: kUserDefaultsAlertLevelKey];
        [[NSUserDefaults standardUserDefaults] synchronize];
        
        [self.alertLevelField resignFirstResponder];
    }
}

@end
