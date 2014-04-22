//
//  CustomerDetector.m
//  CustomerCounter
//
//  Created by Paul de Lange on 20/04/2014.
//  Copyright (c) 2014 Chesterford. All rights reserved.
//

#import "CustomerDetector.h"

#import "FaceObject.h"
#import "EyeObject.h"

#include "findEyeCenter.h"

#import "Customer.h"
#import "CoreDataStack.h"
#import "AppDelegate.h"

#import <opencv2/opencv.hpp>

#import <AVFoundation/AVFoundation.h>

NSString * const CustomerCounterErrorDomain = @"CustomerCounter";

@interface CustomerDetector () <AVCaptureMetadataOutputObjectsDelegate> {
    dispatch_queue_t                        _dataProcessingQueue;
    
    AVCaptureSession*                       _captureSession;
    
    AVCaptureMetadataOutput*                _metatdataOutput;
    
    NSSet*                                _faces;
}

@end

@implementation CustomerDetector

- (void) start {
    NSParameterAssert(![_captureSession isRunning]);
    
    AVCaptureMetadataOutput* metadataOutput = [AVCaptureMetadataOutput new];
    
    if([_captureSession canAddOutput: metadataOutput]) {
        [_captureSession addOutput: metadataOutput];
    }
    else {
        if( [self.delegate respondsToSelector: @selector(customerDetector:encounteredError:)] ) {
            NSError* error = [NSError errorWithDomain: CustomerCounterErrorDomain
                                                 code: kCustomerCounterErrorCanNotAddMetadataOutput
                                             userInfo: nil];
            [self.delegate customerDetector: self encounteredError: error];
        }
        
        return;
    }
    
    if([metadataOutput.availableMetadataObjectTypes containsObject: AVMetadataObjectTypeFace]) {
        metadataOutput.metadataObjectTypes = @[AVMetadataObjectTypeFace];
    }
    else {
        if( [self.delegate respondsToSelector: @selector(customerDetector:encounteredError:)] ) {
            NSError* error = [NSError errorWithDomain: CustomerCounterErrorDomain
                                                 code: kCustomerCounterErrorNoFaceRecognition
                                             userInfo: nil];
            [self.delegate customerDetector: self encounteredError: error];
        }
        
        return;
    }
    
    _metatdataOutput = metadataOutput;
    [_metatdataOutput setMetadataObjectsDelegate: self queue: _dataProcessingQueue];
    
    [_captureSession startRunning];
}

- (void) stop {
    if( [_captureSession isRunning] ) {
        [_captureSession stopRunning];
    }
    
    [_metatdataOutput setMetadataObjectsDelegate: nil queue: nil];
    _metatdataOutput = nil;
    
    _faces = nil;
}

#pragma mark - NSObject
- (instancetype) init {
    self = [super init];
    
    if( self ) {
        _dataProcessingQueue = dispatch_queue_create("Data Processing", DISPATCH_QUEUE_SERIAL);
        
        NSString* preset = AVCaptureSessionPresetHigh;
        _captureSession = [AVCaptureSession new];
        if([_captureSession canSetSessionPreset: preset]) {
            _captureSession.sessionPreset = preset;
        }

#if TARGET_OS_IPHONE
        for(AVCaptureDevice* device in [AVCaptureDevice devicesWithMediaType: AVMediaTypeVideo]) {
            if( device.position == AVCaptureDevicePositionFront ) {
                
                __autoreleasing NSError* error;
                AVCaptureDeviceInput* defaultInput = [AVCaptureDeviceInput deviceInputWithDevice: device error: &error];
                NSAssert(!error, @"Error creating input device: %@", error);
                NSAssert([_captureSession canAddInput: defaultInput], @"Can not add device: %@", defaultInput);
                [_captureSession addInput: defaultInput];
                
                break;
            }
        }
#endif
    }
    
    return self;
}

#pragma mark - AVCaptureMetadataOutputObjectsDelegate
- (void)captureOutput:(AVCaptureOutput *)captureOutput didOutputMetadataObjects:(NSArray *)metadataObjects fromConnection:(AVCaptureConnection *)connection {
    
    if ( metadataObjects.count == 0 ) {
        _faces = nil;
        return;
    }
    
    @autoreleasepool {
        
        NSMutableSet* facesToSave = [NSMutableSet set];
        
        for ( AVMetadataObject *object in metadataObjects ) {
            if ( [[object type] isEqual:AVMetadataObjectTypeFace] ) {
                AVMetadataFaceObject* face = (AVMetadataFaceObject*)object;
                
                FaceObject* aFaceObject;
                NSSet* trackedAndMatchingFaces = [_faces filteredSetUsingPredicate: [NSPredicate predicateWithFormat: @"foundationID = %d", face.faceID]];
                aFaceObject = trackedAndMatchingFaces.anyObject;
                
                if( !aFaceObject ) {
                    aFaceObject = [FaceObject new];
                    aFaceObject.foundationID = face.faceID;
                }
                
                aFaceObject.bounds = [face bounds];
                aFaceObject.isFacingCamera = YES;//face.isFacingCamera;
                
                NSParameterAssert([face hasRollAngle]);
                NSParameterAssert([face hasYawAngle]);
                
                if( fabs(face.rollAngle) <= 45 && fabs(face.yawAngle) <= 45 ) {
                    if( !aFaceObject.hasBeenCounted ){
                        
                        dispatch_async(dispatch_get_main_queue(), ^{
                            AppDelegate* delegate = (AppDelegate*)[[UIApplication sharedApplication] delegate];
                            CoreDataStack* stack = delegate.stack;
                            
                            NSManagedObjectContext* context = stack.mainQueueManagedObjectContext;
                            Customer* customer = [Customer insertInManagedObjectContext: context];
                            customer.timestamp = [NSDate date];
                            
                            NSError* error;
                            [context threadSafeSave: &error];
                            DLogError(error);
                            
                            if( [self.delegate respondsToSelector: @selector(customerDetector:detectedCustomers:)] ) {
                                [self.delegate customerDetector: self detectedCustomers: [NSSet setWithObject: customer]];
                            }
                        });
                    }
                    
                    aFaceObject.hasBeenCounted = YES;
                }
                
                [facesToSave addObject: aFaceObject];
            }
        }
        
        _faces = [facesToSave copy];
    }
}

@end
