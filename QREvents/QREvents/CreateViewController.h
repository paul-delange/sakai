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
@property (weak, nonatomic) IBOutlet UITextField *nameField;
@property (weak, nonatomic) IBOutlet UIButton *addButton;
@property (copy, nonatomic) NSString* participantCode;

- (IBAction)addPushed:(id)sender;

@end
