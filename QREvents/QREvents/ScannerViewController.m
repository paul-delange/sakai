//
//  ScannerViewController.m
//  QREvents
//
//  Created by Paul De Lange on 25/09/13.
//  Copyright (c) 2013 Toshimoto Sakai. All rights reserved.
//

#import "ScannerViewController.h"
#import "AppDelegate.h"
#import "Participant.h"

#import <ZBarSDK/ZBarReaderView.h>
#if TARGET_IPHONE_SIMULATOR
#import <ZBarSDK/ZBarCameraSimulator.h>
#endif

#define kAlertViewTagInvalidQRCode  4561
#define kAlertViewTagUnknownParticipant  4562

@interface ScannerViewController () <ZBarReaderViewDelegate, UIAlertViewDelegate> {
#if TARGET_IPHONE_SIMULATOR
    ZBarCameraSimulator* cameraSimulator;
#endif
    
    BOOL _canScanEventCode;
    NSString* _participantCode;
}

@end

@implementation ScannerViewController

- (ZBarReaderView*) readerView {
    return (ZBarReaderView*)self.view;
}

- (void) animateParticipantRecognitionSequence {
    _canScanEventCode = NO;
    double delayInSeconds = 4.0;
    dispatch_time_t popTime = dispatch_time(DISPATCH_TIME_NOW, (int64_t)(delayInSeconds * NSEC_PER_SEC));
    dispatch_after(popTime, dispatch_get_main_queue(), ^(void){
        _canScanEventCode = YES;
    });
}

- (AppDelegate*) appDelegate {
    return (AppDelegate*)[[UIApplication sharedApplication] delegate];
}

#pragma mark - UIViewController
- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        // Custom initialization
    }
    return self;
}

- (void) dealloc {
    [[self readerView] setReaderDelegate: nil];
}

- (void)viewDidLoad
{
    [super viewDidLoad];
	// Do any additional setup after loading the view.
    [[self readerView] setReaderDelegate: self];
    
    //Seems to be a hack
    [[self readerView] willRotateToInterfaceOrientation: [UIApplication sharedApplication].statusBarOrientation
                                               duration: 0];
    
#if TARGET_IPHONE_SIMULATOR
    cameraSimulator = [[ZBarCameraSimulator alloc] initWithViewController: self];
    cameraSimulator.readerView = [self readerView];
#endif
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (void) viewDidAppear:(BOOL)animated {
    [super viewDidAppear: animated];
    
    [[self readerView] start];
}

- (void) viewWillDisappear:(BOOL)animated {
    [super viewWillDisappear: animated];
    
    [[self readerView] stop];
}

- (BOOL) isValidEventCode: (NSString*) code {
    NSUInteger length = [code length];
    BOOL containsHyphenCorrectly = [code characterAtIndex: 3] == '-';
    return length == 8 && containsHyphenCorrectly;
}

#pragma mark - ZBarReaderViewDelegate
- (void) readerView:(ZBarReaderView *)readerView didReadSymbols:(ZBarSymbolSet *)symbols fromImage:(UIImage *)image {
    if( !_canScanEventCode )
        return;
    
    for(ZBarSymbol* sym in symbols) {
        if( [self isValidEventCode: sym.data] ) {
            NSString* eventCode = [sym.data substringToIndex: 3];
            NSString* participantCode = [sym.data substringFromIndex: 4];
            
            NSLog(@"Update %@ for event %@", participantCode, eventCode);
            RKObjectManager* objectManager = [self appDelegate].objectManager;
            NSManagedObjectContext* context = objectManager.managedObjectStore.mainQueueManagedObjectContext;
            NSFetchRequest* request = [NSFetchRequest fetchRequestWithEntityName: NSStringFromClass([Participant class])];
            [request setFetchLimit: 1];
            [request setPredicate: [NSPredicate predicateWithFormat: @"primaryKey = %@", participantCode]];
            
            __autoreleasing NSError* error;
            NSArray* results = [context executeFetchRequest: request error: &error];
            NSAssert(!error, @"Error fetching participant: %@", error);
            
            if( results.count ) {
                Participant* participant = results.lastObject;
                
                //TODO: Update times...
                
                [self animateParticipantRecognitionSequence];
                
                self.scannedParticipant(participant);
            }
            else {
                _participantCode = participantCode;
                NSString* title = NSLocalizedString(@"Unknown Particpant code", @"");
                NSString* msg = NSLocalizedString(@"This participant could not be found in this event. Would you like to manually add them?", @"");
                
                UIAlertView* alert = [[UIAlertView alloc] initWithTitle: title
                                                                message: msg
                                                               delegate: self
                                                      cancelButtonTitle: NSLocalizedString(@"No", @"")
                                                      otherButtonTitles: NSLocalizedString(@"Yes", @""), nil];
                alert.tag = kAlertViewTagUnknownParticipant;
                [alert show];
            }
        }
        else {
            NSString* title = NSLocalizedString(@"Invalid QR code", @"");
            NSString* msg = NSLocalizedString(@"This QR code is not compatible with %@ version %@. Please try another.", @"");
            
            UIAlertView* alert = [[UIAlertView alloc] initWithTitle: title
                                                            message: msg
                                                           delegate: self
                                                  cancelButtonTitle: NSLocalizedString(@"OK", @"")
                                                  otherButtonTitles: nil];
            alert.tag = kAlertViewTagInvalidQRCode;
            [alert show];
        }
    }
}

#pragma mark - UIAlertViewDelegate
- (void) alertView:(UIAlertView *)alertView didDismissWithButtonIndex:(NSInteger)buttonIndex {
    switch (alertView.tag) {
        case kAlertViewTagInvalidQRCode:
        {
            _canScanEventCode = YES;
            break;
        }
        case kAlertViewTagUnknownParticipant:
        {
            if( alertView.cancelButtonIndex == buttonIndex ) {
                _canScanEventCode = YES;
            }
            else {
                self.manuallyAddParticipant(_participantCode);
            }
            break;
        }
        default:
            break;
    }
}

@end
