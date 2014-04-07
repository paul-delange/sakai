//
//  Magnet.m
//  App Stream
//
//  Created by de Lange Paul on 6/1/13.
//  Copyright (c) 2013 __MyCompanyName__. All rights reserved.
//

#import "Magnet.h"

@implementation Magnet

- (instancetype) init {
    self = [super initWithFilename: @"magnet.png"];
    if( self ) {
        self.dynamic = NO;
    }
    return self;
}

@end
