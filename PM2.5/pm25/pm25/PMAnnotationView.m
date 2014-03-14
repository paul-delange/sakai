//
//  PMAnnotationView.m
//  pm25
//
//  Created by Paul De Lange on 13/03/14.
//  Copyright (c) 2014 Chesterford. All rights reserved.
//

#import "PMAnnotationView.h"

#import "PMAnnotation.h"

@implementation PMAnnotationView

#pragma mark - UIView
- (void) drawRect:(CGRect)rect {
    [super drawRect: rect];
    
    PMAnnotation* ann = self.annotation;
    
    UIBezierPath* borderPath = [UIBezierPath bezierPathWithRoundedRect: rect cornerRadius: 5.];
    CGContextRef ctx = UIGraphicsGetCurrentContext();
    UIColor* backgroundColor;
    
    if( ann.pmValue > 70 ) {
        backgroundColor = [UIColor colorWithRed: 220/255. green: 80/255. blue: 80/255. alpha: 0.75];
    }
    else if( ann.pmValue > 35 ) {
        backgroundColor = [UIColor colorWithRed: 211/255. green: 220/255. blue: 56/255. alpha: 0.75];
    }
    else {
        backgroundColor = [UIColor colorWithWhite: 1 alpha: 0.75];
    }
    
    CGContextSetFillColorWithColor(ctx, [backgroundColor CGColor]);
    CGContextAddPath(ctx, [borderPath CGPath]);
    CGContextFillPath(ctx);
    
    NSDictionary* titleAttributes = @{
                                      NSForegroundColorAttributeName : [UIColor blackColor],
                                      NSFontAttributeName : [UIFont preferredFontForTextStyle: UIFontTextStyleBody]
                                      };
    
    CGSize titleSize = [ann.title sizeWithAttributes: titleAttributes];
    [ann.title drawAtPoint: CGPointMake((CGRectGetWidth(rect)-titleSize.width)/2., (CGRectGetHeight(rect)-titleSize.height)/2.)
            withAttributes: titleAttributes];
}

#pragma mark - MKAnnotationView
- (id) initWithAnnotation:(id<MKAnnotation>)annotation reuseIdentifier:(NSString *)reuseIdentifier {
    self = [super initWithAnnotation: annotation reuseIdentifier: reuseIdentifier];
    
    if( self ) {
        CGRect frame = self.frame;
        frame.size.width = 30;
        frame.size.height = 30;
        self.frame = frame;
        
        self.opaque = NO;
        
        self.layer.shadowColor = [[UIColor blackColor] CGColor];
        self.layer.shadowOpacity = 1.;
        self.layer.shadowRadius = 5.;
        self.layer.shadowOffset = CGSizeMake(0, 1);
    }
    
    return self;
}

- (void) prepareForReuse {
    [super prepareForReuse];
    
    [self setNeedsDisplay];
}

@end
