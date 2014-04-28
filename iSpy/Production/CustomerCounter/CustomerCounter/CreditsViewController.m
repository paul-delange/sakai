//
//  CreditsViewController.m
//  CustomerCounter
//
//  Created by Paul de Lange on 27/04/2014.
//  Copyright (c) 2014 Chesterford. All rights reserved.
//

#import "CreditsViewController.h"

@interface CreditsViewController ()

@property (weak, nonatomic) IBOutlet UILabel *appNameLabel;
@property (weak, nonatomic) IBOutlet UILabel *appVersionLabel;
@end

@implementation CreditsViewController

#pragma mark - UIViewController
- (void)viewDidLoad
{
    [super viewDidLoad];
    // Do any additional setup after loading the view.
    self.title = NSLocalizedString(@"Credits", @"");
    self.appNameLabel.text = kAppName();
    
    id version = [[[NSBundle mainBundle] infoDictionary] objectForKey: (id)kCFBundleVersionKey];
    self.appVersionLabel.text = [NSString stringWithFormat: NSLocalizedString(@"Version %@", @""), version];
}

@end
