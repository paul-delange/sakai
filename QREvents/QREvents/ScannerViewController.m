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

@import AVFoundation;

#define kAlertViewTagInvalidQRCode  4561
#define kAlertViewTagUnknownParticipant  4562

@interface ScannerViewController () <ZBarReaderViewDelegate, UIAlertViewDelegate> {
#if TARGET_IPHONE_SIMULATOR
    ZBarCameraSimulator* cameraSimulator;
#else
    AVCaptureDevice* _frontCamera;
    AVCaptureDevice* _backCamera;
#endif
    
    BOOL _canScanEventCode;
    NSString* _participantCode;
    __weak UIImageView* _capturedImageView;
}

@end

@implementation ScannerViewController

- (ZBarReaderView*) readerView {
    return (ZBarReaderView*)self.view;
}

- (void) animateParticipantRecognitionSequence: (UIImage*) image {
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

- (IBAction)cameraToggleChanged:(UISwitch *)sender {
#if !TARGET_IPHONE_SIMULATOR
    AVCaptureDevice* currentDevice = [self readerView].device;
    if( currentDevice.position == AVCaptureDevicePositionBack )
        [self readerView].device = _frontCamera;
    else
        [self readerView].device = _backCamera;
#endif
}

#pragma mark - UIViewController
- (id)initWithCoder:(NSCoder *)aDecoder {
    self = [super initWithCoder: aDecoder];
    if( self ) {
#if !TARGET_IPHONE_SIMULATOR
        NSArray* devices = [AVCaptureDevice devices];
        for(AVCaptureDevice* device in devices) {
            if( [device hasMediaType: AVMediaTypeVideo] ) {
                if( [device position] == AVCaptureDevicePositionBack )
                    _backCamera = device;
                else
                    _frontCamera = device;
                    
            }
        }
#endif
        _canScanEventCode = YES;
    }
    return self;
}

- (void) dealloc {
    [[self readerView] setReaderDelegate: nil];
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    self.frontLabel.text = NSLocalizedString(@"Front", @"");
    self.backLabel.text = NSLocalizedString(@"Back", @"");
    
#if TARGET_IPHONE_SIMULATOR
    cameraSimulator = [[ZBarCameraSimulator alloc] initWithViewController: self];
    cameraSimulator.readerView = [self readerView];
    
    self.cameraToggle.hidden = YES;
    self.frontLabel.hidden = YES;
    self.backLabel.hidden = YES;
#else
    if( _frontCamera && _backCamera ) {
        [self.view bringSubviewToFront: self.cameraToggle];
        [self.view bringSubviewToFront: self.frontLabel];
        [self.view bringSubviewToFront: self.backLabel];
    }
    else {
        self.cameraToggle.hidden = YES;
        self.frontLabel.hidden = YES;
        self.backLabel.hidden = YES;
    }
#endif
}

- (void) willRotateToInterfaceOrientation:(UIInterfaceOrientation)toInterfaceOrientation duration:(NSTimeInterval)duration {
    [super willRotateToInterfaceOrientation: toInterfaceOrientation duration: duration];
    
    [[self readerView] willRotateToInterfaceOrientation: toInterfaceOrientation
                                               duration: 0];
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (void) viewDidAppear:(BOOL)animated {
    [super viewDidAppear: animated];
    
    [[self readerView] start];
    [[self readerView] setReaderDelegate: self];
    [[self readerView] willRotateToInterfaceOrientation: [UIApplication sharedApplication].statusBarOrientation
                                               duration: 0];
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
        
        NSLog(@"Scan: %@", NSStringFromCGRect(sym.bounds));
        
        if( [self isValidEventCode: sym.data] ) {
            
            [self.activityIndicator startAnimating];
            
            UIImageView* imageView = [[UIImageView alloc] initWithImage: image];
            imageView.frame = self.view.bounds;
            imageView.layer.shadowColor = [UIColor blackColor].CGColor;
            imageView.layer.shadowOffset = CGSizeMake(2.f, 2.f);
            imageView.layer.shadowRadius = 5.f;
            imageView.layer.shadowOpacity = 1.f;
            
            [self.view addSubview: imageView];
            _capturedImageView = imageView;
            
            [UIView animateWithDuration: [UIApplication sharedApplication].statusBarOrientationAnimationDuration
                                  delay: 0
                                options: UIViewAnimationOptionCurveEaseOut
                             animations: ^{
                                 const CGFloat reducedSizePercent = 0.9;
                                 const CGFloat width = reducedSizePercent * CGRectGetWidth(imageView.frame);
                                 const CGFloat height = reducedSizePercent * CGRectGetHeight(imageView.frame);
                                 const CGFloat x = (CGRectGetWidth(imageView.frame) - width) / 2.f;
                                 const CGFloat y = (CGRectGetHeight(imageView.frame) - height) / 2.f;
                                 
                                 imageView.frame = CGRectMake(x, y, width, height);
                             } completion: ^(BOOL finished) {
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
                                     
                                     //Following rules on page 10 of qrevents_app.pptx.pdf
                                     if( participant.entryTime ) {
                                         participant.exitTime = [NSDate date];
                                     }
                                     else {
                                         participant.entryTime = [NSDate date];
                                     }
                                     
                                     [context saveToPersistentStore: &error];
                                     NSAssert(!error, @"Error updating particpant: %@", error);
 
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
                                 
                                 _canScanEventCode = YES;
                             }];
        }
        else {
            NSString* title = NSLocalizedString(@"Invalid QR code", @"");
            NSString* format = NSLocalizedString(@"This QR code is not compatible with %@ version %@. Please try another.", @"");
            NSString* msg = [NSString stringWithFormat: format, kAppName(), kAppVersion()];
            
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

- (void) readerViewDidStart: (ZBarReaderView*) readerView {
    [self.activityIndicator stopAnimating];
}

#pragma mark - UIAlertViewDelegate
- (void) alertView:(UIAlertView *)alertView didDismissWithButtonIndex:(NSInteger)buttonIndex {
    switch (alertView.tag) {
        case kAlertViewTagInvalidQRCode:
        {
            break;
        }
        case kAlertViewTagUnknownParticipant:
        {
            if( alertView.cancelButtonIndex == buttonIndex ) {
                [UIView transitionWithView: self.view
                                  duration: [UIApplication sharedApplication].statusBarOrientationAnimationDuration
                                   options: UIViewAnimationOptionCurveEaseIn
                                animations: ^{
                                    _capturedImageView.alpha = 0.f;
                                } completion:^(BOOL finished) {
                                    [_capturedImageView removeFromSuperview];
                                }];
            }
            else {
                self.manuallyAddParticipant(_participantCode);
            }
            break;
        }
        default:
            break;
    }
    
    _canScanEventCode = YES;
}

@end
