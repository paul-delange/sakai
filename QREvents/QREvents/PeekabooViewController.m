//
//  PeekabooViewController.m
//  QREvents
//
//  Created by Paul De Lange on 09/10/13.
//  Copyright (c) 2013 Toshimoto Sakai. All rights reserved.
//

#import "PeekabooViewController.h"

#define     PEEK_WIDTH      256

@interface PeekabooViewController () {
    BOOL _peekingViewControllerVisible;
    BOOL _animating;
}

@end

@implementation PeekabooViewController


- (IBAction) togglePeekingController: (id)sender {
    
    if( _animating )
        return;

    _animating = YES;
    
    if( _peekingViewControllerVisible ) {
        _peekingViewControllerVisible = NO;
        
        [UIView animateWithDuration: [UIApplication sharedApplication].statusBarOrientationAnimationDuration
                              delay: 0.f
                            options: UIViewAnimationOptionCurveEaseInOut
                         animations: ^{
                             self.detailViewController.view.frame = [self frameForDetailViewController];
                         } completion: ^(BOOL finished) {
                             [self.masterViewController.view removeFromSuperview];
                             _animating = NO;
                         }];
        
    }
    else {
        _peekingViewControllerVisible = YES;
        self.masterViewController.view.frame = [self frameForMasterViewController];
        [self.view insertSubview: self.masterViewController.view belowSubview: self.detailViewController.view];
        
        [UIView animateWithDuration: [UIApplication sharedApplication].statusBarOrientationAnimationDuration
                              delay: 0.f
                            options: UIViewAnimationOptionCurveEaseInOut
                         animations: ^{
                             self.detailViewController.view.frame = [self frameForDetailViewController];
                         } completion: ^(BOOL finished) {
                             _animating = NO;
                         }];
    }
}

- (void) setDetailViewController:(UIViewController *)detailViewController {
    if( _detailViewController != detailViewController ) {
        [_detailViewController removeObserver: self forKeyPath: @"view" context: nil];
        [_detailViewController willMoveToParentViewController: nil];
        [_detailViewController.view removeFromSuperview];
        [_detailViewController removeFromParentViewController];
        
        
        [detailViewController addObserver: self forKeyPath: @"view" options: NSKeyValueObservingOptionNew context: nil];

        [self addChildViewController: detailViewController];
        
        if( [self isViewLoaded] ) {
            [self.view addSubview: detailViewController.view];
        }
        
        [detailViewController didMoveToParentViewController: self];
        
        _detailViewController = detailViewController;
    }
}

- (void) setMasterViewController:(UIViewController *)masterViewController {
    if (_masterViewController != masterViewController )  {
        
        [_masterViewController removeObserver: self forKeyPath: @"view" context: nil];
        [_masterViewController willMoveToParentViewController: nil];
        [_masterViewController.view removeFromSuperview];
        [_masterViewController removeFromParentViewController];
        
        if( [self isViewLoaded] ) {
            [self.view addSubview: masterViewController.view];
        }
        
        [masterViewController didMoveToParentViewController: self];
        
        _masterViewController = masterViewController;
    }
}

- (CGRect) frameForMasterViewController {
    if( _peekingViewControllerVisible ) {
        return CGRectMake(0, 0, PEEK_WIDTH, CGRectGetHeight(self.view.bounds));
    }
    else {
        return CGRectMake(0, 0, 0, CGRectGetHeight(self.view.bounds));
    }
}

- (CGRect) frameForDetailViewController {
    if( _peekingViewControllerVisible ) {
        return CGRectMake(PEEK_WIDTH, 0, CGRectGetWidth(self.view.bounds)-PEEK_WIDTH, CGRectGetHeight(self.view.bounds));
    }
    else {
        return self.view.bounds;
    }
}

#pragma mark - UIViewController
- (void)viewDidLoad
{
    [super viewDidLoad];
	// Do any additional setup after loading the view.
    
    if( _peekingViewControllerVisible ) {
        if( self.masterViewController ) {
            self.masterViewController.view.frame = [self frameForMasterViewController];
            [self.view addSubview: self.masterViewController.view];
        }
    }
    
    if( self.detailViewController ) {
        self.detailViewController.view.frame = [self frameForDetailViewController];
        [self.view addSubview: self.detailViewController.view];
    }
}

- (void) viewWillLayoutSubviews {
    [super viewWillLayoutSubviews];
    
    self.masterViewController.view.frame = [self frameForMasterViewController];
    self.detailViewController.view.frame = [self frameForDetailViewController];
}

#pragma mark - KVO
- (void) observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context {
    if( [keyPath isEqualToString: @"view"] ) {
        UIView* newView = change[NSKeyValueChangeNewKey];
        newView.layer.masksToBounds = NO;
        newView.layer.shadowOffset = CGSizeZero;
        newView.layer.shadowRadius = 10.f;
        newView.layer.shadowOpacity = 0.8;
    }
}

@end
