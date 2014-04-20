//
//  CustomerDetector.h
//  CustomerCounter
//
//  Created by Paul de Lange on 20/04/2014.
//  Copyright (c) 2014 Chesterford. All rights reserved.
//

#import <Foundation/Foundation.h>

@class CustomerDetector;

@protocol CustomerDetectorDelegate <NSObject>
@optional
- (void) customerDetector: (CustomerDetector*) detector detectedCustomers: (NSSet*) customers;

@end

@interface CustomerDetector : NSObject

@property (weak) id<CustomerDetectorDelegate> delegate;

- (void) start;
- (void) stop;

@end
