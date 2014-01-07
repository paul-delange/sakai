//
//  ScannerViewController.h
//  QREvents
//
//  Created by Paul De Lange on 25/09/13.
//  Copyright (c) 2013 Toshimoto Sakai. All rights reserved.
//

#import <UIKit/UIKit.h>

@class Participant;
@class ZBarReaderView;

@interface ScannerViewController : UIViewController

@property (weak, nonatomic) IBOutlet ZBarReaderView *readerView;
@property (weak, nonatomic) IBOutlet UISwitch *cameraToggle;
@property (weak, nonatomic) IBOutlet UILabel *frontLabel;
@property (weak, nonatomic) IBOutlet UILabel *backLabel;
@property (weak, nonatomic) IBOutlet UIActivityIndicatorView *activityIndicator;
@property (weak, nonatomic) IBOutlet UILabel *scannedPersonLabel;

@property (copy, nonatomic) void(^manuallyAddParticipant)(NSString* participantCode);
@property (copy, nonatomic) void(^scannedParticipant)(Participant* participant);

- (IBAction)cameraToggleChanged:(UISwitch *)sender;

@end
