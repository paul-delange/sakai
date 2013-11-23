//
//  ConnectViewController.m
//  QREvents
//
//  Created by Paul De Lange on 26/09/13.
//  Copyright (c) 2013 Toshimoto Sakai. All rights reserved.
//

#import "ConnectViewController.h"
#import "AppDelegate.h"

#import "Event.h"

#import "SBTableAlert.h"

@import AVFoundation;

#import <ZBarSDK/ZBarReaderView.h>
#import <SystemConfiguration/CaptiveNetwork.h>

#define kConfigCodeServerURLKey     @"url"
#define kConfigCodeEventKey         @"event"

@interface ConnectViewController () <UITextFieldDelegate, SBTableAlertDataSource, SBTableAlertDelegate, ZBarReaderViewDelegate> {
    SBTableAlert* _alert;
    NSArray* _events;
    
    
    AVCaptureDevice* _frontCamera;
}

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
                                                                                                path: kWebServiceEventListPath
                                                                                          parameters: nil];
    
    
    void (^failureHandler)(RKObjectRequestOperation*, NSError*) = ^(RKObjectRequestOperation* operation, NSError* error) {
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
        
    };
    
    [operation setCompletionBlockWithSuccess: ^(RKObjectRequestOperation *operation, RKMappingResult *mappingResult) {
        //This server seems to respond to the correct services, so we can go ahead and save our object manager
        [[self appDelegate] setObjectManager: objectManager];
        
        //Now ask for event data
        [objectManager getObjectsAtPath: kWebServiceEventListPath
                             parameters: nil
                                success: ^(RKObjectRequestOperation *operation, RKMappingResult *mappingResult) {
                                    _events = [mappingResult array];
                                    if( _events.count == 1 ) {
                                        [self dismissViewControllerAnimated: YES completion: ^{
                                            [[NSNotificationCenter defaultCenter] postNotificationName: kApplicationResetNotification
                                                                                                object: nil
                                                                                              userInfo: nil];
                                        }];
                                    }
                                    else if( _events.count > 1 ) {
                                        NSString* title = NSLocalizedString(@"Please select an event", @"");
                                        _alert = [[SBTableAlert alloc] initWithTitle: title cancelButtonTitle: NSLocalizedString(@"Cancel", @"") messageFormat: @""];
                                        _alert.dataSource = self;
                                        _alert.delegate = self;
                                        [_alert show];
                                    }
                                    else {
                                        //Didn't find any events...
                                        NSString* title = NSLocalizedString(@"No events available", @"");
                                        NSString* format = NSLocalizedString(@"%@ could not locate any event data on this server. Please check the configuration with an event organizer.", @"");
                                        NSString* msg = [NSString stringWithFormat: format, kAppName()];
                                        
                                        UIAlertView* alert = [[UIAlertView alloc] initWithTitle: title
                                                                                        message: msg
                                                                                       delegate: nil
                                                                              cancelButtonTitle: NSLocalizedString(@"OK", @"")
                                                                              otherButtonTitles: nil];
                                        [alert show];
                                    }
                                    
                                    self.serverURLField.enabled = YES;
                                    self.connectButton.enabled = YES;
                                    [activityView removeFromSuperview];
                                    
                                } failure: failureHandler];
    } failure: failureHandler];
    
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

- (void) badConfigurationScanned {
    NSString* title = NSLocalizedString(@"Not a Configuration code", @"");
    NSString* msg = NSLocalizedString(@"Could not extract event information from this code, please try again.", @"");
    UIAlertView* alert = [[UIAlertView alloc] initWithTitle: title
                                                    message: msg
                                                   delegate: nil
                                          cancelButtonTitle: NSLocalizedString(@"OK", @"")
                                          otherButtonTitles: nil];
    [alert show];
}

#pragma mark - NSObject
- (id) initWithCoder:(NSCoder *)aDecoder {
    self = [super initWithCoder: aDecoder];
    if( self ) {
        
        
#if !TARGET_IPHONE_SIMULATOR
        NSArray* devices = [AVCaptureDevice devices];
        for(AVCaptureDevice* device in devices) {
            if( [device hasMediaType: AVMediaTypeVideo] ) {
                if( [device position] == AVCaptureDevicePositionFront )
                    _frontCamera = device;
                
            }
        }
#endif
    }
    return self;
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
#else
#if DEBUG
    self.serverURLField.text = @"http://api.qrevents.com";
    self.connectButton.enabled = YES;
#endif
#endif
    
    self.qrcodeLabel.text = NSLocalizedString(@"or, scan a configuration code…", @"");
    self.readerView.autoresizingMask = UIViewAutoresizingNone;
}

- (void) viewDidAppear:(BOOL)animated {
    [super viewDidAppear: animated];
    
    if( _frontCamera ) {
        [[self readerView] setDevice: _frontCamera];
        [[self readerView] start];
        [[self readerView] setReaderDelegate: self];
        [[self readerView] willRotateToInterfaceOrientation: [UIApplication sharedApplication].statusBarOrientation
                                                   duration: 0];
    }
}

- (void) viewWillDisappear:(BOOL)animated {
    [super viewWillDisappear: animated];
    
    [[self readerView] stop];
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

#pragma mark - SBTableAlertDataSource
- (UITableViewCell*) tableAlert:(SBTableAlert *)tableAlert cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    static NSString* cellIdentifier = @"AlertTableViewCellIdentifier";
    UITableViewCell* cell = [tableAlert.tableView dequeueReusableCellWithIdentifier: cellIdentifier];
    if( !cell ) {
        cell = [[UITableViewCell alloc] initWithStyle: UITableViewCellStyleDefault reuseIdentifier: cellIdentifier];
    }
    
    Event* event = [_events objectAtIndex: indexPath.row];
    
    cell.textLabel.text = event.name;
    
    return cell;
}

- (NSInteger) tableAlert:(SBTableAlert *)tableAlert numberOfRowsInSection:(NSInteger)section {
    return _events.count;
}

#pragma mark - SBTableAlertDelegate
- (void)tableAlert:(SBTableAlert *)tableAlert didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    Event* selectedEvent = [_events objectAtIndex: indexPath.row];
    NSMutableArray* toDelete = [_events mutableCopy];
    [toDelete removeObject: selectedEvent];
    
    _events = nil;
    
    //Delete
    RKObjectManager* manager = [[self appDelegate] objectManager];
    RKManagedObjectStore* store = [manager managedObjectStore];
    NSManagedObjectContext* context = store.persistentStoreManagedObjectContext;
    for(NSManagedObject* obj in toDelete) {
        NSManagedObject* persistent = [context objectWithID: obj.objectID];
        [store.persistentStoreManagedObjectContext deleteObject: persistent];
    }
    toDelete = nil;
    
    [store.persistentStoreManagedObjectContext saveToPersistentStore: nil];
    
    [self dismissViewControllerAnimated: YES completion: ^{
        [[NSNotificationCenter defaultCenter] postNotificationName: kApplicationResetNotification
                                                            object: nil
                                                          userInfo: nil];
    }];
}

#pragma mark - ZBarReaderViewDelegate
- (void) readerView:(ZBarReaderView *)readerView didReadSymbols:(ZBarSymbolSet *)symbols fromImage:(UIImage *)image {
    for(ZBarSymbol* sym in symbols) {
        NSString* stringValue = sym.data;
        NSData* data = [stringValue dataUsingEncoding: NSUTF8StringEncoding];
        
        //Search for a valid config
        __autoreleasing NSError* error;
        NSDictionary* config = [NSJSONSerialization JSONObjectWithData: data options: 0 error: &error];
        
        if( config ) {
            NSAssert(!error, @"Error reading config code: %@", error);
            
            NSString* string = config[kConfigCodeServerURLKey];
            NSURL* url = [NSURL URLWithString: string];
            if( url ) {
                NSDictionary* event = config[kConfigCodeEventKey];
                if( event ) {
                    RKObjectManager* objectManager = [[self appDelegate] objectManagerWithBaseURL: url andEventName: kAppName()];
                    NSManagedObjectContext* context = objectManager.managedObjectStore.persistentStoreManagedObjectContext;
                    RKFetchRequestManagedObjectCache* cache = [RKFetchRequestManagedObjectCache new];
                    RKManagedObjectMappingOperationDataSource* datasource = [[RKManagedObjectMappingOperationDataSource alloc] initWithManagedObjectContext: context
                                                                                                                                                      cache: cache];
                    NSArray* responseDescriptors = objectManager.responseDescriptors;
                    for(RKResponseDescriptor* descriptor in responseDescriptors) {
                        if( [descriptor matchesPath: kWebServiceEventListPath] ) {
                            RKMapping* mapping	 = descriptor.mapping;
                            NSDictionary* mappingDictionary = @{ [NSNull null] : mapping};
                            RKMapperOperation* operation = [[RKMapperOperation alloc] initWithRepresentation: event
                                                                                          mappingsDictionary: mappingDictionary];
                            [operation setMappingOperationDataSource: datasource];
                            [operation start];
                        }
                    }
                    
                    if( [Event currentEvent] != nil ) {
                        //Successfully created an event
                        [self dismissViewControllerAnimated: YES completion: ^{
                            [[NSNotificationCenter defaultCenter] postNotificationName: kApplicationResetNotification
                                                                                object: nil
                                                                              userInfo: nil];
                        }];
                    }
                    else {
                        [self badConfigurationScanned];
                    }
                    
                }
                else {
                    self.serverURLField.text = string;
                }
            }
            else {
                [self badConfigurationScanned];
            }
        }
        else {
            [self badConfigurationScanned];
        }
    }
}

@end
