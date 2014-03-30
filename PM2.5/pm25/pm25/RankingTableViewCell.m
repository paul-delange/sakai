//
//  RankingTableViewCell.m
//  pm25
//
//  Created by Paul de Lange on 30/03/2014.
//  Copyright (c) 2014 Chesterford. All rights reserved.
//

#import "RankingTableViewCell.h"

@implementation RankingTableViewCell

- (id) initWithCoder:(NSCoder *)aDecoder {
    self = [super initWithCoder: aDecoder];
    if( self ) {
        self.backgroundColor = [UIColor clearColor];
        self.contentView.backgroundColor = [UIColor clearColor];
    }
    
    return self;
}

@end
