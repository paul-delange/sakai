//
//  HomeViewController.m
//  CustomerCounter
//
//  Created by Paul de Lange on 20/04/2014.
//  Copyright (c) 2014 Chesterford. All rights reserved.
//

#import "HomeViewController.h"

@import AssetsLibrary;

#define kAlertViewAssetsAuthorizationDenied         666
#define kAlertViewAssetsAuthorizationRestricted     667

@interface HomeViewController () <UIAlertViewDelegate>

@end

@implementation HomeViewController

#pragma mark - UIViewController
- (void)viewDidLoad
{
    [super viewDidLoad];
    // Do any additional setup after loading the view.
    
    self.navigationItem.backBarButtonItem = [[UIBarButtonItem alloc] initWithTitle: @"" style: UIBarButtonItemStylePlain target: nil action: nil];
}

- (BOOL) shouldPerformSegueWithIdentifier:(NSString *)identifier sender:(id)sender {
    if( [identifier isEqualToString: @"PushPlaySegue"] ) {
        ALAuthorizationStatus authorizationStatus = [ALAssetsLibrary authorizationStatus];
        
        if ( authorizationStatus == ALAuthorizationStatusDenied ) {
            NSString* title = NSLocalizedString(@"Not Authorized", @"");
            NSString* format = NSLocalizedString(@"%@ is not authorized to display photos. Please enable this in the device Settings app with the Privacy>Photos option", @"");
            NSString* msg = [NSString stringWithFormat: format, kAppName()];
            
            UIAlertView* alert = [[UIAlertView alloc] initWithTitle: title
                                                            message: msg
                                                           delegate: nil
                                                  cancelButtonTitle: NSLocalizedString(@"OK", @"")
                                                  otherButtonTitles: nil];
            alert.tag = kAlertViewAssetsAuthorizationDenied;
            [alert show];
            
            return NO;
        }
        
        if( authorizationStatus == ALAuthorizationStatusRestricted ) {
            NSString* title = NSLocalizedString(@"Not Authorized", @"");
            NSString* msg = NSLocalizedString(@"You are not authorized to access photos on this device. Please see you device administrator to remove the restriction.", @"");
            UIAlertView* alert = [[UIAlertView alloc] initWithTitle: title
                                                            message: msg
                                                           delegate: nil
                                                  cancelButtonTitle: NSLocalizedString(@"OK", @"")
                                                  otherButtonTitles: nil];
            alert.tag = kAlertViewAssetsAuthorizationRestricted;
            [alert show];
            
            return NO;
        }
    }
    
    return YES;
}

#pragma mark - UIAlertViewDelegate
- (void) alertView:(UIAlertView *)alertView clickedButtonAtIndex:(NSInteger)buttonIndex {
    
}

@end
