//
//  AppContainerViewController.h
//  pm25
//
//  Created by Paul de Lange on 9/03/2014.
//  Copyright (c) 2014 Chesterford. All rights reserved.
//

@interface AppContainerViewController : UIViewController

@property (copy, nonatomic) IBOutletCollection(UIViewController) NSArray* menuItems;
@property (strong, nonatomic) UIImage* menuIcon;

@property (copy, readonly) NSArray* viewControllers;
@property (strong, readonly) UIViewController* topViewController;

- (void) setSelectedViewControllerIndex: (NSInteger) index animated: (BOOL) animated;

@end

