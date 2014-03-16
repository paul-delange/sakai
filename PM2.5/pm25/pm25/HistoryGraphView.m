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
        
        //1. Fit all bars in the rect
        CGFloat stride = CGRectGetWidth(rect) / numberOfPoints;
        stride = MIN(stride, 35.);  //Limit maximum bar width
        
        //2. Set how much of the graph to be space
        CGFloat spacing = 0.7 * stride;
        
        //3. Calculate where to start drawing bars
        CGFloat offset = (CGRectGetWidth(rect) - numberOfPoints * stride)/2. + stride/2.f;
        
        //4. Calculate max height of bars
        CGFloat maxBarHeight = CGRectGetHeight(rect) * 0.65;
        
        //5. Small marks on scale line height
        CGFloat notchHeight = 5.;
       
        //6. Prepare font
        UIFont* font = [UIFont systemFontOfSize: 9];
        NSDictionary* labelAttributes = @{
                                          NSFontAttributeName : font,
                                          NSForegroundColorAttributeName : [UIColor whiteColor]
                                          };
        
        NSAssert(CGRectGetHeight(rect) > maxBarHeight + notchHeight + font.pointSize * 2,
                 @"Rect %@ is too small to draw a graph in", NSStringFromCGRect(rect));
        
        //7. Calculate scale line
        CGFloat lineCenterY = CGRectGetHeight(rect) - font.pointSize - notchHeight/2.;
        
        //8. Find maximum pm2.5 value to put into the maxBarHeight
        __block CGFloat maxValue = 0.; //Normally this: [[self.points valueForKeyPath: @"@max.value"] floatValue];
        [self.points enumerateObjectsUsingBlock: ^(id obj, NSUInteger idx, BOOL *stop) {
            NSDictionary* point = (NSDictionary*)obj;
            CGFloat value = [point[@"value"] floatValue];
            if( value > maxValue )
                maxValue = value;
        }];
        
        //9. Draw each bar from the bottom up
        for(NSUInteger i=0;i<numberOfPoints;i++) {
            NSDictionary* point = self.points[i];
            NSString* value = point[@"value"];
            NSString* fullDateString = point[@"time"];

            CGSize labelSize = [value sizeWithAttributes: labelAttributes];
            CGFloat center = i * stride + offset;
            
            //10. Draw time label
            
            //Hack: going to chop out the time part
            NSRange startTime = [fullDateString rangeOfString: @"\u2019" options: NSBackwardsSearch];
            fullDateString = [fullDateString substringFromIndex: startTime.location + startTime.length];
            NSRange endTime = [fullDateString rangeOfString: @":" options: NSBackwardsSearch];
            fullDateString = [fullDateString substringToIndex: endTime.location];
            
            NSDictionary* timeLabelAttributes = labelAttributes;
            CGSize timeLabelSize = [fullDateString sizeWithAttributes: labelAttributes];
            
            while (timeLabelSize.width > stride) {
                UIFont* timeLabelFont = [font fontWithSize: font.pointSize-1];
                NSMutableDictionary* timeLabelAttributes = [labelAttributes mutableCopy];
                [timeLabelAttributes setObject: timeLabelFont forKey: NSFontAttributeName];
                timeLabelSize = [fullDateString sizeWithAttributes: timeLabelAttributes];
            }
            
            CGRect timeLabelRect = CGRectMake(center-timeLabelSize.width/2.,
                                              CGRectGetHeight(rect)-labelSize.height,
                                              timeLabelSize.width,
                                              labelSize.height);
            
            CGContextSetStrokeColorWithColor(ctx, [UIColor whiteColor].CGColor);
            [fullDateString drawInRect: timeLabelRect withAttributes: timeLabelAttributes];
            
            //11. Draw notch
            
            CGContextMoveToPoint(ctx, center, lineCenterY-notchHeight/2.);
            CGContextAddLineToPoint(ctx, center, lineCenterY+notchHeight/2.);
            CGContextStrokePath(ctx);
            
            //12. Draw bar
            
            CGFloat percentOfMax = [value integerValue] / maxValue;
            CGFloat barHeight = maxBarHeight * percentOfMax;
            CGRect barRect = CGRectMake(center - (stride-spacing)/2.,
                                        lineCenterY - notchHeight/2.f - barHeight,
                                        (stride-spacing),
                                        barHeight);
            
           // NSLog(@"%@, %f, %f, %@", value, percentOfMax, barHeight, NSStringFromCGRect(barRect));
            
            CGContextSetFillColorWithColor(ctx, [UIColor yellowColor].CGColor);
            CGContextFillRect(ctx, barRect);
            
            //13. Draw value label
            NSDictionary* valueLabelAttributes = labelAttributes;
            CGSize valueLabelSize = [value sizeWithAttributes: valueLabelAttributes];
            while (valueLabelSize.width > stride) {
                UIFont* valueLabelFont = [font fontWithSize: font.pointSize-1];
                NSMutableDictionary* valueLabelAttributes = [labelAttributes mutableCopy];
                [valueLabelAttributes setObject: valueLabelFont forKey: NSFontAttributeName];
                valueLabelSize = [fullDateString sizeWithAttributes: valueLabelAttributes];
            }
            
            CGRect valueLabelRect = CGRectMake(center-valueLabelSize.width/2.,
                                               CGRectGetMinY(barRect) - valueLabelSize.height,
                                               valueLabelSize.width,
                                               valueLabelSize.height);
            CGContextSetStrokeColorWithColor(ctx, [UIColor whiteColor].CGColor);
            [value drawInRect: valueLabelRect withAttributes: timeLabelAttributes];
            
            /*
            CGContextSetStrokeColorWithColor(ctx, [UIColor whiteColor].CGColor);
            CGContextMoveToPoint(ctx, centers[i], lineCenterY-notchHeight/2.);
            CGContextAddLineToPoint(ctx, centers[i], lineCenterY+notchHeight/2.);
             CGContextStrokePath(ctx);
            
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
            
            //Hack: going to chop out the time part
            
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
             */
        }

        /*
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
        
         */
        /*
        CGContextSetStrokeColorWithColor(ctx, [UIColor whiteColor].CGColor);
        
        CGContextMoveToPoint(ctx, centers[0], lineCenterY);
        CGContextAddLineToPoint(ctx, centers[numberOfPoints-1], lineCenterY);
        
        CGContextStrokePath(ctx);*/
    }
}

@end
