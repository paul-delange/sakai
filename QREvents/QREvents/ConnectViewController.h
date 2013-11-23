//
//  ConnectViewController.h
//  QREvents
//
//  Created by Paul De Lange on 26/09/13.
//  Copyright (c) 2013 Toshimoto Sakai. All rights reserved.
//

#import <UIKit/UIKit.h>

@class ZBarReaderView;

@interface ConnectViewController : UIViewController

@property (weak, nonatomic) IBOutlet UILabel *welcomeLabel;
@property (weak, nonatomic) IBOutlet UITextField *serverURLField;
@property (weak, nonatomic) IBOutlet UIButton *connectButton;
@property (weak, nonatomic) IBOutlet UILabel *wifiStatusLabel;
@property (weak, nonatomic) IBOutlet UILabel *qrcodeLabel;
@property (weak, nonatomic) IBOutlet ZBarReaderView *readerView;

- (IBAction)connectPushed:(id)sender;

@end
