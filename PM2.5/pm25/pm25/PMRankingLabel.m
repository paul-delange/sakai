//
//  PMRankingLabel.m
//  pm25
//
//  Created by Paul de Lange on 30/03/2014.
//  Copyright (c) 2014 Chesterford. All rights reserved.
//

#import "PMRankingLabel.h"

@implementation PMRankingLabel

- (NSUInteger) pmValue {
    return [self.text integerValue];
}

- (void) drawRect:(CGRect)rect {
    
    UIBezierPath* borderPath = [UIBezierPath bezierPathWithRoundedRect: rect cornerRadius: 5.];
    CGContextRef ctx = UIGraphicsGetCurrentContext();
    UIColor* backgroundColor;
    
    if( self.pmValue > 70 ) {
        backgroundColor = [UIColor colorWithRed: 220/255. green: 80/255. blue: 80/255. alpha: 0.75];
    }
    else if( self.pmValue > 35 ) {
//        backgroundColor = [UIColor colorWithRed: 211/255. green: 220/255. blue: 56/255. alpha: 0.75];
        backgroundColor = [UIColor colorWithRed: 255/255. green: 255/255. blue: 0/255. alpha: 0.75];

    }
    else {
        backgroundColor = [UIColor colorWithWhite: 1 alpha: 0.85];
    }
    
    CGContextSetFillColorWithColor(ctx, [backgroundColor CGColor]);
    CGContextAddPath(ctx, [borderPath CGPath]);
    CGContextFillPath(ctx);
    
    [super drawRect: rect];
}

@end
