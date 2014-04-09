//
//  DisplayViewController.m
//  iSpy
//
//  Created by Paul de Lange on 8/04/2014.
//  Copyright (c) 2014 Chesterford. All rights reserved.
//

#import "DisplayViewController.h"

#import "PhotoGrabber.h"

@interface DisplayViewController ()

@property (weak, nonatomic) IBOutlet UIImageView *imageView;
@property (weak, nonatomic) IBOutlet UIScrollView *scrollView;
@property (weak, nonatomic) IBOutlet UIRefreshControl* refreshControl;

@end

@implementation DisplayViewController

- (IBAction) refreshPushed: (UIRefreshControl*)sender {
    UIImage* cached = [PhotoGrabber getPhotoForTag: @"japan" withCompletionHandler: ^(UIImage *image, NSError *error) {
        self.imageView.image = image;
        
        CATransition *transition = [CATransition animation];
        transition.duration = 1.0f;
        transition.timingFunction = [CAMediaTimingFunction functionWithName:kCAMediaTimingFunctionEaseInEaseOut];
        transition.type = kCATransitionFade;
        
        [self.imageView.layer addAnimation:transition forKey:nil];
        
        [sender endRefreshing];
    }];
    
    self.imageView.image = cached;
}

- (IBAction) unwind:(UIStoryboardSegue*)sender {
    
}

#pragma mark - UIViewController
- (void)viewDidLoad
{
    [super viewDidLoad];
    // Do any additional setup after loading the view.
    UIRefreshControl* refreshControl = [UIRefreshControl new];
    refreshControl.tintColor = [UIColor whiteColor];
    [refreshControl addTarget: self action: @selector(refreshPushed:) forControlEvents: UIControlEventValueChanged];
    [self.scrollView addSubview: refreshControl];
    self.refreshControl = refreshControl;

    [self refreshPushed: nil];
}

- (void) viewDidLayoutSubviews {
    [super viewDidLayoutSubviews];
    
    self.scrollView.contentSize = self.view.bounds.size;
}

@end
