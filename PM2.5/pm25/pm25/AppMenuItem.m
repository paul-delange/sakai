//
//  AppMenuItem.m
//  pm25
//
//  Created by Paul de Lange on 9/03/2014.
//  Copyright (c) 2014 Chesterford. All rights reserved.
//

#import "AppMenuItem.h"

#define NSCodingViewControllerNameKey       @"controller"
#define NSCodingImageDataKey                @"image"
#define NSCodingTitleKey                    @"title"

@interface AppMenuItem () {
    NSString* _imageName;
}

@end

@implementation AppMenuItem

- (instancetype) initWithViewController: (UIViewController*) controller image: (NSString*) imageName andTitle: (NSString*) title {
    self = [super init];
    if( self ) {
        _controller = controller;
        _imageName = imageName;
        _title = [title copy];
    }
    return self;
}

- (UIImage*) image {
    return [UIImage imageNamed: _imageName];
}

- (void)encodeWithCoder:(NSCoder *)aCoder {
    [aCoder encodeObject: _controller forKey: NSCodingViewControllerNameKey];
    [aCoder encodeObject: _imageName forKey: NSCodingImageDataKey];
    [aCoder encodeObject: _title forKey: NSCodingTitleKey];
}

- (id)initWithCoder:(NSCoder *)aDecoder {
    self = [super init];
    if( self ) {
        _title = [aDecoder decodeObjectForKey: NSCodingTitleKey];
        _imageName =[aDecoder decodeObjectForKey: NSCodingImageDataKey];
        _controller = [aDecoder decodeObjectForKey: NSCodingViewControllerNameKey];
    }
    
    return self;
}

@end
