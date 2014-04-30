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
@property (weak, nonatomic) IBOutlet UITextField *confirmPasswordField;
@property (weak, nonatomic) IBOutlet UILabel *confirmPasswordLabel;
@property (weak, nonatomic) IBOutlet UIButton *confirmButton;

@end

@implementation ChangePasswordTableViewCell

- (void) savePassword {
    NSString* password = self.passwordField.text;
    NSParameterAssert(password.length >= 4);
    
    [AdminLock lockWithPassword: password];

    self.oldPasswordField.text = @"";
    self.passwordField.text = @"";
    self.confirmPasswordField.text = @"";
    self.confirmButton.enabled = NO;
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
    
    
    if( ![AdminLock tryLock] ) {
        self.oldPasswordField.enabled = NO;
        self.oldPasswordLabel.textColor = [UIColor grayColor];
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
    
    BOOL passwordsMatch = [newpass isEqualToString: confirmpass];
    BOOL isGoodLength = [newpass length] >= 4;
    
    if( [AdminLock tryLock] ) {
        BOOL isCorrectOldPass =  [AdminLock unlockWithPassword: oldpass];
        
        self.confirmButton.enabled = isCorrectOldPass && isGoodLength && passwordsMatch;
        
        self.oldPasswordField.textColor = isCorrectOldPass ? [UIColor blackColor] : [UIColor redColor];
    }
    else {
        self.confirmButton.enabled =  [newpass length] && passwordsMatch;
    }
    
    self.confirmPasswordField.textColor = passwordsMatch ? [UIColor blackColor] : [UIColor redColor];
    self.passwordField.textColor = isGoodLength ? [UIColor blackColor] : [UIColor redColor];
    
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
