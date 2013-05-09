//
//  Animation.m
//  App Stream
//
//  Created by de Lange Paul on 5/9/13.
//  Copyright (c) 2013 __MyCompanyName__. All rights reserved.
//

#import "Animation.h"

@interface Animation() {
    NSString* _keyPath;
}
@end

@implementation Animation
@synthesize toValue, fromValue;

- (instancetype) initWithKeyPath: (NSString*) keyPath {
    self = [super init];
    if( self ) {
        _keyPath = keyPath;
    }
    return self;
}

+ (instancetype) animationWithKeyPath: (NSString*) keyPath {
    return [[Animation alloc] initWithKeyPath: keyPath];
}

@end
