//
//  ForegroundPanel.m
//  pm25
//
//  Created by Paul de Lange on 9/03/2014.
//  Copyright (c) 2014 Chesterford. All rights reserved.
//

#import "ForegroundPanel.h"

@implementation ForegroundPanel

- (id)initWithCoder:(NSCoder *)aDecoder {
    self = [super initWithCoder: aDecoder];
    if( self ) {
        self.backgroundColor = [UIColor colorWithWhite: 0 alpha: 0.6];
        self.layer.cornerRadius = 10.;
    }
    
    return self;
}

@end
