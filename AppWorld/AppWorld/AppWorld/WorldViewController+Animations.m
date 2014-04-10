//
//  WorldViewController+Animations.m
//  AppWorld
//
//  Created by Paul de Lange on 10/04/2014.
//  Copyright (c) 2014 Tall Developments. All rights reserved.
//

#import "WorldViewController+Animations.h"

#define kViewTagVignette    4415

@interface WorldViewController (AnimationsInternal)

@property (weak) UIView* vignetteView;

@end

@implementation WorldViewController (AnimationsInternal)

- (void) setVignetteView:(UIView *)vignetteView {
    [[self.view viewWithTag: kViewTagVignette] setTag: 0];
    
    vignetteView.tag = kViewTagVignette;
}

- (UIView*) vignetteView {
    return [self.view viewWithTag: kViewTagVignette];
}

- (void) showVignette: (BOOL) show animated: (BOOL) animated {
    
    if( show ) {
        if( self.vignetteView )
            return;
        
        CGRect bounds = self.view.bounds;
        
        UIGraphicsBeginImageContextWithOptions(bounds.size, NO, [UIScreen mainScreen].scale);
        CGContextRef ctx = UIGraphicsGetCurrentContext();
        
        CGColorSpaceRef colorSpace = CGColorSpaceCreateDeviceGray();
        CFMutableArrayRef colors = CFArrayCreateMutable(NULL, 2, NULL);
        
        CGColorRef centerColor = [[UIColor clearColor] CGColor];
        CGColorRef outsideColor = [[UIColor blackColor] CGColor];
        
        CFArraySetValueAtIndex(colors, 0, centerColor);
        CFArraySetValueAtIndex(colors, 1, outsideColor);
        
        const CGFloat locations[2] = { 0., 1. };
        
        CGGradientRef gradient = CGGradientCreateWithColors(colorSpace,
                                                            colors,
                                                            locations);
        CGContextDrawRadialGradient(ctx,
                                    gradient,
                                    CGPointMake(CGRectGetMidX(bounds), CGRectGetMidY(bounds)),
                                    0,
                                    CGPointMake(CGRectGetMidX(bounds), CGRectGetMidY(bounds)),
                                    200,
                                    kCGGradientDrawsBeforeStartLocation | kCGGradientDrawsAfterEndLocation);
        
        
        UIImage *blank = UIGraphicsGetImageFromCurrentImageContext();
        UIGraphicsEndImageContext();
        
        
        UIImageView* imageView = [[UIImageView alloc] initWithImage: blank];
        imageView.backgroundColor = [UIColor clearColor];
        
        [self.view addSubview: imageView];
        
        CGRect afterFrame = imageView.frame;
        CGRect beforeFrame = CGRectInset(afterFrame, -500, -500);
        
        imageView.frame = beforeFrame;
        imageView.alpha = 0.;
        
        [UIView animateWithDuration: 1.0 * animated animations:^{
            imageView.frame = afterFrame;
            imageView.alpha = 1.;
        }];
        
        self.vignetteView = imageView;
    }
    else {
        UIView* v = self.vignetteView;
        self.vignetteView = nil;
        
        CGRect afterFrame = CGRectInset(v.frame, -500, -500);
        
        [UIView animateWithDuration: 1.0 * animated animations: ^{
            v.frame = afterFrame;
            v.alpha = 0.;
        } completion: ^(BOOL finished) {
            [v removeFromSuperview];
        }];
    }
}

@end
