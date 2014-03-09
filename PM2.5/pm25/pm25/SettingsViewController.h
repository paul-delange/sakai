//
//  SettingsViewController.h
//  pm25
//
//  Created by Paul de Lange on 9/03/2014.
//  Copyright (c) 2014 Chesterford. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface SettingsViewController : UIViewController

@property (weak, nonatomic) IBOutlet UILabel *pushNotificationLabel;
@property (weak, nonatomic) IBOutlet UILabel *alertLevellabel;
@property (weak, nonatomic) IBOutlet UISwitch *pushNotificationSwitch;
@property (weak, nonatomic) IBOutlet UITextField *alertLevelField;
@property (weak, nonatomic) IBOutlet UILabel *explanationLabel;

- (IBAction)pushNotificationValueChanged:(id)sender;

@end
