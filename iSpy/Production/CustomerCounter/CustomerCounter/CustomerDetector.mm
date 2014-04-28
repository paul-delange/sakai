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

static inline cv::Rect CVRectFromCGRect(CGRect rect) {
    return cv::Rect(rect.origin.x, rect.origin.y, rect.size.width, rect.size.height);
}

static inline AVCaptureVideoOrientation AVCaptureVideoOrientationFromUIDeviceOrientation(UIDeviceOrientation orientation) {
   // NSLog(@"Orientation: %d", orientation);
    
    switch (orientation) {
        case UIDeviceOrientationPortrait:
            return AVCaptureVideoOrientationPortrait;
        case UIDeviceOrientationPortraitUpsideDown:
            return AVCaptureVideoOrientationPortraitUpsideDown;
        case UIDeviceOrientationLandscapeLeft:
            return AVCaptureVideoOrientationLandscapeRight;
        case UIDeviceOrientationLandscapeRight:
            return AVCaptureVideoOrientationLandscapeLeft;
        default:
            return AVCaptureVideoOrientationPortrait;
    }
}

static CGImageRef CGImageCreateFromOpenCVMatrix(cv::Mat* cvMat) {
    
    CFDataRef data = CFDataCreate(NULL, cvMat->data, cvMat->elemSize() * cvMat->total());
    
    CGColorSpaceRef colorSpace;
    
    if (cvMat->elemSize() == 1) {
        colorSpace = CGColorSpaceCreateDeviceGray();
    } else {
        colorSpace = CGColorSpaceCreateDeviceRGB();
    }
    
    CGDataProviderRef provider = CGDataProviderCreateWithCFData(data);
    
    // Creating CGImage from cv::Mat
    CGImageRef imageRef = CGImageCreate(cvMat->cols,                                 //width
                                        cvMat->rows,                                 //height
                                        8,                                          //bits per component
                                        8 * cvMat->elemSize(),                       //bits per pixel
                                        cvMat->step[0],                            //bytesPerRow
                                        colorSpace,                                 //colorspace
                                        kCGImageAlphaNone|kCGBitmapByteOrderDefault,// bitmap info
                                        provider,                                   //CGDataProviderRef
                                        NULL,                                       //decode
                                        false,                                      //should interpolate
                                        kCGRenderingIntentDefault                   //intent
                                        );
    
    
    CGDataProviderRelease(provider);
    CGColorSpaceRelease(colorSpace);
    CFRelease(data);
    
    return imageRef;
}

@interface CustomerDetector () <AVCaptureMetadataOutputObjectsDelegate, AVCaptureVideoDataOutputSampleBufferDelegate> {
    AVCaptureSession*                       _captureSession;
    
    dispatch_queue_t                        _dataProcessingQueue;
    dispatch_queue_t                        _videoProcessingQueue;
    
    AVCaptureMetadataOutput*                _metatdataOutput;
    AVCaptureVideoDataOutput*               _videoDataOutput;
    
    NSHashTable*                            _previewLayers;
}

@property (copy, atomic) NSSet* faces;

@end

@implementation CustomerDetector

- (AVCaptureVideoPreviewLayer*) previewLayer {
    AVCaptureVideoPreviewLayer* layer = [[AVCaptureVideoPreviewLayer alloc] initWithSession: _captureSession];
    [layer setVideoGravity: AVLayerVideoGravityResizeAspect];
    layer.connection.videoOrientation = AVCaptureVideoOrientationFromUIDeviceOrientation([[UIDevice currentDevice] orientation]);
    [_previewLayers addObject: layer];
    return layer;
}

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
    
    _videoDataOutput = [AVCaptureVideoDataOutput new];
    _videoDataOutput.videoSettings = @{
                                       (id)kCVPixelBufferPixelFormatTypeKey : @(kCVPixelFormatType_420YpCbCr8BiPlanarFullRange)
                                       };
    _videoDataOutput.alwaysDiscardsLateVideoFrames = YES;
    
    if( [_captureSession canAddOutput: _videoDataOutput] ) {
        [_captureSession addOutput: _videoDataOutput];
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
    
    [_videoDataOutput setSampleBufferDelegate: self queue: _videoProcessingQueue];
    
    AVCaptureConnection* videoConnection = [_videoDataOutput connectionWithMediaType: AVMediaTypeVideo];
    videoConnection.videoOrientation = AVCaptureVideoOrientationFromUIDeviceOrientation([[UIDevice currentDevice] orientation]);
    
    [_captureSession startRunning];
}

- (void) stop {
    if( [_captureSession isRunning] ) {
        [_captureSession stopRunning];
    }
    
    [_metatdataOutput setMetadataObjectsDelegate: nil queue: nil];
    _metatdataOutput = nil;
    
    [_videoDataOutput setSampleBufferDelegate: nil queue: nil];
    _videoDataOutput = nil;
    
    _faces = nil;
}

- (IBAction) deviceOrientationChanged:(NSNotification*)sender {
    UIDeviceOrientation orientation = [[UIDevice currentDevice] orientation];
    
    for(AVCaptureVideoPreviewLayer* layer in _previewLayers) {
        AVCaptureConnection* connection = layer.connection;
        connection.videoOrientation = AVCaptureVideoOrientationFromUIDeviceOrientation(orientation);
    }
    
    AVCaptureConnection* videoConnection = [_videoDataOutput connectionWithMediaType: AVMediaTypeVideo];
    videoConnection.videoOrientation = AVCaptureVideoOrientationFromUIDeviceOrientation(orientation);
}

#pragma mark - NSObject
- (instancetype) init {
    self = [super init];
    
    if( self ) {
        _dataProcessingQueue = dispatch_queue_create("Data Processing", DISPATCH_QUEUE_SERIAL);
        _videoProcessingQueue = dispatch_queue_create("Video Processing", DISPATCH_QUEUE_SERIAL);
        
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
        
        _previewLayers = [NSHashTable weakObjectsHashTable];
        
        [[NSNotificationCenter defaultCenter] addObserver: self
                                                 selector: @selector(deviceOrientationChanged:)
                                                     name: UIDeviceOrientationDidChangeNotification
                                                   object: nil];
    }
    
    return self;
}

- (void) dealloc {
    [[NSNotificationCenter defaultCenter] removeObserver: self];
}

#pragma mark - AVCaptureMetadataOutputObjectsDelegate
- (void)captureOutput:(AVCaptureOutput *)captureOutput didOutputMetadataObjects:(NSArray *)metadataObjects fromConnection:(AVCaptureConnection *)connection {
    
    [CATransaction begin];
	[CATransaction setValue:(id)kCFBooleanTrue forKey:kCATransactionDisableActions];
    
    for(AVCaptureVideoPreviewLayer* layer in _previewLayers) {
        NSArray *sublayers = [NSArray arrayWithArray:[layer sublayers]];
        NSInteger sublayersCount = [sublayers count], currentSublayer = 0;
        
        // hide all the face layers
        for ( CALayer *layer in sublayers ) {
            if ( [[layer name] isEqualToString:@"FaceLayer"] )
                [layer setHidden:YES];
        }
        
        if( metadataObjects.count == 0 ) {
            break;
        }
        
        for ( AVMetadataObject *object in metadataObjects ) {
            if ( [[object type] isEqual:AVMetadataObjectTypeFace] ) {
                AVMetadataFaceObject* face = (AVMetadataFaceObject*)object;
             
                AVMetadataFaceObject * adjusted = (AVMetadataFaceObject*)[layer transformedMetadataObjectForMetadataObject:face];
                
                // Do interesting things with this face
                CALayer *featureLayer = nil;
                
                // re-use an existing layer if possible
                while ( !featureLayer && (currentSublayer < sublayersCount) ) {
                    CALayer *currentLayer = [sublayers objectAtIndex:currentSublayer++];
                    if ( [[currentLayer name] isEqualToString:@"FaceLayer"] ) {
                        featureLayer = currentLayer;
                        [currentLayer setHidden:NO];
                    }
                }
                
                // create a new one if necessary
                if ( !featureLayer ) {
                    featureLayer = [[CALayer alloc]init];
                    featureLayer.borderColor = [UIColor redColor].CGColor;
                    featureLayer.borderWidth = 2.;
                    //featureLayer.contents = (id)[UIImage imageNamed:@"border"].CGImage;
                    [featureLayer setName:@"FaceLayer"];
                    [layer addSublayer:featureLayer];
                    featureLayer = nil;
                }
                
                [featureLayer setFrame: [adjusted bounds]];
            }
        }
    }
    
    [CATransaction commit];
    
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
                
                /*if( fabs(face.rollAngle) <= 45 && fabs(face.yawAngle) <= 45 ) {
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
                } */
                
                [facesToSave addObject: aFaceObject];
            }
        }
        
        self.faces = facesToSave;
        
    }
}

#pragma mark - AVCaptureVideoDataOutputSampleBufferDelegate
- (void)captureOutput:(AVCaptureOutput *)captureOutput didOutputSampleBuffer:(CMSampleBufferRef)sampleBuffer fromConnection:(AVCaptureConnection *)connection {

    CVImageBufferRef imageBuffer = CMSampleBufferGetImageBuffer(sampleBuffer);
    
    //Images are coming in YUV format, the first channel is the intensity (luma)...
    size_t lumaPlane = 0;
    
    CVPixelBufferLockBaseAddress(imageBuffer, 0);
    
    uint8_t* baseAddress = (uint8_t*)CVPixelBufferGetBaseAddressOfPlane(imageBuffer, lumaPlane);
    size_t width = CVPixelBufferGetWidthOfPlane(imageBuffer, lumaPlane);
    size_t height = CVPixelBufferGetHeightOfPlane(imageBuffer, lumaPlane);
    
    //Take Core Video pixel buffer and convert it to a openCV image matrix
    cv::Mat gray(cv::Size((int)width, (int)height), CV_8UC1, baseAddress, cv::Mat::AUTO_STEP);
    
    NSSet* faces = self.faces;
    
    for(FaceObject* face in faces) {
        CGRect bounds = [captureOutput rectForMetadataOutputRectOfInterest: face.bounds];
        
        //Probably no eyes in the bottom of the face!!
        //bounds.size.height *= 0.5;
        
        //If the face is inside the capture frame
        if( CGRectContainsRect(CGRectMake(0, 0, width, height), bounds) ) {
            
            //Cut the full image (gray) to the face rect (frame)
            cv::Rect faceRect = CVRectFromCGRect(bounds);
            
            //Draw a square around our search area
            cv::rectangle(gray, faceRect, cv::Scalar(0, 0, 0));
            
            cv::Mat faceFrame = gray(faceRect).clone();
            NSArray* eyes = [face eyesInImage:faceFrame];
            
            if( [eyes count] == 2 ) {
                if( !face.hasBeenCounted ){
                    
                    dispatch_async(dispatch_get_main_queue(), ^{
                        /*AppDelegate* delegate = (AppDelegate*)[[UIApplication sharedApplication] delegate];
                        CoreDataStack* stack = delegate.stack;
                        
                        NSManagedObjectContext* context = stack.mainQueueManagedObjectContext;
                        Customer* customer = [Customer insertInManagedObjectContext: context];
                        customer.timestamp = [NSDate date];
                        
                        NSError* error;
                        [context threadSafeSave: &error];
                        DLogError(error);
                        */
                        if( [self.delegate respondsToSelector: @selector(customerDetector:detectedCustomers:)] ) {
                            [self.delegate customerDetector: self detectedCustomers: nil];
                        }
                    });
                }
                
                face.hasBeenCounted = YES;
            }
            
            
            for(NSValue* value in eyes) {
                CGRect eyeRect = [value CGRectValue];
                eyeRect.origin.x += bounds.origin.x;
                eyeRect.origin.y += bounds.origin.y;
                
                cv::rectangle(gray, CVRectFromCGRect(eyeRect), cv::Scalar(0, 0, 0));
                
                //Find pupil
                cv::Mat eyeFrame = gray(CVRectFromCGRect(eyeRect)).clone();
                
                // http://thume.ca/projects/2012/11/04/simple-accurate-eye-center-tracking-in-opencv/
                cv::Point center = findEyeCenter(eyeFrame);
                
                int radius = eyeRect.size.height * 0.2;
                if( CGRectContainsPoint(CGRectInset(eyeRect, 10, 10), CGPointMake(center.x + eyeRect.origin.x, center.y+eyeRect.origin.y))) {
                    cv::circle(gray, cv::Point(center.x + eyeRect.origin.x, center.y + eyeRect.origin.y), radius, cv::Scalar(255,255,255));
                }
            }
        }
    }
    
    if( [self.delegate respondsToSelector: @selector(customerDetector:processedImage:)]) {
        CGImageRef cgImage = CGImageCreateFromOpenCVMatrix(&gray);
        UIImage* uiImage = [UIImage imageWithCGImage: cgImage];
        
        dispatch_async(dispatch_get_main_queue(), ^{
            [self.delegate customerDetector: self processedImage: uiImage];
        });

        CGImageRelease(cgImage);
    }
    
    
    CVPixelBufferUnlockBaseAddress(imageBuffer, 0);
}

@end
