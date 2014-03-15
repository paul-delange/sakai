//
//  AppContainerViewController.m
//  pm25
//
//  Created by Paul de Lange on 9/03/2014.
//  Copyright (c) 2014 Chesterford. All rights reserved.
//

#import "AppContainerViewController.h"

#import "AppMenuButton.h"

#import "AppMenuItem.h"
//#import "PhotoGrabber.h"
#import "UIImage+ImageEffects.h"
#import "ContentLock.h"

#import "GADBannerView.h"
#import "GADRequest.h"

#define kStateResorationCurrentIndexKey     @"CurrentSelectedIndexKey"

@interface AppContainerViewController () <UIGestureRecognizerDelegate, GADBannerViewDelegate> {
    NSUInteger      _currentViewControllerIndex;
    NSArray*        _menuItemViews;
    __weak UIView*  _menuDismissView;
    NSLayoutConstraint*     _bottomLayoutConstraint;
}

@property (weak) UIButton* menuButton;
@property (weak) UIImageView* imageView;
@property (weak) UIView* contentView;
@property (weak) GADBannerView* bannerView;

@end

@implementation AppContainerViewController


- (void) addChildViewController:(UIViewController *)childController {
    [childController willMoveToParentViewController: self];
    [super addChildViewController: childController];
    [childController didMoveToParentViewController: self];
}

- (void) removeChildViewController: (UIViewController *) childController {
    [childController willMoveToParentViewController: nil];
    [childController removeFromParentViewController];
    [childController didMoveToParentViewController: nil];
}

- (NSArray*) viewControllers {
    return [self.menuItems valueForKeyPath: @"@unionOfObjects.controller"];
}

- (void) addMenuButtonWithImage: (UIImage*) image {
    UIImage* menuImage = image;
    UIButton* menuButton = [UIButton buttonWithType: UIButtonTypeCustom];
    menuButton.frame = CGRectMake(CGRectGetWidth(self.view.bounds)-menuImage.size.width, 0, menuImage.size.width, menuImage.size.height);
    [menuButton setImage: menuImage forState: UIControlStateNormal];
    menuButton.translatesAutoresizingMaskIntoConstraints = NO;
    [menuButton addTarget: self action: @selector(menuPushed:) forControlEvents: UIControlEventTouchUpInside];
    menuButton.layer.shadowColor = [UIColor blackColor].CGColor;
    menuButton.layer.shadowOpacity = 1.;
    menuButton.layer.shadowOffset = CGSizeZero;
    menuButton.layer.shadowRadius = 5.;
    [self.view addSubview: menuButton];
    self.menuButton = menuButton;
    
    id contentView = self.contentView;
    
    [self.view addConstraints: [NSLayoutConstraint constraintsWithVisualFormat: @"H:[menuButton]-|"
                                                                       options: 0
                                                                       metrics: nil
                                                                         views: NSDictionaryOfVariableBindings(menuButton)]];
    [self.view addConstraint: [NSLayoutConstraint constraintWithItem: menuButton
                                                           attribute: NSLayoutAttributeBottom
                                                           relatedBy: NSLayoutRelationEqual
                                                              toItem: contentView
                                                           attribute: NSLayoutAttributeBottom
                                                          multiplier: 1.0
                                                            constant: -8.]];
}

- (void) addBannerView {
    GADBannerView* banner = [[GADBannerView alloc] initWithAdSize: kGADAdSizeBanner];
    banner.delegate = self;
    banner.adUnitID = ADMOB_SLOT_IDENTIFIER;
    banner.rootViewController = self;
    banner.translatesAutoresizingMaskIntoConstraints = NO;
    [self.view addSubview: banner];
    self.bannerView = banner;
    
    UIView* view = self.contentView;
    
    [self.view addConstraints: [NSLayoutConstraint constraintsWithVisualFormat: @"H:|[banner]|"
                                                                       options: 0
                                                                       metrics: nil
                                                                         views: NSDictionaryOfVariableBindings(banner)]];
    NSString* visualFormat = [NSString stringWithFormat: @"V:[view][banner(==%f)]", kGADAdSizeBanner.size.height];
    
    [self.view addConstraints: [NSLayoutConstraint constraintsWithVisualFormat: visualFormat
                                                                       options: 0
                                                                       metrics: nil
                                                                         views: NSDictionaryOfVariableBindings(view, banner)]];
    
}

- (void) setMenuItems:(NSArray *)menuItems {
    
    for(UIViewController* childController in self.viewControllers) {
        [self removeChildViewController: childController];
        
        if( [childController isViewLoaded] )
            [childController.view removeFromSuperview];
    }
    
    _menuItems = [menuItems copy];
    
    for(UIViewController* childController in self.viewControllers) {
        [self addChildViewController: childController];
    }
}

- (void) displayView: (UIView*) view {
    view.backgroundColor = [UIColor clearColor];
    view.frame = self.contentView.bounds;
    view.autoresizingMask = UIViewAutoresizingFlexibleHeight | UIViewAutoresizingFlexibleWidth;
}

#pragma mark - Actions
- (IBAction) menuItemPushed:(id)sender {
    AppMenuItem* oldItem = self.menuItems[_currentViewControllerIndex];
    NSMutableArray* remainingItems = [self.menuItems mutableCopy];
    [remainingItems removeObject: oldItem];
    [remainingItems insertObject: oldItem atIndex: 0];
    
    BOOL shouldHoldSelection = sender == _menuItemViews[0] ? NO : YES;
    
    for(AppMenuButton* itemView in _menuItemViews) {
        
        BOOL isSelectedItem = itemView == sender;
        
        [UIView animateWithDuration: 0.3
                              delay: 0
                            options: UIViewAnimationOptionCurveEaseInOut
                         animations: ^{
                             CGRect frame = itemView.frame;
                             frame.origin.y = CGRectGetMaxY(self.contentView.bounds) - CGRectGetHeight(frame);
                             itemView.frame = frame;
                             itemView.alpha = isSelectedItem && shouldHoldSelection ? 0.7 : 0.;
                         } completion: ^(BOOL finished) {
                             itemView.hasSeparator = NO;
                             
                             if( finished && itemView.alpha > 0. ) {
                                 itemView.enabled = NO;
                                 [UIView animateWithDuration: 1.0
                                                       delay: 1.0
                                                     options: UIViewAnimationOptionCurveEaseIn
                                                  animations: ^{
                                                      itemView.alpha = 0.;
                                                  } completion:^(BOOL finished) {
                                                      [itemView removeFromSuperview];
                                                  }];
                             }
                             else {
                                 [itemView removeFromSuperview];
                             }
                         }];
    }
    
    if( [_menuItemViews containsObject: sender] ) {
        NSUInteger viewIndex = [_menuItemViews indexOfObject: sender];
        AppMenuItem* newItem = remainingItems[viewIndex];
        
        _currentViewControllerIndex = [self.menuItems indexOfObject: newItem];
        
        UIViewController* newController =  newItem.controller;
        UIView* view = newController.view;
        [self displayView: view];
        //view.alpha = 0.f;
        [self.menuButton setImage: newItem.image forState: UIControlStateNormal];
        
        [UIView transitionWithView: self.view
                          duration: 0.3
                           options: UIViewAnimationOptionCurveEaseInOut
                        animations: ^{
                            
                            [self.contentView insertSubview: view belowSubview: _menuDismissView];
                            //view.alpha = 1.f;
                            if( view != oldItem.controller.view )
                                [oldItem.controller.view removeFromSuperview];
                            
                        } completion: NULL];
    }
    
    [UIView transitionWithView: self.view
                      duration: 0.3
                       options: UIViewAnimationOptionCurveEaseInOut
                    animations: ^{
                        self.menuButton.alpha = 1.f;
                        [_menuDismissView removeFromSuperview];
                    } completion: NULL];
    
    _menuItemViews = nil;
}

- (IBAction) menuPushed:(id)sender {
    
    CGSize imageSize = self.view.bounds.size;
    UIGraphicsBeginImageContextWithOptions(imageSize, NO, 0.0);
    [self.contentView drawViewHierarchyInRect: self.contentView.bounds afterScreenUpdates: NO];
    UIImage *screenshot = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
    
    screenshot = [screenshot applyBlurWithRadius: 1.5
                                       tintColor: [UIColor colorWithWhite: 1.0 alpha: 0.3]
                           saturationDeltaFactor: 1
                                       maskImage: nil];
    
    UIImageView* imageView = [[UIImageView alloc] initWithImage: screenshot];
    imageView.userInteractionEnabled = YES;
    UITapGestureRecognizer* tapGesture = [[UITapGestureRecognizer alloc] initWithTarget: self action: @selector(menuItemPushed:)];
    tapGesture.delegate = self;
    
    [imageView addGestureRecognizer: tapGesture];
    
    [UIView transitionWithView: self.view
                      duration: 0.3
                       options: UIViewAnimationOptionCurveEaseIn
                    animations: ^{
                        [self.contentView insertSubview: imageView aboveSubview: self.menuButton];
                    } completion:^(BOOL finished) {
                        
                    }];
    _menuDismissView = imageView;
    
    AppMenuItem* currentItem = self.menuItems[_currentViewControllerIndex];
    NSMutableArray* remainingItems = [self.menuItems mutableCopy];
    [remainingItems removeObject: currentItem];
    [remainingItems insertObject: currentItem atIndex: 0];
    
    NSMutableArray* views = [NSMutableArray new];
    
    for(AppMenuItem* item in remainingItems) {
        CGFloat h = CGRectGetHeight(self.menuButton.bounds) + 16.;
        CGRect frame = CGRectMake(0, CGRectGetHeight(self.contentView.bounds)-h, CGRectGetWidth(self.view.bounds), h);
        AppMenuButton* itemView = [AppMenuButton menuButtonWithItem: item andFrame: frame];
        [itemView addTarget: self action: @selector(menuItemPushed:) forControlEvents: UIControlEventTouchUpInside];
        itemView.hasSeparator = item != [remainingItems objectAtIndex: 0];
        
        [self.contentView insertSubview: itemView aboveSubview: self.menuButton];
        
        [UIView animateWithDuration: 0.9
                              delay: 0.0
             usingSpringWithDamping: 0.4
              initialSpringVelocity: 0.0
                            options: UIViewAnimationOptionCurveEaseOut
                         animations: ^{
                             CGRect frame = itemView.frame;
                             frame.origin.y -= [views count] * CGRectGetHeight(itemView.bounds);;
                             itemView.frame = frame;
                         } completion: NULL];
        
        [views addObject: itemView];
    }
    
    _menuItemViews = [views copy];
    self.menuButton.alpha = 0.f;
    
}

#pragma mark - Notifications
- (void) locationChanged: (NSNotification*) notif {
    /*CLLocation* location = notif.userInfo[kCurrentLocationUserInfoKey];
    
    [PhotoGrabber getPhotoForLocation: location
                withCompletionHandler: ^(UIImage* image, NSError *error) {
                    self.imageView.image = image;
                    
                    CATransition *transition = [CATransition animation];
                    transition.duration = 1.0f;
                    transition.timingFunction = [CAMediaTimingFunction functionWithName:kCAMediaTimingFunctionEaseInEaseOut];
                    transition.type = kCATransitionFade;
                    
                    [self.imageView.layer addAnimation:transition forKey:nil];
                }];*/
}

- (void) contentUnlocked: (NSNotification*) notification {
    [self.bannerView loadRequest: nil];
}

#pragma mark - NSObject
+ (void) initialize {
    /*if( ![PhotoGrabber getPhotoForLocation: nil withCompletionHandler: nil]) {
        UIImage* img = [UIImage imageNamed: @"default-background"];
        [PhotoGrabber setPhoto: img];
    }*/
}

- (id) initWithCoder:(NSCoder *)aDecoder {
    self = [super initWithCoder: aDecoder];
    if( self ) {
        [[NSNotificationCenter defaultCenter] addObserver: self
                                                 selector: @selector(locationChanged:)
                                                     name: kCurrentLocationChangedNotification
                                                   object: nil];
#if IN_APP_PURCHASE_ENABLED
        [[NSNotificationCenter defaultCenter] addObserver: self
                                                 selector: @selector(contentUnlocked:)
                                                     name: kContentUnlockedNotification
                                                   object: nil];
#endif
        
    }
    return self;
}

- (void) dealloc {
    [[NSNotificationCenter defaultCenter] removeObserver: self];
}

#pragma mark - UIViewController;
-(void)viewDidLoad
{
    [super viewDidLoad];
    // Do any additional setup after loading the view.
    /*
    UIImage* currentImage = [PhotoGrabber getPhotoForLocation: nil
                                        withCompletionHandler: nil];
    UIImageView* imageView = [[UIImageView alloc] initWithImage: currentImage];
    imageView.frame = self.view.bounds;
    imageView.autoresizingMask = UIViewAutoresizingFlexibleHeight | UIViewAutoresizingFlexibleWidth;
    imageView.contentMode = UIViewContentModeScaleAspectFill;
    [self.view addSubview: imageView];
    self.imageView = imageView;
    
    
    UIColor* topColor = [UIColor colorWithRed: 0/255. green: 124/255. blue: 211/255. alpha: 1.];
    UIColor* bottomColor = [UIColor colorWithRed: 0/255. green: 124/255. blue: 211/255. alpha: 1.];
    
    CAGradientLayer* layer = [CAGradientLayer layer];
    layer.colors = @[(id)topColor.CGColor, (id)bottomColor.CGColor];
    layer.frame = self.view.bounds;
    layer.endPoint = CGPointMake(0.5, 1);
    layer.startPoint = CGPointMake(0.5, 0);
    [self.view.layer insertSublayer: layer atIndex: 0];
    */
    
    self.view.backgroundColor = [UIColor colorWithRed: 0/255. green: 124/255. blue: 211/255. alpha: 1.];
    UIView* view = [[UIView alloc] initWithFrame: self.view.bounds];// firstController.view;
    view.translatesAutoresizingMaskIntoConstraints = NO;
    view.backgroundColor = [UIColor clearColor];
    
    [self.view addSubview: view];
    self.contentView = view;
    
    
    [self.view addConstraints: [NSLayoutConstraint constraintsWithVisualFormat: @"H:|[view]|"
                                                                       options: 0
                                                                       metrics: nil
                                                                         views: NSDictionaryOfVariableBindings(view)]];
    [self.view addConstraints: [NSLayoutConstraint constraintsWithVisualFormat: @"V:|[view]"
                                                                       options: 0
                                                                       metrics: nil
                                                                         views: NSDictionaryOfVariableBindings(view)]];
    
    _bottomLayoutConstraint = [NSLayoutConstraint constraintWithItem: view
                                                           attribute: NSLayoutAttributeBottom
                                                           relatedBy: NSLayoutRelationEqual
                                                              toItem: self.view
                                                           attribute: NSLayoutAttributeBottom
                                                          multiplier: 1.0
                                                            constant: 0.0];
    [self.view addConstraint: _bottomLayoutConstraint];
}

- (void) viewWillAppear:(BOOL)animated {
    [super viewWillAppear: animated];
    
    AppMenuItem* firstItem = self.menuItems[_currentViewControllerIndex];
    
    if( !self.menuButton ) {
        
        NSParameterAssert(firstItem);
        
        UIViewController* firstController =  firstItem.controller;
        [self addMenuButtonWithImage: firstItem.image];
        [self addBannerView];
        [self displayView: firstController.view];
        [self.contentView insertSubview: firstController.view belowSubview: self.menuButton];
    }
    
    
    //Animate the current menu item
    CGFloat h = CGRectGetHeight(self.menuButton.bounds) + 16.;
    CGRect frame = CGRectMake(0, CGRectGetHeight(self.contentView.bounds)-h, CGRectGetWidth(self.view.bounds), h);
    AppMenuButton* itemView = [AppMenuButton menuButtonWithItem: firstItem andFrame: frame];
    itemView.hasSeparator = YES;
    itemView.translatesAutoresizingMaskIntoConstraints =  NO;
    [self.contentView insertSubview: itemView aboveSubview: self.menuButton];
    
    [self.contentView addConstraints: [NSLayoutConstraint constraintsWithVisualFormat: @"H:|[itemView]|"
                                                                              options: 0
                                                                              metrics: nil
                                                                                views: NSDictionaryOfVariableBindings(itemView)]];
    [self.contentView addConstraints: [NSLayoutConstraint constraintsWithVisualFormat: @"V:[itemView(==h)]|"
                                                                              options: 0
                                                                              metrics: @{ @"h" : @(h) }
                                                                                views: NSDictionaryOfVariableBindings(itemView)]];
    
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(1. * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        [UIView transitionWithView: self.contentView
                          duration: 0.3
                           options: UIViewAnimationOptionCurveEaseIn
                        animations: ^{
                            itemView.alpha = 0.f;
                        } completion: ^(BOOL finished){
                            [itemView removeFromSuperview];
                            
                            CABasicAnimation *theAnimation;
                            
                            theAnimation=[CABasicAnimation animationWithKeyPath:@"opacity"];
                            theAnimation.duration=0.3;
                            theAnimation.repeatCount=3;
                            theAnimation.autoreverses=YES;
                            theAnimation.fromValue=[NSNumber numberWithFloat:1.0];
                            theAnimation.toValue=[NSNumber numberWithFloat:0.0];
                            [self.menuButton.layer addAnimation:theAnimation forKey:@"animateOpacity"];
                        }];
    });
}

- (void) viewDidAppear:(BOOL)animated {
    [super viewDidAppear: animated];
    
#if IN_APP_PURCHASE_ENABLED
    if( ![ContentLock tryLock] ) {
#endif
        GADRequest* request = [GADRequest request];
        request.testDevices = @[ GAD_SIMULATOR_ID ];
        
        [self.bannerView loadRequest: request];
#if IN_APP_PURCHASE_ENABLED
    }
#endif
}

- (void) viewWillDisappear:(BOOL)animated {
    [super viewWillDisappear: animated];
    
    [self.bannerView loadRequest: nil];
}

- (void) encodeRestorableStateWithCoder:(NSCoder *)coder {
    NSLog(@"Save: %@", NSStringFromClass([self class]));
    [coder encodeInteger: _currentViewControllerIndex forKey: kStateResorationCurrentIndexKey];
    
    [super encodeRestorableStateWithCoder: coder];
}

- (void) decodeRestorableStateWithCoder:(NSCoder *)coder {
    NSLog(@"Restore: %@", NSStringFromClass([self class]));
    
    [super decodeRestorableStateWithCoder: coder];
    
    if( [coder containsValueForKey: kStateResorationCurrentIndexKey] ) {
        _currentViewControllerIndex = [coder decodeIntegerForKey: kStateResorationCurrentIndexKey];
    }
}

#pragma mark - UIGestureRecognizerDelegate
- (BOOL)gestureRecognizer:(UIGestureRecognizer *)gestureRecognizer shouldReceiveTouch:(UITouch *)touch {
    CGPoint location = [gestureRecognizer locationInView: self.view];
    
    for(UIView* view in _menuItemViews) {
        if( CGRectContainsPoint(view.frame, location) )
            return NO;
    }
    
    return YES;
}

#pragma mark - GADBannerViewDelegate
- (void)adViewDidReceiveAd:(GADBannerView *)view {
    _bottomLayoutConstraint.constant = -kGADAdSizeBanner.size.height;
    
    [UIView animateWithDuration: 0.3
                     animations: ^{
                         [self.view layoutIfNeeded];
                     }];
}

- (void)adView:(GADBannerView *)view didFailToReceiveAdWithError:(GADRequestError *)error {
    _bottomLayoutConstraint.constant = 0.;
    
    [UIView animateWithDuration: 0.3
                     animations: ^{
                         [self.view layoutIfNeeded];
                     }];
}

@end
