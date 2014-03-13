//
//  ParticleCollectionViewCell.m
//  pm25
//
//  Created by Paul De Lange on 12/03/14.
//  Copyright (c) 2014 Chesterford. All rights reserved.
//

#import "ParticleCollectionViewCell.h"

@implementation ParticleCollectionViewCell

- (void) setBorderMask:(kParticleBorderMask)borderMask {
    _borderMask = borderMask;
    [self setNeedsDisplay];
}

#pragma mark - UIView
- (void) layoutSubviews {
    [super layoutSubviews];
    [self setNeedsDisplay];
}

- (void) drawRect:(CGRect)rect {
    [super drawRect: rect];
    
    CGContextRef ctx = UIGraphicsGetCurrentContext();
    
    CGContextSetStrokeColorWithColor(ctx, [UIColor whiteColor].CGColor);
    
    if( self.borderMask & kParticleBorderMaskTop ) {
        CGContextMoveToPoint(ctx, 0, 1);
        CGContextAddLineToPoint(ctx, CGRectGetWidth(rect), 1.0);
    }
    
    if( self.borderMask & kParticleBorderMaskRight ) {
        CGContextMoveToPoint(ctx, CGRectGetWidth(rect)-1, 1);
        CGContextAddLineToPoint(ctx, CGRectGetWidth(rect)-1, CGRectGetHeight(rect)-1);
    }
    
    if( self.borderMask & kParticleBorderMaskBottom ) {
        CGContextMoveToPoint(ctx, 1, CGRectGetHeight(rect)-1);
        CGContextAddLineToPoint(ctx, CGRectGetWidth(rect)-1, CGRectGetHeight(rect)-1);
    }
    
    if( self.borderMask & kParticleBorderMaskLeft ) {
        CGContextMoveToPoint(ctx, 1, 1);
        CGContextAddLineToPoint(ctx, 1, CGRectGetHeight(rect)-1);
    }
    
    CGFloat dashes[] = { 3., 1. };
    
    
    
    CGContextMoveToPoint(ctx, 0, CGRectGetMidY(rect));
    CGContextAddLineToPoint(ctx, CGRectGetWidth(rect), CGRectGetMidY(rect));

    CGContextSetLineWidth(ctx, 1);
    CGContextSetLineDash(ctx, 0, dashes, 2);
    CGContextStrokePath(ctx);
}

@end
