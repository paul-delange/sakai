//
//  AppMenuItem.m
//  pm25
//
//  Created by Paul de Lange on 9/03/2014.
//  Copyright (c) 2014 Chesterford. All rights reserved.
//

#import "AppMenuItem.h"

@implementation AppMenuItem

    - (instancetype) initWithViewController: (UIViewController*) controller image: (UIImage*) image andTitle: (NSString*) title {
        self = [super init];
        if( self ) {
            _controller = controller;
            _image = image;
            _title = [title copy];
        }
        return self;
    }
    
@end
