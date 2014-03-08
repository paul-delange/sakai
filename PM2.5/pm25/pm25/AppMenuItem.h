//
//  AppMenuItem.h
//  pm25
//
//  Created by Paul de Lange on 9/03/2014.
//  Copyright (c) 2014 Chesterford. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface AppMenuItem : NSObject

    - (instancetype) initWithViewController: (UIViewController*) controller image: (UIImage*) image andTitle: (NSString*) title;
    
    @property (readonly, weak) UIViewController* controller;
    @property (readonly, strong) UIImage* image;
    @property (readonly, copy) NSString* title;
    
@end
