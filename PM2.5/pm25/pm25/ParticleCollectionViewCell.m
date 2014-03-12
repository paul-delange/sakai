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
        CGContextMoveToPoint(ctx, 0, 0);
        CGContextAddLineToPoint(ctx, CGRectGetWidth(rect), 0.0);
    }
    
    if( self.borderMask & kParticleBorderMaskRight ) {
        CGContextMoveToPoint(ctx, CGRectGetWidth(rect), 0);
        CGContextAddLineToPoint(ctx, CGRectGetWidth(rect), CGRectGetHeight(rect));
    }
    
    if( self.borderMask & kParticleBorderMaskBottom ) {
        CGContextMoveToPoint(ctx, 0, CGRectGetHeight(rect));
        CGContextAddLineToPoint(ctx, CGRectGetWidth(rect), CGRectGetHeight(rect));
    }
    
    if( self.borderMask & kParticleBorderMaskLeft ) {
        CGContextMoveToPoint(ctx, 0, 0);
        CGContextAddLineToPoint(ctx, 0, CGRectGetHeight(rect));
    }
    
    CGFloat dashes[] = { 3., 1. };
    CGContextSetLineWidth(ctx, 2);
    CGContextSetLineDash(ctx, 0, dashes, 2);
    
    CGContextMoveToPoint(ctx, 0, CGRectGetMidY(rect));
    CGContextAddLineToPoint(ctx, CGRectGetWidth(rect), CGRectGetMidY(rect));
    
    CGContextSetLineWidth(ctx, 1);
    CGContextSetLineDash(ctx, 0, dashes, 2);

    CGContextStrokePath(ctx);
}

@end
