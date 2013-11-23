//
//  ParticipantsViewController.h
//  QREvents
//
//  Created by Paul De Lange on 25/09/13.
//  Copyright (c) 2013 Toshimoto Sakai. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface ParticipantsViewController : UITableViewController

@property (strong, nonatomic) IBOutlet UIBarButtonItem* settingsButton;
@property (strong, nonatomic) IBOutlet UIBarButtonItem* codeButton;
@property (strong, nonatomic) IBOutlet UIBarButtonItem* refreshButton;
@property (strong, nonatomic) IBOutlet UIBarButtonItem* searchButton;

- (IBAction)cameraTogglePushed:(id)sender;
- (IBAction)proxyValueChanged:(UISwitch *)sender;
- (IBAction)onTheDayValueChanged:(UISwitch *)sender;
- (IBAction)participantValueChanged:(UISwitch *)sender;
- (IBAction)cellRightSwiped:(UISwipeGestureRecognizer *)sender;

@end
