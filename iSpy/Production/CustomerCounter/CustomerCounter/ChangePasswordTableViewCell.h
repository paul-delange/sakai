//
//  ChangePasswordTableViewCell.h
//  CustomerCounter
//
//  Created by Paul de Lange on 30/04/2014.
//  Copyright (c) 2014 Chesterford. All rights reserved.
//

#import <UIKit/UIKit.h>

#import "UIPromptTextField.h"

@interface ChangePasswordTableViewCell : UITableViewCell

@property (weak, nonatomic) IBOutlet UIPromptTextField *oldPasswordField;
@property (weak, nonatomic) IBOutlet UIPromptTextField *passwordField;

@end
