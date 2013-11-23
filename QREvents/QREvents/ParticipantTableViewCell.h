//
//  ParticipantTableViewCell.h
//  QREvents
//
//  Created by Paul De Lange on 25/09/13.
//  Copyright (c) 2013 Toshimoto Sakai. All rights reserved.
//

#import <UIKit/UIKit.h>

@class Participant;

@interface ParticipantTableViewCell : UITableViewCell

@property (weak, nonatomic) IBOutlet UILabel* nameLabel;
@property (weak, nonatomic) IBOutlet UILabel* organizationLabel;
@property (weak, nonatomic) IBOutlet UILabel *entryTimeLabel;
@property (weak, nonatomic) IBOutlet UILabel *exitTimeLabel;
@property (weak, nonatomic) IBOutlet UILabel *proxyLabel;
@property (weak, nonatomic) IBOutlet UISwitch *proxySwitch;
@property (weak, nonatomic) IBOutlet UILabel *onTheDayLabel;
@property (weak, nonatomic) IBOutlet UISwitch *onTheDaySwitch;
@property (weak, nonatomic) IBOutlet UILabel *participantLabel;
@property (weak, nonatomic) IBOutlet UILabel *qrcodeLabel;
@property (weak, nonatomic) IBOutlet UISwitch *participantSwitch;

- (void) setParticipant: (Participant*) participant;

@end
