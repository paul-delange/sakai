//
//  CustomerDetector.h
//  CustomerCounter
//
//  Created by Paul de Lange on 20/04/2014.
//  Copyright (c) 2014 Chesterford. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <AVFoundation/AVFoundation.h>

@class CustomerDetector;

extern NSString * const CustomerCounterErrorDomain;

enum {
    kCustomerCounterErrorCanNotAddMetadataOutput = 875,
    kCustomerCounterErrorNoFaceRecognition
};

@protocol CustomerDetectorDelegate <NSObject>
@optional
- (void) customerDetector: (CustomerDetector*) detector detectedCustomers: (NSSet*) customers;
- (void) customerDetector: (CustomerDetector*) detector encounteredError: (NSError*) error;

@end

@interface CustomerDetector : NSObject

@property (weak) id<CustomerDetectorDelegate> delegate;

- (void) start;
- (void) stop;

- (AVCaptureVideoPreviewLayer*) previewLayer;

@end
