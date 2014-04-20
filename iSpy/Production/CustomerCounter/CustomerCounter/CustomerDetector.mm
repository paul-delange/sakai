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

#import <opencv2/opencv.hpp>

#import <AVFoundation/AVFoundation.h>

@interface CustomerDetector () <AVCaptureMetadataOutputObjectsDelegate> {
    dispatch_queue_t                        _dataProcessingQueue;
    
    AVCaptureSession*                       _captureSession;
    
    AVCaptureMetadataOutput*                _metatdataOutput;
    
    NSSet*                                _faces;
}

@end

@implementation CustomerDetector

- (void) start {
    [_captureSession startRunning];
}

- (void) stop {
    [_captureSession stopRunning];
    _faces = nil;
}

#pragma mark - NSObject
- (instancetype) init {
    self = [super init];
    
    if( self ) {
        _dataProcessingQueue = dispatch_queue_create("Data Processing", DISPATCH_QUEUE_SERIAL);
        
        NSString* preset = AVCaptureSessionPresetHigh;
        _captureSession = [AVCaptureSession new];
        NSParameterAssert([_captureSession canSetSessionPreset: preset]);
        _captureSession.sessionPreset = preset;
        
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

        _metatdataOutput = [AVCaptureMetadataOutput new];
        
        
        NSAssert([_captureSession canAddOutput: _metatdataOutput], @"Can not add %@ to capture session", _metatdataOutput);
        
        [_metatdataOutput setMetadataObjectsDelegate: self queue: dispatch_get_main_queue()];
        [_captureSession addOutput: _metatdataOutput];
        
        NSAssert([_metatdataOutput.availableMetadataObjectTypes containsObject: AVMetadataObjectTypeFace], @"No face recognition on this device");
        
        _metatdataOutput.metadataObjectTypes = @[AVMetadataObjectTypeFace];

    }
    
    return self;
}

#pragma mark - AVCaptureMetadataOutputObjectsDelegate
- (void)captureOutput:(AVCaptureOutput *)captureOutput didOutputMetadataObjects:(NSArray *)metadataObjects fromConnection:(AVCaptureConnection *)connection {
    NSParameterAssert([NSThread isMainThread]);
    
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
                
                [facesToSave addObject: aFaceObject];
            }
        }
        
        _faces = [facesToSave copy];
    }
}

@end
