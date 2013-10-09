//
//  ResignableNavigationViewController.m
//  QREvents
//
//  Created by Paul De Lange on 26/09/13.
//  Copyright (c) 2013 Toshimoto Sakai. All rights reserved.
//

#import "ResignableNavigationViewController.h"

//This is a known issue:
//  On iPad, when a view controller is presented as a modal view, the keyboard can not be dismissed. Normally, we can override this method
//  in the presented view controller. But when the parent is a navigation controller, it doesn't work. So we make this hack
@interface ResignableNavigationViewController ()

@end

@implementation ResignableNavigationViewController

- (BOOL)disablesAutomaticKeyboardDismissal {
    return NO;
}

@end
