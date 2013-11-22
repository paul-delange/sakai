//
//  ParticipantTableViewCell.m
//  QREvents
//
//  Created by Paul De Lange on 25/09/13.
//  Copyright (c) 2013 Toshimoto Sakai. All rights reserved.
//

#import "ParticipantTableViewCell.h"

#import "Participant.h"

@implementation ParticipantTableViewCell

- (void) commonInit {
    NSString* participant = NSLocalizedString(@"Participant", @"sankasha");
    NSString* ontheday = NSLocalizedString(@"On the Day", @"toujitsu");
    NSString* proxy = NSLocalizedString(@"Representative", @"dairi");
    
    self.participantLabel.text = [NSString stringWithFormat: @"%@:", participant];
    self.onTheDayLabel.text = [NSString stringWithFormat: @"%@:", ontheday];
    self.proxyLabel.text = [NSString stringWithFormat: @"%@:", proxy];
}

- (void) setParticipant: (Participant*) participant {
    
    self.nameLabel.text = participant.name;
    
    if( participant.position.length && participant.department.length ) {
        self.organizationLabel.text = [NSString stringWithFormat: @"%@ (%@)", participant.department, participant.position];
    }
    else if( participant.position.length ) {
        self.organizationLabel.text = participant.position;
    }
    else if (participant.department.length ) {
        self.organizationLabel.text = participant.department;
    }
    
    NSDate* cutoffDate = [NSDate dateWithTimeInterval: -(60 * 60 * 365 * 5) sinceDate: [NSDate date]];
    
    BOOL goodEntryTime = [participant.entryTime timeIntervalSinceDate: cutoffDate] > 0;
    BOOL goodExitTime = [participant.exitTime timeIntervalSinceDate: cutoffDate] > 0;
    
    NSString* entrydatestring = goodEntryTime ? [NSDateFormatter localizedStringFromDate: participant.entryTime
                                                                                       dateStyle: NSDateFormatterNoStyle
                                                                                       timeStyle: NSDateFormatterShortStyle] :
    NSLocalizedString(@"-/-", @"");
    
    NSString* exitdatestring = goodExitTime ? [NSDateFormatter localizedStringFromDate: participant.exitTime
                                                                                     dateStyle: NSDateFormatterNoStyle
                                                                                     timeStyle: NSDateFormatterShortStyle] :
    NSLocalizedString(@"-/-", @"");
    
    self.entryTimeLabel.text = [NSString stringWithFormat: NSLocalizedString(@"Entry: %@", @""), entrydatestring];
    self.exitTimeLabel.text = [NSString stringWithFormat: NSLocalizedString(@"Exit: %@", @""), exitdatestring];
    self.onTheDaySwitch.on = participant.on_the_dayValue;
    self.proxySwitch.on = participant.by_proxyValue;

    
    if( participant.qrcode.length ) {
        self.qrcodeLabel.hidden = NO;
        self.qrcodeLabel.text = [NSString stringWithFormat: NSLocalizedString(@"(QR code: %@)", @""), participant.qrcode];
    }
    else {
        self.qrcodeLabel.hidden = YES;
    }
}

#pragma mark - NSObject
- (void) awakeFromNib {
    [self commonInit];
}

@end
