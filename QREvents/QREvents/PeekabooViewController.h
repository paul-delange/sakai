//
//  PeekabooViewController.h
//  QREvents
//
//  Created by Paul De Lange on 09/10/13.
//  Copyright (c) 2013 Toshimoto Sakai. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface PeekabooViewController : UIViewController

@property (strong, nonatomic) UIViewController* masterViewController;
@property (strong, nonatomic) UIViewController* detailViewController;


- (IBAction) togglePeekingController: (id)sender;

@end
