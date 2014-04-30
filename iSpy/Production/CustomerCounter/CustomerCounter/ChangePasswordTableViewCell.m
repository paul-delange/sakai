//
//  ChangePasswordTableViewCell.m
//  CustomerCounter
//
//  Created by Paul de Lange on 30/04/2014.
//  Copyright (c) 2014 Chesterford. All rights reserved.
//

#import "ChangePasswordTableViewCell.h"

#import "AdminLock.h"

#define kAlertViewConfirmAddPasswordTag 981

@interface ChangePasswordTableViewCell () <UITextFieldDelegate, UIAlertViewDelegate>

@property (weak, nonatomic) IBOutlet UILabel *oldPasswordLabel;
@property (weak, nonatomic) IBOutlet UILabel *passwordLabel;
@property (weak, nonatomic) IBOutlet UIPromptTextField *confirmPasswordField;
@property (weak, nonatomic) IBOutlet UILabel *confirmPasswordLabel;
@property (weak, nonatomic) IBOutlet UIButton *confirmButton;
@property (weak, nonatomic) IBOutlet UILabel *explanationLabel;

@end

@implementation ChangePasswordTableViewCell

- (void) savePassword {
    NSString* password = self.passwordField.text;
    NSParameterAssert(password.length >= 4);
    
    [AdminLock lockWithPassword: password];
}

- (IBAction)confirmPushed:(id)sender {
    if( [AdminLock tryLock] ) {
        [self savePassword];
    }
    else {
        NSString* title = NSLocalizedString(@"Warning!", @"");
        NSString* format = NSLocalizedString(@"If you add a password to %@, you will not be able to exit the slideshow without it. Would you like to continue?", @"");
        UIAlertView* alert = [[UIAlertView alloc] initWithTitle: title
                                                        message: [NSString stringWithFormat: format, kAppName()]
                                                       delegate: self
                                              cancelButtonTitle: NSLocalizedString(@"Cancel", @"")
                                              otherButtonTitles: NSLocalizedString(@"Add", @""), nil];
        alert.tag = kAlertViewConfirmAddPasswordTag;
        [alert show];
    }
}

#pragma mark - NSObject
- (void) awakeFromNib {
    [super awakeFromNib];
    
    self.confirmButton.enabled = NO;
    [self.confirmButton setTitle: NSLocalizedString(@"Save", @"") forState: UIControlStateNormal];
    
    self.oldPasswordLabel.text = NSLocalizedString(@"Previous password:", @"");
    self.passwordLabel.text = NSLocalizedString(@"New password:", @"");
    self.confirmPasswordLabel.text = NSLocalizedString(@"Confirm password:", @"");
    
    if( [AdminLock tryLock] ) {
        self.explanationLabel.text = NSLocalizedString(@"There is currently a password protecting against users leaving the Slideshow. To change the password, first enter it again here.", @"");
    }
    else {
        self.explanationLabel.text = NSLocalizedString(@"Add a password to protect against users leaving the Slideshow. Once a password has been set, it can be changed but never removed.", @"");

        self.oldPasswordField.enabled = NO;
        self.oldPasswordLabel.textColor = [UIColor grayColor];
    }
}

#pragma mark - UIResponder
- (BOOL) resignFirstResponder {
    
    [self.oldPasswordField resignFirstResponder];
    [self.passwordField resignFirstResponder];
    [self.confirmPasswordField resignFirstResponder];
    
    return [super resignFirstResponder];
}

#pragma mark - UITableViewCell
- (void) prepareForReuse {
    [super prepareForReuse];
    
    self.oldPasswordField.text = @"";
    self.passwordField.text = @"";
    self.confirmPasswordField.text = @"";
    self.confirmButton.enabled = NO;
    
    if( [AdminLock tryLock] ) {
        self.oldPasswordField.enabled = YES;
        self.oldPasswordLabel.textColor = [UIColor blackColor];
        
        self.explanationLabel.text = NSLocalizedString(@"There is currently a password protecting against users leaving the Slideshow. To change the password, first enter it again here.", @"");
    }
    else {
        self.oldPasswordField.enabled = NO;
        self.oldPasswordLabel.textColor = [UIColor grayColor];
        
        self.explanationLabel.text = NSLocalizedString(@"Add a password to protect against users leaving the Slideshow. Once a password has been set, it can be changed but never removed.", @"");
    }

}

#pragma mark - UITextFieldDelegate
- (BOOL) textFieldShouldReturn:(UITextField *)textField {
    if( textField == self.oldPasswordField ) {
        [self.passwordField becomeFirstResponder];
    }
    else if( textField == self.passwordField ) {
        [self.confirmPasswordField becomeFirstResponder];
    }
    
    return YES;
}

- (BOOL) textField:(UITextField *)textField shouldChangeCharactersInRange:(NSRange)range replacementString:(NSString *)string {
    NSString* reconstructedString = [textField.text stringByReplacingCharactersInRange: range withString: string];
    
    NSString* oldpass = ( textField == self.oldPasswordField ) ? reconstructedString : self.oldPasswordField.text;
    NSString* newpass = ( textField == self.passwordField ) ? reconstructedString : self.passwordField.text;
    NSString* confirmpass = ( textField == self.confirmPasswordField ) ? reconstructedString : self.confirmPasswordField.text;
    
    BOOL passwordsMatch = [newpass isEqualToString: confirmpass] || [confirmpass length] == 0;
    BOOL isGoodLength = [newpass length] >= 4 || [newpass length] == 0;
    
    if( [AdminLock tryLock] ) {
        BOOL isCorrectOldPass =  [AdminLock unlockWithPassword: oldpass];
        
        self.confirmButton.enabled = isCorrectOldPass && [newpass length] && passwordsMatch && [confirmpass length];
        
        self.oldPasswordField.prompt = isCorrectOldPass || [oldpass length] == 0 ? @"" : NSLocalizedString(@"Incorrect", @"");
    }
    else {
        self.confirmButton.enabled =  [newpass length] && passwordsMatch && [confirmpass length];
    }
    
    self.confirmPasswordField.prompt = passwordsMatch ? @"" : NSLocalizedString(@"Doesn't match", @"");
    self.passwordField.prompt = isGoodLength ? @"" : NSLocalizedString(@"Too short", @"");
    
    return YES;
}

#pragma mark - UIAlertViewDelegate
- (void) alertView:(UIAlertView *)alertView clickedButtonAtIndex:(NSInteger)buttonIndex {
    switch (alertView.tag) {
        case kAlertViewConfirmAddPasswordTag:
        {
            if( buttonIndex != alertView.cancelButtonIndex ) {
                [self savePassword];
            }
            break;
        }
        default:
            break;
    }
}

@end
