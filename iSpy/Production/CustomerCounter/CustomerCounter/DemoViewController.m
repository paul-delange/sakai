//
//  DemoViewController.m
//  CustomerCounter
//
//  Created by Paul de Lange on 20/04/2014.
//  Copyright (c) 2014 Chesterford. All rights reserved.
//

#import "DemoViewController.h"

#import "CustomerDetector.h"

@import AVFoundation;

@interface DemoViewController () <CustomerDetectorDelegate> {
    CustomerDetector*   _detector;
    AVCaptureVideoPreviewLayer* _previewLayer;
}

@end

@implementation DemoViewController

#pragma mark - NSObject
- (instancetype) initWithCoder:(NSCoder *)aDecoder {
    self = [super initWithCoder: aDecoder];
    if( self ) {
        _detector = [CustomerDetector new];
        _detector.delegate = self;
    }
    return self;
}

#pragma mark - UIViewController
- (void)viewDidLoad
{
    [super viewDidLoad];
    // Do any additional setup after loading the view.
    AVCaptureVideoPreviewLayer* previewLayer = [_detector previewLayer];
    [self.view.layer addSublayer: previewLayer];
    _previewLayer = previewLayer;
}

- (void) viewWillAppear:(BOOL)animated {
    [super viewWillAppear: animated];
    
    [_detector start];
}

- (void) viewDidDisappear:(BOOL)animated {
    [super viewDidDisappear: animated];
    
    [_detector stop];
}

- (void) viewDidLayoutSubviews {
    [super viewDidLayoutSubviews];
    
    _previewLayer.frame = self.view.bounds;
}

#pragma mark - CustomerDetectorDelegate
- (void) customerDetector:(CustomerDetector *)detector detectedCustomers:(NSSet *)customers {
    NSLog(@"Detected: %@", customers);
}

- (void) customerDetector:(CustomerDetector *)detector encounteredError:(NSError *)error {
    switch (error.code) {
        case kCustomerCounterErrorCanNotAddMetadataOutput:
        {
            NSString* title = NSLocalizedString(@"Initialization Error", @"");
            NSString* format = NSLocalizedString(@"%@ could not connect to the device sensors. Please restart the app and try again.", @"");
            UIAlertView* alert = [[UIAlertView alloc] initWithTitle: title
                                                            message: [NSString stringWithFormat: format, kAppName()]
                                                           delegate: nil
                                                  cancelButtonTitle: NSLocalizedString(@"OK", @"")
                                                  otherButtonTitles: nil];
            [alert show];
            break;
        }
        case kCustomerCounterErrorNoFaceRecognition:
        {
            NSString* title = NSLocalizedString(@"Incompatible device", @"");
            NSString* format = NSLocalizedString(@"%@ is not supported on this device! Please try using an iPad 2 or later device.", @"");
            UIAlertView* alert = [[UIAlertView alloc] initWithTitle: title
                                                            message: [NSString stringWithFormat: format, kAppName()]
                                                           delegate: nil
                                                  cancelButtonTitle: NSLocalizedString(@"OK", @"")
                                                  otherButtonTitles: nil];
            [alert show];
            break;
        }
        default:
            break;
    }
}

@end
