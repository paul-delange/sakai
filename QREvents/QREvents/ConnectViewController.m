//
//  ConnectViewController.m
//  QREvents
//
//  Created by Paul De Lange on 26/09/13.
//  Copyright (c) 2013 Toshimoto Sakai. All rights reserved.
//

#import "ConnectViewController.h"
#import "AppDelegate.h"

#import <SystemConfiguration/CaptiveNetwork.h>

@interface ConnectViewController () <UITextFieldDelegate>

@end

@implementation ConnectViewController

- (AppDelegate*) appDelegate {
    return (AppDelegate*)[[UIApplication sharedApplication] delegate];
}

- (IBAction)connectPushed:(id)sender {
    NSURL* url = [NSURL URLWithString: self.serverURLField.text];
    RKObjectManager* objectManager = [[self appDelegate] objectManagerWithBaseURL: url andEventName: kAppName()];
    
    self.serverURLField.enabled = NO;
    self.connectButton.enabled = NO;
    
    UIActivityIndicatorView* activityView = [[UIActivityIndicatorView alloc] initWithActivityIndicatorStyle: UIActivityIndicatorViewStyleGray];
    [activityView startAnimating];
    activityView.frame = CGRectMake(CGRectGetWidth(self.connectButton.frame)-CGRectGetWidth(activityView.frame)-10, 0, CGRectGetWidth(activityView.frame), CGRectGetHeight(self.connectButton.frame));
    
    [self.connectButton addSubview: activityView];
    
    RKObjectRequestOperation *operation = [objectManager appropriateObjectRequestOperationWithObject: nil
                                                                                              method: RKRequestMethodHEAD
                                                                                                path: kWebServiceListPath
                                                                                          parameters: nil];
    [operation setCompletionBlockWithSuccess: ^(RKObjectRequestOperation *operation, RKMappingResult *mappingResult) {
        
        [[self appDelegate] setObjectManager: objectManager];
        [self dismissViewControllerAnimated: YES completion: ^{
            [[NSNotificationCenter defaultCenter] postNotificationName: kApplicationResetNotification
                                                                object: nil
                                                              userInfo: nil];
        }];
        
    } failure: ^(RKObjectRequestOperation *operation, NSError *error) {
        self.serverURLField.enabled = YES;
        self.connectButton.enabled = YES;
        [activityView removeFromSuperview];
        
        NSString* title = NSLocalizedString(@"Server not compatible", @"");
        NSString* format = NSLocalizedString(@"The server you specified appears to be incompatible with this version (%@) of %@.\nError code: %d", @"");
        NSString* msg;
        
        /*
         * Error codes:
         *
         *  -1003 = hostname could not be found
         *  -1011 = Unexpected status code
         *  -1012 = SSL failure (close_notify during handshake) - probably a proxy problem
         */
        
        switch (error.code) {
            case -1011:
                msg = [NSString stringWithFormat: format, kAppVersion(), kAppName(), operation.HTTPRequestOperation.response.statusCode];
                break;
            case -1003:
                title = NSLocalizedString(@"Could not find host", @"");
                msg = NSLocalizedString(@"The server you specified could not be found. Please verify your internet connection.", @"");
                break;
            case -1012:
                title = @"SSL Failure";
                msg = @"SSL handshake has failed, this is usually due to a proxy server interrupting the request. Perhaps try with http?";
            default:
                msg = [NSString stringWithFormat: format, kAppVersion(), kAppName(), error.code];
                break;
        }
        
        UIAlertView* alert = [[UIAlertView alloc] initWithTitle: title
                                                        message: msg
                                                       delegate: nil
                                              cancelButtonTitle: NSLocalizedString(@"OK", @"")
                                              otherButtonTitles: nil];
        [alert show];
    }];
    
    [objectManager enqueueObjectRequestOperation:operation];
}
                                      
                                      

- (NSString*) getNetworkName {
#if TARGET_IPHONE_SIMULATOR
    NSDictionary* info = @{@"SSID" : @"Mac Network"};
#else
    NSArray *ifs = (__bridge_transfer NSArray*)CNCopySupportedInterfaces();
    NSDictionary* info;
    for (NSString *ifnam in ifs) {
        info = (__bridge_transfer NSDictionary*)CNCopyCurrentNetworkInfo((__bridge CFStringRef)ifnam);
        if (info && [info count]) {
            break;
        }
    }
#endif
    return info[@"SSID"];
}

- (BOOL) validateURL: (NSString*) text {
    NSURL* candidateURL = [NSURL URLWithString: text];
    return candidateURL && candidateURL.scheme && candidateURL.host;
}

#pragma mark - UIViewController
- (void)viewDidLoad
{
    [super viewDidLoad];
	// Do any additional setup after loading the view.
    NSString* wifiName = [self getNetworkName];
    NSString* appName = kAppName();
    
    if( wifiName.length ) {
        //We are connected
        self.wifiStatusLabel.text = [NSString stringWithFormat: NSLocalizedString(@"Connected to: %@", @""), wifiName];
        self.wifiStatusLabel.textColor = [UIColor grayColor];
    }
    else {
        //Was no WIFI!!
        self.wifiStatusLabel.text = NSLocalizedString(@"No Network Detected!", @"");
        self.wifiStatusLabel.textColor = [UIColor redColor];
    }
    /*
    NSURLRequest* request = [NSURLRequest requestWithURL: [NSURL URLWithString: @"http://api.qrevents.com/events"]];
    NSData* data = [NSURLConnection sendSynchronousRequest: request returningResponse: Nil error: nil];
    NSArray* parsed = [NSJSONSerialization JSONObjectWithData: data options: 0 error: nil];
    
    self.navigationItem.title = [[parsed objectAtIndex: 0] valueForKey: @"title"];
    */
    NSString* connect = NSLocalizedString(@"Start", @"");
    NSString* format = NSLocalizedString(@"Welcome to %@!\n\nBefore using this app, you must connect to an event. Please enter the address of a valid event server below and then push '%@'", @"");
    NSString* welcomeMessage = [NSString stringWithFormat: format, appName, connect];
    
    NSRange headerRange = NSMakeRange(0, [welcomeMessage rangeOfString: @"\n"].location);
    NSDictionary* headerAttributes = @{
                                       NSFontAttributeName : [UIFont boldSystemFontOfSize: 17]
                                       };
    
    NSRange msgRange = NSMakeRange(headerRange.location + headerRange.length, welcomeMessage.length-headerRange.length-headerRange.location);
    NSDictionary* msgAttributes = @{
                                    NSFontAttributeName : [UIFont systemFontOfSize: 15]
                                    };
    
    NSMutableAttributedString* attrString = [[NSMutableAttributedString alloc] initWithString: welcomeMessage];
    
    [attrString setAttributes: headerAttributes range: headerRange];
    [attrString setAttributes: msgAttributes range: msgRange];
    
    self.welcomeLabel.attributedText = attrString;
    /*NSDictionary* anEvent = [parsed objectAtIndex: 0];
    self.welcomeLabel.text = [anEvent valueForKey: @"name"];
    */
    [self.connectButton setTitle: connect forState: UIControlStateNormal];
    
    self.serverURLField.placeholder = NSLocalizedString(@"http://www.example.com", @"");
    
    self.connectButton.enabled = NO;
#if USING_PARSE_DOT_COM
    self.serverURLField.text = @"https://api.parse.com/1/classes";
    self.connectButton.enabled = YES;
#endif
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
    
}

- (BOOL)disablesAutomaticKeyboardDismissal {
    return NO;
}

#pragma mark - UITextFieldDelegate
- (BOOL)textField:(UITextField *)textField shouldChangeCharactersInRange:(NSRange)range replacementString:(NSString *)string {
    NSString* finalText = [textField.text stringByReplacingCharactersInRange: range withString: string];
    self.connectButton.enabled = [self validateURL: finalText];
    return YES;
}

- (BOOL) textFieldShouldReturn:(UITextField *)textField {
    [textField resignFirstResponder];
    return YES;
}

@end
