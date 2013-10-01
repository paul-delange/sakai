//
//  ScannerViewController.h
//  QREvents
//
//  Created by Paul De Lange on 25/09/13.
//  Copyright (c) 2013 Toshimoto Sakai. All rights reserved.
//

#import <UIKit/UIKit.h>

@class Participant;

@interface ScannerViewController : UIViewController

@property (copy, nonatomic) void(^manuallyAddParticipant)(NSString* participantCode);
@property (copy, nonatomic) void(^scannedParticipant)(Participant* participant);

@end
