//
//  CreateViewController.h
//  QREvents
//
//  Created by Paul De Lange on 26/09/13.
//  Copyright (c) 2013 Toshimoto Sakai. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface CreateViewController : UIViewController

@property (weak, nonatomic) IBOutlet UILabel *nameLabel;
@property (weak, nonatomic) IBOutlet UILabel *companyLabel;
@property (weak, nonatomic) IBOutlet UILabel *affiliationlabel;
@property (weak, nonatomic) IBOutlet UITextField *nameField;
@property (weak, nonatomic) IBOutlet UITextField *companyField;
@property (weak, nonatomic) IBOutlet UITextField *affiliationField;
@property (weak, nonatomic) IBOutlet UIButton *addButton;
@property (weak, nonatomic) IBOutlet UILabel *participantLabel;
@property (weak, nonatomic) IBOutlet UISwitch *participantSwitch;
@property (weak, nonatomic) IBOutlet UILabel *onTheDayLabel;
@property (weak, nonatomic) IBOutlet UISwitch *onTheDaySwitch;
@property (weak, nonatomic) IBOutlet UILabel *proxyLabel;
@property (weak, nonatomic) IBOutlet UISwitch *proxySwitch;
@property (weak, nonatomic) IBOutlet UILabel *qrcodeLabel;
@property (weak, nonatomic) IBOutlet UITextField *qrCodeField;
@property (weak, nonatomic) IBOutlet UILabel *entryTimeLabel;
@property (weak, nonatomic) IBOutlet UILabel *exitTimeLabel;
@property (weak, nonatomic) IBOutlet UITextField *entryTimeField;
@property (weak, nonatomic) IBOutlet UITextField *exitTimeField;



@property (copy, nonatomic) NSString* participantCode;


- (IBAction)addPushed:(id)sender;
- (IBAction)participantValueChanged:(UISwitch *)sender;
- (IBAction)onTheDayValueChanged:(UISwitch *)sender;
- (IBAction)proxyValueChanged:(UISwitch *)sender;

@end
