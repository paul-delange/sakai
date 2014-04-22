//
//  SettingsViewController.m
//  CustomerCounter
//
//  Created by Paul de Lange on 20/04/2014.
//  Copyright (c) 2014 Chesterford. All rights reserved.
//

#import "SettingsViewController.h"

NSString * NSUserDefaultsSlideShowIntervalKey = @"SlideshowInterval";

@interface SettingsViewController ()

@end

@implementation SettingsViewController

#pragma mark - UIViewController
- (void)viewDidLoad
{
    [super viewDidLoad];
    // Do any additional setup after loading the view.
    self.title = NSLocalizedString(@"Settings", @"");
    self.navigationItem.backBarButtonItem = [[UIBarButtonItem alloc] initWithTitle: @"" style: UIBarButtonItemStylePlain target: nil action: nil];
}

- (BOOL) shouldPerformSegueWithIdentifier:(NSString *)identifier sender:(id)sender {

    if( [identifier isEqualToString: @"PushResultsSegue"] ) {
        NSManagedObjectContext* context = NSManagedObjectContextGetMainThreadContext();
        NSFetchRequest* request = [NSFetchRequest fetchRequestWithEntityName: @"Customer"];
        NSError* error;
        NSInteger count = [context countForFetchRequest: request error: &error];
        DLogError(error);
        
        if( count <= 0 ) {
            
            NSString* title = NSLocalizedString(@"Nobody has been counted", @"");
            NSString* msg = NSLocalizedString(@"Please first confirm an active slideshow has been displayed and that customers have come to see the display.", @"");
            
            UIAlertView* alert = [[UIAlertView alloc] initWithTitle: title
                                                            message: msg
                                                           delegate: nil
                                                  cancelButtonTitle: NSLocalizedString(@"OK", @"")
                                                  otherButtonTitles: nil];
            [alert show];
            
            return NO;
        }
        else {
            return YES;
        }
    }
    
    return [super shouldPerformSegueWithIdentifier: identifier sender: sender];
}

@end
