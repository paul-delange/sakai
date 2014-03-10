//
//  AppContainerViewController.h
//  pm25
//
//  Created by Paul de Lange on 9/03/2014.
//  Copyright (c) 2014 Chesterford. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface AppContainerViewController : UIViewController

@property (copy, nonatomic) IBOutletCollection(UIViewController) NSArray* menuItems;

@property (copy, readonly) NSArray* viewControllers;

@end
