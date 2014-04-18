//
//  CameraViewController.m
//  iSpy
//
//  Created by Paul de Lange on 8/04/2014.
//  Copyright (c) 2014 Chesterford. All rights reserved.
//

#import "CameraViewController.h"

#import "AVMetadataFaceObject+GazeTracking.h"

#import "FaceObject.h"
#import "EyeObject.h"

#include "findEyeCenter.h"

#import <opencv2/opencv.hpp>

#import <AVFoundation/AVFoundation.h>

/* Doesn't crop correctly... give up for now :(
 static CVPixelBufferRef CVPixelBufferCopyWithClipToRect(CIContext* context, CMSampleBufferRef sampleBuffer, CGRect clippingRect) {
 CVImageBufferRef imageBuffer = CMSampleBufferGetImageBuffer(sampleBuffer);
 
 NSDictionary* attachments = (__bridge_transfer NSDictionary *)CMCopyDictionaryOfAttachments(kCFAllocatorDefault,
 sampleBuffer,
 kCMAttachmentMode_ShouldPropagate);
 
 CIImage *ciImage = [[CIImage alloc] initWithCVPixelBuffer: imageBuffer options:attachments];
 NSLog(@"Crop %@ to %@", NSStringFromCGRect(ciImage.extent), NSStringFromCGRect(clippingRect));
 
 CIImage* cropped = [ciImage imageByCroppingToRect: clippingRect];
 
 size_t width = CGRectGetWidth(cropped.extent);
 size_t height = CGRectGetHeight(cropped.extent);
 
 NSDictionary* attrs = @{
 (id)kCVPixelBufferIOSurfacePropertiesKey : @{}
 //, (id)kCVPixelBufferPixelFormatTypeKey : @(kCMPixelFormat_8IndexedGray_WhiteIsZero)
 , (id)kCVPixelBufferOpenGLESCompatibilityKey : @YES
 };
 
 CVPixelBufferRef pixelBuffer;
 CVPixelBufferCreate(NULL,
 width,
 height,
 kCVPixelFormatType_32BGRA,
 (__bridge CFDictionaryRef)attrs,
 &pixelBuffer);
 
 [context render: cropped toCVPixelBuffer: pixelBuffer];
 
 return pixelBuffer;
 } */

static inline cv::Rect CVRectFromCGRect(CGRect rect) {
    return cv::Rect(rect.origin.x, rect.origin.y, rect.size.width, rect.size.height);
}

static inline NSString* NSStringFromCVRect(cv::Rect rect) {
    return [NSString stringWithFormat: @"{{%d, %d}, {%d, %d}}", rect.x, rect.y, rect.width, rect.height];
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

/*
 static cv::Mat CMSampleBufferCopyOpenCVMatrix(CMSampleBufferRef sampleBuffer, CGRect regionOfInterest) {
 cv::Rect roi = cv::Rect(regionOfInterest.origin.x, regionOfInterest.origin.y, regionOfInterest.size.width, regionOfInterest.size.height);
 
 CVImageBufferRef imageBuffer = CMSampleBufferGetImageBuffer(sampleBuffer);
 
 CVPixelBufferLockBaseAddress(imageBuffer, 0);
 
 size_t lumaPlane = 0;
 uint8_t* baseAddress = (uint8_t*)CVPixelBufferGetBaseAddressOfPlane(imageBuffer, lumaPlane);
 //size_t bytesPerRow = CVPixelBufferGetBytesPerRowOfPlane(imageBuffer, lumaPlane);
 size_t width = CVPixelBufferGetWidthOfPlane(imageBuffer, lumaPlane);
 size_t height = CVPixelBufferGetHeightOfPlane(imageBuffer, lumaPlane);
 
 cv::Mat gray(cv::Size(width, height), CV_8UC1, baseAddress, cv::Mat::AUTO_STEP);
 
 CVPixelBufferUnlockBaseAddress(imageBuffer, 0);
 
 return gray(roi).clone();
 }
 
 static CGImageRef CMSampleBufferCopyCGImageRef(CIContext* gpuContext, CMSampleBufferRef sampleBuffer, CGRect regionOfInterest) {
 if( CGSizeEqualToSize(regionOfInterest.size, CGSizeZero) )
 return nil;
 
 CVImageBufferRef imageBuffer = CMSampleBufferGetImageBuffer(sampleBuffer);
 
 CVPixelBufferLockBaseAddress(imageBuffer, 0);
 
 size_t lumaPlane = 0;
 uint8_t* baseAddress = (uint8_t*)CVPixelBufferGetBaseAddressOfPlane(imageBuffer, lumaPlane);
 size_t bytesPerRow = CVPixelBufferGetBytesPerRowOfPlane(imageBuffer, lumaPlane);
 size_t width = CVPixelBufferGetWidthOfPlane(imageBuffer, lumaPlane);
 size_t height = CVPixelBufferGetHeightOfPlane(imageBuffer, lumaPlane);
 
 cv::Mat gray(cv::Size(width, height), CV_8UC1, baseAddress, cv::Mat::AUTO_STEP);
 
 {   //Return an image
 CGColorSpaceRef colorSpace = CGColorSpaceCreateDeviceGray();
 CGBitmapInfo bitmapInfo = kCGBitmapAlphaInfoMask & kCGImageAlphaNone;
 
 CGContextRef ctx = CGBitmapContextCreate(baseAddress,
 width,
 height,
 8,
 bytesPerRow,
 colorSpace,
 bitmapInfo);
 
 CGImageRef cgImage = CGBitmapContextCreateImage(ctx);
 CGContextRelease(ctx);
 
 CGColorSpaceRelease(colorSpace);
 CVPixelBufferUnlockBaseAddress(imageBuffer, 0);
 
 CGImageRef cropped = CGImageCreateWithImageInRect(cgImage, regionOfInterest);
 CGImageRelease(cgImage);
 
 return cropped;
 }
 }*/

static AVCaptureVideoOrientation AVVideoOrientationFromUIInterfaceOrientation(UIInterfaceOrientation orientation) {
    switch (orientation) {
        case UIInterfaceOrientationLandscapeLeft:
            return AVCaptureVideoOrientationLandscapeLeft;
        case UIInterfaceOrientationLandscapeRight:
            return AVCaptureVideoOrientationLandscapeRight;
        case UIInterfaceOrientationPortrait:
            return AVCaptureVideoOrientationPortrait;
        case UIInterfaceOrientationPortraitUpsideDown:
            return AVCaptureVideoOrientationPortraitUpsideDown;
    }
}

@interface CameraViewController () <AVCaptureMetadataOutputObjectsDelegate, AVCaptureVideoDataOutputSampleBufferDelegate> {
    AVCaptureDevice*                        _frontCamera;
    AVCaptureSession*                       _captureSession;
    
    AVCaptureMetadataOutput*                _metatdataOutput;
    
    AVCaptureVideoDataOutput*               _dataOutput;
    AVCaptureConnection*                    _dataCaptureConnection;
    dispatch_queue_t                        _dataProcessingQueue;
    
    
    __weak AVCaptureVideoPreviewLayer*      _previewLayer;
    
    NSSet*                                  _faces;
}

@property (weak, nonatomic) IBOutlet UILabel* counterLabel;
@property (weak, nonatomic) IBOutlet UIImageView *faceImageView;

@end

@implementation CameraViewController

- (void) setCaptureDevice: (AVCaptureDevice*) device {
    if( !device )
        return;
    
    for(AVCaptureInput* input in _captureSession.inputs) {
        [_captureSession removeInput: input];
    }
    
    /*
    AVCaptureDeviceFormat* bestFormat = device.activeFormat;
    
    for(AVCaptureDeviceFormat* format in device.formats) {
        
        if( format.videoFieldOfView >  bestFormat.videoFieldOfView ) {
            bestFormat = format;
        }
    }
    
    if( [device lockForConfiguration: NULL] ) {
        device.activeFormat = bestFormat;
        
        [device unlockForConfiguration];
    }
    
    NSLog(@"Setting video format %@", device.activeFormat);
    */
    __autoreleasing NSError* error;
    AVCaptureDeviceInput* defaultInput = [AVCaptureDeviceInput deviceInputWithDevice: device error: &error];
    NSAssert(!error, @"Error creating input device: %@", error);
    NSAssert([_captureSession canAddInput: defaultInput], @"Can not add device: %@", defaultInput);
    [_captureSession addInput: defaultInput];
}

#pragma mark - NSObject
- (instancetype) initWithCoder:(NSCoder *)aDecoder {
    self = [super initWithCoder: aDecoder];
    if( self ) {
        _dataProcessingQueue = dispatch_queue_create("Data Processing", DISPATCH_QUEUE_SERIAL);
    }
    
    return self;
}

#pragma mark - UIViewController
-(void) viewDidLoad {
    [super viewDidLoad];
    
    NSString* preset = AVCaptureSessionPresetHigh;
    _captureSession = [AVCaptureSession new];
    NSParameterAssert([_captureSession canSetSessionPreset: preset]);
    _captureSession.sessionPreset = preset;
    
    AVCaptureVideoPreviewLayer* layer = [[AVCaptureVideoPreviewLayer alloc] initWithSession: _captureSession];
    [layer setVideoGravity: AVLayerVideoGravityResizeAspect];
    
    [self.view.layer insertSublayer: layer atIndex: 0];
    _previewLayer = layer;
    
    for(AVCaptureDevice* device in [AVCaptureDevice devicesWithMediaType: AVMediaTypeVideo]) {
        if( device.position == AVCaptureDevicePositionFront ) {
            _frontCamera = device;
            break;
        }
    }
    
    [self setCaptureDevice: _frontCamera];
    
    _metatdataOutput = [AVCaptureMetadataOutput new];
    
    
    NSAssert([_captureSession canAddOutput: _metatdataOutput], @"Can not add %@ to capture session", _metatdataOutput);
    
    [_metatdataOutput setMetadataObjectsDelegate: self queue: dispatch_get_main_queue()];
    [_captureSession addOutput: _metatdataOutput];
    
    NSAssert([_metatdataOutput.availableMetadataObjectTypes containsObject: AVMetadataObjectTypeFace], @"No face recognition on this device");
    
    _metatdataOutput.metadataObjectTypes = @[AVMetadataObjectTypeFace];
    
    _dataOutput = [AVCaptureVideoDataOutput new];
    _dataOutput.videoSettings = @{
                                  (id)kCVPixelBufferPixelFormatTypeKey : @(kCVPixelFormatType_420YpCbCr8BiPlanarFullRange)
                                  };
    _dataOutput.alwaysDiscardsLateVideoFrames = YES;
    
    [_dataOutput setSampleBufferDelegate: self queue: _dataProcessingQueue];
    NSAssert([_captureSession canAddOutput: _dataOutput], @"Can not add %@ to capture session", _dataOutput);
    [_captureSession addOutput: _dataOutput];
    _dataCaptureConnection = [_dataOutput connectionWithMediaType: AVMediaTypeVideo];
    _dataCaptureConnection.videoOrientation = AVVideoOrientationFromUIInterfaceOrientation([[UIApplication sharedApplication] statusBarOrientation]);
    
    NSParameterAssert(_dataCaptureConnection);
}

- (void) viewWillAppear:(BOOL)animated {
    [super viewWillAppear: animated];
    
    [_captureSession startRunning];
}

- (void) viewDidDisappear:(BOOL)animated {
    [super viewDidDisappear: animated];
    
    [_captureSession stopRunning];
    _faces = nil;
}

- (void) viewDidLayoutSubviews {
    [super viewDidLayoutSubviews];
    _previewLayer.frame = self.view.bounds;
}

- (void) willRotateToInterfaceOrientation:(UIInterfaceOrientation)toInterfaceOrientation duration:(NSTimeInterval)duration {
    _dataCaptureConnection.videoOrientation = AVVideoOrientationFromUIInterfaceOrientation(toInterfaceOrientation);
}

#pragma mark - AVCaptureVideoDataOutputSampleBufferDelegate
- (void)captureOutput:(AVCaptureOutput *)captureOutput didOutputSampleBuffer:(CMSampleBufferRef)sampleBuffer fromConnection:(AVCaptureConnection *)connection {
    NSParameterAssert(![NSThread isMainThread]);
    
    @autoreleasepool {
    
    CVImageBufferRef imageBuffer = CMSampleBufferGetImageBuffer(sampleBuffer);
    
    //Images are coming in YUV format, the first channel is the intensity (luma)...
    size_t lumaPlane = 0;
    
    CVPixelBufferLockBaseAddress(imageBuffer, 0);
    
    uint8_t* baseAddress = (uint8_t*)CVPixelBufferGetBaseAddressOfPlane(imageBuffer, lumaPlane);
    size_t width = CVPixelBufferGetWidthOfPlane(imageBuffer, lumaPlane);
    size_t height = CVPixelBufferGetHeightOfPlane(imageBuffer, lumaPlane);
    
    //Take Core Video pixel buffer and convert it to a openCV image matrix
    cv::Mat gray(cv::Size((int)width, (int)height), CV_8UC1, baseAddress, cv::Mat::AUTO_STEP);
    
    //Go through all faces
    for(FaceObject* face in [_faces copy]) {
        
        //If the face was looking at the camera
        if( face.isFacingCamera ) {
            
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
                    if( CGRectContainsPoint(CGRectInset(eyeRect, 10, 10), CGPointMake(center.x + eyeRect.origin.x, center.y+eyeRect.origin.y)))
                        cv::circle(gray, cv::Point(center.x + eyeRect.origin.x, center.y + eyeRect.origin.y), radius, cv::Scalar(255,255,255));
                     
                }
            }
        }
    }
    
    //Convert openCV back to an Core Graphics
    CGImageRef cgImage = CGImageCreateFromOpenCVMatrix(&gray);
    UIImage* uiImage = [UIImage imageWithCGImage: cgImage];
    CGImageRelease(cgImage);
    
    CVPixelBufferUnlockBaseAddress(imageBuffer, 0);
    
    //On the main thread update the preview view
    dispatch_async(dispatch_get_main_queue(), ^{
        self.faceImageView.image = uiImage;
    });
    }
}

#pragma mark - AVCaptureMetadataOutputObjectsDelegate
- (void)captureOutput:(AVCaptureOutput *)captureOutput didOutputMetadataObjects:(NSArray *)metadataObjects fromConnection:(AVCaptureConnection *)connection {
    //NSParameterAssert(connection.videoPreviewLayer == _previewLayer);
    NSParameterAssert([NSThread isMainThread]);
    
    @autoreleasepool {
        
    [CATransaction begin];
	[CATransaction setValue:(id)kCFBooleanTrue forKey:kCATransactionDisableActions];
    
    NSArray *sublayers = [NSArray arrayWithArray:[_previewLayer sublayers]];
	NSInteger sublayersCount = [sublayers count], currentSublayer = 0;
    
	// hide all the face layers
	for ( CALayer *layer in sublayers ) {
		if ( [[layer name] isEqualToString:@"FaceLayer"] )
			[layer setHidden:YES];
	}
    
	if ( metadataObjects.count == 0 ) {
        _faces = nil;
		[CATransaction commit];
		return; // early bail.
	}
    
    NSMutableSet* facesToSave = [NSMutableSet set];
    
    for ( AVMetadataObject *object in metadataObjects ) {
        if ( [[object type] isEqual:AVMetadataObjectTypeFace] ) {
            AVMetadataFaceObject* face = (AVMetadataFaceObject*)object;
            
            FaceObject* aFaceObject;
            NSSet* trackedAndMatchingFaces = [_faces filteredSetUsingPredicate: [NSPredicate predicateWithFormat: @"foundationID = %d", face.faceID]];
            aFaceObject = trackedAndMatchingFaces.anyObject;
            
            if( !aFaceObject ) {
                
                NSInteger currentCount = [self.counterLabel.text integerValue];
                currentCount++;
                self.counterLabel.text = [@(currentCount) stringValue];
                
                aFaceObject = [FaceObject new];
                aFaceObject.foundationID = face.faceID;
            }
            
            AVMetadataFaceObject * adjusted = (AVMetadataFaceObject*)[_previewLayer transformedMetadataObjectForMetadataObject:face];
            aFaceObject.bounds = [face bounds];
            aFaceObject.isFacingCamera = YES;//face.isFacingCamera;
            
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
                [_previewLayer addSublayer:featureLayer];
                featureLayer = nil;
            }
            
            [featureLayer setFrame: [adjusted bounds]];
            [facesToSave addObject: aFaceObject];
        }
    }
    
    _faces = [facesToSave copy];
    
    [CATransaction commit];
    }
}

@end
