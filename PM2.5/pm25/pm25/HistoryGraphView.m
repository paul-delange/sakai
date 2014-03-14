//
//  HistoryGraphView.m
//  pm25
//
//  Created by Paul De Lange on 12/03/14.
//  Copyright (c) 2014 Chesterford. All rights reserved.
//

#import "HistoryGraphView.h"

@interface HistoryGraphView ()

@end

@implementation HistoryGraphView

- (void) setPoints:(NSArray *)points {
    _points = [points sortedArrayUsingComparator: ^NSComparisonResult(id obj1, id obj2) {
        id date1 = obj1[@"time"];
        id date2 = obj2[@"time"];
        return [date1 compare: date2];
    }];
    
    [self setNeedsDisplay];
}

#pragma mark - NSObject
- (id) initWithCoder:(NSCoder *)aDecoder {
    self = [super initWithCoder: aDecoder];
    if( self ) {
        //_pointWidth = 10.;
        // 影なしに設定
        //self.clipsToBounds = NO;
        //self.layer.shadowColor = [UIColor blackColor].CGColor;
        //self.layer.shadowOpacity = 0.8;
        //self.layer.shadowRadius = 5.;
        //self.layer.shadowOffset = CGSizeMake(0, 2);
    }
    return self;
}

#pragma mark - UIView
- (void) layoutSubviews {
    [super layoutSubviews];
    
    [self setNeedsDisplay];
}

- (void) drawRect:(CGRect)rect {
    [super drawRect: rect];
    
    //NSLog(@"Rect: %@", NSStringFromCGRect(rect));
    
    NSUInteger numberOfPoints = [self.points count];
    
    if( numberOfPoints > 1 ) {
        CGContextRef ctx = UIGraphicsGetCurrentContext();
        
        CGFloat centers[numberOfPoints];
        CGFloat stride = CGRectGetWidth(rect) / numberOfPoints;
        CGFloat spacing = 20.;
        
        stride = MIN(stride, 35.);
        
        CGFloat offset = (CGRectGetWidth(rect) - numberOfPoints * stride)/2. + spacing/2.;
        CGFloat maxBarHeight = CGRectGetHeight(rect) * 0.65;
        CGFloat notchHeight = 5.;
       
        CGFloat lineCenterY = maxBarHeight + notchHeight;
        
        CGContextSetStrokeColorWithColor(ctx, [UIColor whiteColor].CGColor);
        
        for(NSUInteger i=0;i<numberOfPoints;i++) {
            //NSDictionary* point = self.points[i];
            centers[i] = i * stride + offset;
            
            CGContextMoveToPoint(ctx, centers[i], lineCenterY-notchHeight/2.);
            CGContextAddLineToPoint(ctx, centers[i], lineCenterY+notchHeight/2.);
            
        }
        
        CGContextMoveToPoint(ctx, centers[0], lineCenterY);
        CGContextAddLineToPoint(ctx, centers[numberOfPoints-1], lineCenterY);
        
        CGContextStrokePath(ctx);
        
        NSDictionary* labelAttributes = @{
                                          NSFontAttributeName : [UIFont systemFontOfSize: 9],
                                          NSForegroundColorAttributeName : [UIColor whiteColor]
                                          };
        
        
        __block CGFloat maxValue = 0.;
        
        [self.points enumerateObjectsUsingBlock: ^(id obj, NSUInteger idx, BOOL *stop) {
            NSDictionary* point = (NSDictionary*)obj;
            CGFloat value = [point[@"value"] floatValue];
            if( value > maxValue )
                maxValue = value;
        }];
        
        for(NSUInteger i=0;i<numberOfPoints;i++) {
            NSDictionary* point = self.points[i];
            NSString* value = point[@"value"];
            
            CGSize labelSize = [value sizeWithAttributes: labelAttributes];
            
            CGFloat percent = [value integerValue] / maxValue;
            
            //NSLog(@"%f, %@", percent, value);
            
            CGRect fillRect = CGRectMake(centers[i]-(stride-spacing)/2.,
                                         (1-percent) * maxBarHeight + labelSize.height,
                                         (stride-spacing),
                                         maxBarHeight * percent - labelSize.height);
            
            //NSLog(@"Bar: %f%% * %f = %f", percent * 100, maxBarHeight, CGRectGetHeight(fillRect));
            
            CGContextSetFillColorWithColor(ctx, [UIColor yellowColor].CGColor);
            CGContextFillRect(ctx, fillRect);
            
            CGRect valueRect = fillRect;
            valueRect.origin.y -= labelSize.height;
            valueRect.size.height = labelSize.height;
            valueRect.origin.x += (valueRect.size.width-labelSize.width)/2.f;
            valueRect.size.width = labelSize.width;
            
            [value drawInRect: valueRect withAttributes: labelAttributes];
        }

        for(NSUInteger i=0;i<numberOfPoints;i++) {
            NSDictionary* point = self.points[i];
            
            //Hack: going to chop out the time part
            NSString* fullDateString = point[@"time"];
            NSRange startTime = [fullDateString rangeOfString: @"\u2019" options: NSBackwardsSearch];
            fullDateString = [fullDateString substringFromIndex: startTime.location + startTime.length];
            NSRange endTime = [fullDateString rangeOfString: @":" options: NSBackwardsSearch];
            fullDateString = [fullDateString substringToIndex: endTime.location];
            
            CGSize labelSize = [fullDateString sizeWithAttributes: labelAttributes];
            
            CGRect labelRect = CGRectMake(centers[i]-(stride-1)/2.,
                                          CGRectGetHeight(rect)-labelSize.height,
                                          stride-1,
                                          labelSize.height);
            NSParameterAssert(labelSize.width <= labelRect.size.width);
            
            labelRect.origin.x += (labelRect.size.width-labelSize.width)/2.f;
            labelRect.size.width = labelSize.width;
            
            [fullDateString drawInRect: labelRect withAttributes: labelAttributes];
            
        }
    }
}

@end
