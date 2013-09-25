//
//  ViewController.h
//  QREvents
//
//  Created by Paul De Lange on 25/09/13.
//  Copyright (c) 2013 Toshimoto Sakai. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface ViewController : UIViewController

@property (weak, nonatomic) IBOutlet UITextField *baseURLField;
@property (weak, nonatomic) IBOutlet UITextField *participantIdField;

- (IBAction)downloadListPushed:(id)sender;
- (IBAction)downloadParticipantPushed:(id)sender;
- (IBAction)modifyAndUpdatePushed:(id)sender;
- (IBAction)createRandomPushed:(id)sender;
- (IBAction)resetPushed:(id)sender;

@end
