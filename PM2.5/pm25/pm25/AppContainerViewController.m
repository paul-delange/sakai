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
#import "PhotoGrabber.h"
#import "UIImage+ImageEffects.h"

@interface AppContainerViewController () <UIGestureRecognizerDelegate> {
    NSUInteger      _currentViewControllerIndex;
    NSArray*        _menuItemViews;
    __weak UIView*  _menuDismissView;
}

@property (weak) UIButton* menuButton;
@property (weak) UIImageView* imageView;

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
    
    _currentViewControllerIndex = 0;
    
    if( [self isViewLoaded] ) {
        UIViewController* firstController =  [self.viewControllers count] > _currentViewControllerIndex ? self.viewControllers[_currentViewControllerIndex] : nil;
        UIView* view = firstController.view;
        view.translatesAutoresizingMaskIntoConstraints = NO;
        
        [self.view addSubview: view];
        
        [self.view addConstraints: [NSLayoutConstraint constraintsWithVisualFormat: @"H:|[view]|"
                                                                           options: 0
                                                                           metrics: nil
                                                                             views: NSDictionaryOfVariableBindings(view)]];
        [self.view addConstraints: [NSLayoutConstraint constraintsWithVisualFormat: @"V:|[view]|"
                                                                           options: 0
                                                                           metrics: nil
                                                                             views: NSDictionaryOfVariableBindings(view)]];
    }
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
        
        //NSLog(@"Hold: %d, selected %d", shouldHoldSelection, isSelectedItem);
        
        [UIView animateWithDuration: 0.3
                              delay: 0
                            options: UIViewAnimationOptionCurveEaseInOut
                         animations: ^{
                             CGRect frame = itemView.frame;
                             frame.origin.y = [self.topLayoutGuide length];
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
        view.translatesAutoresizingMaskIntoConstraints = NO;
        view.backgroundColor = [UIColor clearColor];
        view.alpha = 0.f;
        [self.view insertSubview: view belowSubview: self.menuButton];
        
        [self.view addConstraints: [NSLayoutConstraint constraintsWithVisualFormat: @"H:|[view]|"
                                                                           options: 0
                                                                           metrics: nil
                                                                             views: NSDictionaryOfVariableBindings(view)]];
        [self.view addConstraints: [NSLayoutConstraint constraintsWithVisualFormat: @"V:|[view]|"
                                                                           options: 0
                                                                           metrics: nil
                                                                             views: NSDictionaryOfVariableBindings(view)]];
        [self.menuButton setImage: newItem.image forState: UIControlStateNormal];
        
        [UIView transitionWithView: self.view
                          duration: 0.3
                           options: UIViewAnimationOptionCurveEaseInOut
                        animations: ^{
                            
                            view.alpha = 1.f;
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
    [self.view drawViewHierarchyInRect: self.view.bounds afterScreenUpdates: NO];
    UIImage *screenshot = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
    
    screenshot = [screenshot applyBlurWithRadius: 5
                                       tintColor: [UIColor colorWithWhite: 1.0 alpha: 0.3]
                           saturationDeltaFactor: 1.8
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
                        [self.view addSubview: imageView];
                    } completion:^(BOOL finished) {
                        
                    }];
    _menuDismissView = imageView;
    
    AppMenuItem* currentItem = self.menuItems[_currentViewControllerIndex];
    NSMutableArray* remainingItems = [self.menuItems mutableCopy];
    [remainingItems removeObject: currentItem];
    [remainingItems insertObject: currentItem atIndex: 0];
    
    NSMutableArray* views = [NSMutableArray new];
    
    for(AppMenuItem* item in remainingItems) {
        CGRect frame = CGRectMake(0, [self.topLayoutGuide length], CGRectGetWidth(self.view.bounds), CGRectGetHeight(self.menuButton.bounds) + 16.);
        AppMenuButton* itemView = [AppMenuButton menuButtonWithItem: item andFrame: frame];
        [itemView addTarget: self action: @selector(menuItemPushed:) forControlEvents: UIControlEventTouchUpInside];
        itemView.hasSeparator = item != remainingItems.lastObject;
        
        [self.view addSubview: itemView];
        
        [UIView animateWithDuration: 0.9
                              delay: 0.0
             usingSpringWithDamping: 0.4
              initialSpringVelocity: 0.0
                            options: UIViewAnimationOptionCurveEaseOut
                         animations: ^{
                             CGRect frame = itemView.frame;
                             frame.origin.y += [views count] * CGRectGetHeight(itemView.bounds);;
                             itemView.frame = frame;
                         } completion: NULL];
        
        [views addObject: itemView];
    }
    
    _menuItemViews = [views copy];
    self.menuButton.alpha = 0.f;
    
}

#pragma mark - Notifications
- (void) locationChanged: (NSNotification*) notif {
    CLLocation* location = notif.userInfo[kCurrentLocationUserInfoKey];
    
    [PhotoGrabber getPhotoForLocation: location
                withCompletionHandler: ^(UIImage* image, NSError *error) {
                    self.imageView.image = image;
                    
                    CATransition *transition = [CATransition animation];
                    transition.duration = 1.0f;
                    transition.timingFunction = [CAMediaTimingFunction functionWithName:kCAMediaTimingFunctionEaseInEaseOut];
                    transition.type = kCATransitionFade;
                    
                    [self.imageView.layer addAnimation:transition forKey:nil];
                }];
}

#pragma mark - NSObject
- (id) initWithCoder:(NSCoder *)aDecoder {
    self = [super initWithCoder: aDecoder];
    if( self ) {
        [[NSNotificationCenter defaultCenter] addObserver: self
                                                 selector: @selector(locationChanged:)
                                                     name: kCurrentLocationChangedNotification
                                                   object: nil];
        
    }
    return self;
}

- (void) dealloc {
    [[NSNotificationCenter defaultCenter] removeObserver: self
                                                    name: kCurrentLocationChangedNotification
                                                  object: nil];
}

#pragma mark - UIViewController;
-(void)viewDidLoad
{
    [super viewDidLoad];
    // Do any additional setup after loading the view.
    
    UIImage* currentImage = [PhotoGrabber getPhotoForLocation: nil
                                        withCompletionHandler: nil];
    UIImageView* imageView = [[UIImageView alloc] initWithImage: currentImage];
    imageView.frame = self.view.bounds;
    imageView.autoresizingMask = UIViewAutoresizingFlexibleHeight | UIViewAutoresizingFlexibleWidth;
    imageView.contentMode = UIViewContentModeScaleAspectFill;
    [self.view addSubview: imageView];
    self.imageView = imageView;
    
    AppMenuItem* firstItem = [self.menuItems count] > _currentViewControllerIndex ? self.menuItems[_currentViewControllerIndex] : nil;
    NSParameterAssert(firstItem);
    
    UIImage* menuImage = firstItem.image;
    UIButton* menuButton = [UIButton buttonWithType: UIButtonTypeCustom];
    menuButton.frame = CGRectMake(CGRectGetWidth(self.view.bounds)-menuImage.size.width, 0, menuImage.size.width, menuImage.size.height);
    [menuButton setImage: menuImage forState: UIControlStateNormal];
    menuButton.translatesAutoresizingMaskIntoConstraints = NO;
    [menuButton addTarget: self action: @selector(menuPushed:) forControlEvents: UIControlEventTouchUpInside];
    
    UIViewController* firstController =  firstItem.controller;
    UIView* view = firstController.view;
    view.translatesAutoresizingMaskIntoConstraints = NO;
    view.backgroundColor = [UIColor clearColor];
    
    [self.view addSubview: view];
    
    [self.view addSubview: menuButton];
    self.menuButton = menuButton;
    
    id topGuide = self.topLayoutGuide;
    
    [self.view addConstraints: [NSLayoutConstraint constraintsWithVisualFormat: @"H:|[view]|"
                                                                       options: 0
                                                                       metrics: nil
                                                                         views: NSDictionaryOfVariableBindings(view)]];
    [self.view addConstraints: [NSLayoutConstraint constraintsWithVisualFormat: @"V:|[view]|"
                                                                       options: 0
                                                                       metrics: nil
                                                                         views: NSDictionaryOfVariableBindings(view)]];
    [self.view addConstraints: [NSLayoutConstraint constraintsWithVisualFormat: @"H:[menuButton]-|"
                                                                       options: 0
                                                                       metrics: nil
                                                                         views: NSDictionaryOfVariableBindings(menuButton)]];
    [self.view addConstraints: [NSLayoutConstraint constraintsWithVisualFormat: @"V:|[topGuide]-[menuButton]"
                                                                       options: 0
                                                                       metrics: nil
                                                                         views: NSDictionaryOfVariableBindings(topGuide, menuButton)]];
    
    
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

@end
