//
//  ParticipantTableViewCell.m
//  QREvents
//
//  Created by Paul De Lange on 25/09/13.
//  Copyright (c) 2013 Toshimoto Sakai. All rights reserved.
//

#import "ParticipantTableViewCell.h"

#import "Participant.h"
#import "AppDelegate.h"

@interface ParticipantTableViewCell () {
    __weak Participant* _participant;
}

@end
@implementation ParticipantTableViewCell

- (AppDelegate*) appDelegate {
    return (AppDelegate*)[[UIApplication sharedApplication] delegate];
}

- (RKObjectManager*) objectManager {
    return [[self appDelegate] objectManager];
}

- (void) commonInit {
    NSString* participant = NSLocalizedString(@"Participant", @"sankasha");
    NSString* ontheday = NSLocalizedString(@"On the Day", @"toujitsu");
    NSString* proxy = NSLocalizedString(@"Representative", @"dairi");
    
    self.participantLabel.text = [NSString stringWithFormat: @"%@:", participant];
    self.onTheDayLabel.text = [NSString stringWithFormat: @"%@:", ontheday];
    self.proxyLabel.text = [NSString stringWithFormat: @"%@:", proxy];
    
    UISwipeGestureRecognizer* swipe = [[UISwipeGestureRecognizer alloc] initWithTarget: self
                                                                                action:@selector(cellRightSwiped:)];
    swipe.direction = UISwipeGestureRecognizerDirectionRight;
    [self addGestureRecognizer: swipe];
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
    
    NSDate* cutoffDate = [NSDate dateWithTimeInterval: -(60 * 60 * 24 * 365 * 5) sinceDate: [NSDate date]];
    
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
    self.participantSwitch.on = [participant participatingValue];
    
    if( participant.qrcode.length ) {
        self.qrcodeLabel.hidden = NO;
        self.qrcodeLabel.text = [NSString stringWithFormat: NSLocalizedString(@"(QR code: %@)", @""), participant.qrcode];
    }
    else {
        self.qrcodeLabel.hidden = YES;
    }
    
    //NSLog(@"%@ vs. %@", participant.exitTime, [NSDate date]);
    
    if( [participant.exitTime timeIntervalSinceNow] < 0 ) {
        self.backgroundColor = [UIColor colorWithWhite: 0.85 alpha: 1.0];
    }
    else {
        self.backgroundColor = [UIColor clearColor];
    }
    
    BOOL canUpdate = ![[NSUserDefaults standardUserDefaults] boolForKey: kUserPreferenceViewModeKey];
    self.proxySwitch.enabled = canUpdate;
    self.onTheDaySwitch.enabled = canUpdate;
    self.participantSwitch.enabled=  canUpdate;
    
    _participant = participant;
    
    [self setSearch: NO];
}

- (void) setSearch: (BOOL) isSearch {
    if( isSearch ) {
        self.proxyLabel.hidden = YES;
        self.proxySwitch.hidden = YES;
        self.participantLabel.hidden = YES;
        self.participantSwitch.hidden = YES;
        self.onTheDayLabel.hidden = YES;
        self.onTheDaySwitch.hidden = YES;
    }
    else {
        self.proxyLabel.hidden = NO;
        self.proxySwitch.hidden = NO;
        self.participantLabel.hidden = NO;
        self.participantSwitch.hidden = NO;
        self.onTheDayLabel.hidden = NO;
        self.onTheDaySwitch.hidden = NO;
    }
}

- (IBAction)cellRightSwiped:(UISwipeGestureRecognizer *)sender {
    
    if( ![[NSUserDefaults standardUserDefaults] boolForKey: kUserPreferenceViewModeKey] ) {
    _participant.exitTime = [NSDate date];
    
    [_participant.managedObjectContext saveToPersistentStore: nil];
    NSString* path = [_participant resourcePath];
    [[self objectManager] putObject: _participant
                               path: path
                         parameters: nil
                            success: ^(RKObjectRequestOperation *operation, RKMappingResult *mappingResult) {
                            } failure:^(RKObjectRequestOperation *operation, NSError *error) {
                            }];
    }
}


#pragma mark - NSObject
- (void) awakeFromNib {
    [self commonInit];
}

@end
