//
//  ScannerViewController.m
//  QREvents
//
//  Created by Paul De Lange on 25/09/13.
//  Copyright (c) 2013 Toshimoto Sakai. All rights reserved.
//

#import "ScannerViewController.h"

#import <ZBarSDK/ZBarReaderView.h>
#if TARGET_IPHONE_SIMULATOR
#import <ZBarSDK/ZBarCameraSimulator.h>
#endif

@interface ScannerViewController () <ZBarReaderViewDelegate> {
#if TARGET_IPHONE_SIMULATOR
    ZBarCameraSimulator* cameraSimulator;
#endif
}

@end

@implementation ScannerViewController

- (ZBarReaderView*) readerView {
    return (ZBarReaderView*)self.view;
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

#pragma mark - ZBarReaderViewDelegate
- (void) readerView:(ZBarReaderView *)readerView didReadSymbols:(ZBarSymbolSet *)symbols fromImage:(UIImage *)image {
    NSLog(@"Read");
    for(ZBarSymbol* sym in symbols) {
        NSLog(@"Data: %@", sym.data);
    }
}

@end
