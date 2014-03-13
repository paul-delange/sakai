//
//  PMAnnotationView.m
//  pm25
//
//  Created by Paul De Lange on 13/03/14.
//  Copyright (c) 2014 Chesterford. All rights reserved.
//

#import "PMAnnotationView.h"

@implementation PMAnnotationView

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

- (void) drawRect:(CGRect)rect {
    [super drawRect: rect];
    
    UIBezierPath* borderPath = [UIBezierPath bezierPathWithRoundedRect: rect cornerRadius: 5.];
    CGContextRef ctx = UIGraphicsGetCurrentContext();
    UIColor* backgroundColor = [UIColor colorWithWhite: 0.75 alpha: 0.75];
    
    CGContextSetFillColorWithColor(ctx, [backgroundColor CGColor]);
    CGContextAddPath(ctx, [borderPath CGPath]);
    CGContextFillPath(ctx);
    
    NSDictionary* titleAttributes = @{
                                      NSForegroundColorAttributeName : [UIColor blackColor],
                                      NSFontAttributeName : [UIFont preferredFontForTextStyle: UIFontTextStyleBody]
                                      };
    
    MKPointAnnotation* ann = self.annotation;
    CGSize titleSize = [ann.title sizeWithAttributes: titleAttributes];
    [ann.title drawAtPoint: CGPointMake((CGRectGetWidth(rect)-titleSize.width)/2., (CGRectGetHeight(rect)-titleSize.height)/2.)
            withAttributes: titleAttributes];
}

@end
