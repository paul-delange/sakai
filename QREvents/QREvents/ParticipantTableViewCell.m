//
//  ParticipantTableViewCell.m
//  QREvents
//
//  Created by Paul De Lange on 25/09/13.
//  Copyright (c) 2013 Toshimoto Sakai. All rights reserved.
//

#import "ParticipantTableViewCell.h"

@implementation ParticipantTableViewCell

- (void) commonInit {
    NSString* participant = NSLocalizedString(@"Participant", @"sankasha");
    NSString* ontheday = NSLocalizedString(@"On the Day", @"toujitsu");
    NSString* proxy = NSLocalizedString(@"Representative", @"dairi");
    
    self.participantLabel.text = [NSString stringWithFormat: @"%@:", participant];
    self.onTheDayLabel.text = [NSString stringWithFormat: @"%@:", ontheday];
    self.proxyLabel.text = [NSString stringWithFormat: @"%@:", proxy];
}

- (void) awakeFromNib {
    [self commonInit];
}

@end
