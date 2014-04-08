//
//  CameraViewController.m
//  iSpy
//
//  Created by Paul de Lange on 8/04/2014.
//  Copyright (c) 2014 Chesterford. All rights reserved.
//

#import "CameraViewController.h"

@import AVFoundation;

@interface CameraViewController () <AVCaptureVideoDataOutputSampleBufferDelegate> {
    AVCaptureDevice*                        _frontCamera;
    AVCaptureSession*                       _captureSession;
    
    CIDetector*                             _faceDetector;
    
    AVCaptureVideoDataOutput*               _videoDataOutput;
    dispatch_queue_t                        _videoProcessingQueue;
    
    __weak AVCaptureVideoPreviewLayer*      _previewLayer;
}

@end

@implementation CameraViewController

- (void) setCaptureDevice: (AVCaptureDevice*) device {
    if( !device )
        return;
    
    for(AVCaptureInput* input in _captureSession.inputs) {
        [_captureSession removeInput: input];
    }
    
    __autoreleasing NSError* error;
    AVCaptureDeviceInput* defaultInput = [AVCaptureDeviceInput deviceInputWithDevice: device error: &error];
    NSAssert(!error, @"Error creating input device: %@", error);
    NSAssert([_captureSession canAddInput: defaultInput], @"Can not add device: %@", defaultInput);
    [_captureSession addInput: defaultInput];
}

- (void)drawFaces:(NSArray *)features
      forVideoBox:(CGRect)clearAperture
      orientation:(UIDeviceOrientation)orientation
{
    
	for ( CIFaceFeature *ff in features ) {
		
	}
}

#pragma mark - UIViewController
-(void) viewDidLoad {
    [super viewDidLoad];
    
    _captureSession = [AVCaptureSession new];
    
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
    
    _videoDataOutput = [AVCaptureVideoDataOutput new];
    NSDictionary* videoSettings = @{(id)kCVPixelBufferPixelFormatTypeKey : @(kCMPixelFormat_32BGRA)};
    
    [_videoDataOutput setVideoSettings: videoSettings];
    [_videoDataOutput setAlwaysDiscardsLateVideoFrames: YES];
    
    _videoProcessingQueue = dispatch_queue_create("VideoProcessingQueue", DISPATCH_QUEUE_SERIAL);
    
    [_videoDataOutput setSampleBufferDelegate: self queue: _videoProcessingQueue];
    
    NSAssert([_captureSession canAddOutput: _videoDataOutput], @"Can not add video output: %@", _videoDataOutput);
    
    [_captureSession addOutput: _videoDataOutput];
    
    NSDictionary* detectorOptions = @{ CIDetectorAccuracy : CIDetectorAccuracyLow };
    _faceDetector = [CIDetector detectorOfType: CIDetectorTypeFace
                                       context: nil
                                       options: detectorOptions];
    
}

- (void) viewWillAppear:(BOOL)animated {
    [super viewWillAppear: animated];
    
    [_captureSession startRunning];
}

- (void) viewDidDisappear:(BOOL)animated {
    [super viewDidDisappear: animated];
    
    [_captureSession stopRunning];
}

- (void) viewDidLayoutSubviews {
    [super viewDidLayoutSubviews];
    _previewLayer.frame = self.view.bounds;
}

#pragma mark - AVCaptureVideoDataOutputSampleBufferDelegate
- (void)captureOutput:(AVCaptureOutput *)captureOutput didOutputSampleBuffer:(CMSampleBufferRef)sampleBuffer fromConnection:(AVCaptureConnection *)connection
{
    // got an image
    CVPixelBufferRef pixelBuffer = CMSampleBufferGetImageBuffer(sampleBuffer);
    NSDictionary* attachments = (__bridge_transfer NSDictionary *)CMCopyDictionaryOfAttachments(kCFAllocatorDefault, sampleBuffer, kCMAttachmentMode_ShouldPropagate);
    
    CIImage *ciImage = [[CIImage alloc] initWithCVPixelBuffer:pixelBuffer options:attachments];
    
    /* kCGImagePropertyOrientation values
     The intended display orientation of the image. If present, this key is a CFNumber value with the same value as defined
     by the TIFF and EXIF specifications -- see enumeration of integer constants.
     The value specified where the origin (0,0) of the image is located. If not present, a value of 1 is assumed.
     
     used when calling featuresInImage: options: The value for this key is an integer NSNumber from 1..8 as found in kCGImagePropertyOrientation.
     If present, the detection will be done based on that orientation but the coordinates in the returned features will still be based on those of the image. */
    
    int exifOrientation = 6; //   6  =  0th row is on the right, and 0th column is the top. Portrait mode.
    NSDictionary *imageOptions = @{CIDetectorImageOrientation : @(exifOrientation)};
    NSArray *features = [_faceDetector featuresInImage:ciImage options:imageOptions];
	
    // get the clean aperture
    // the clean aperture is a rectangle that defines the portion of the encoded pixel dimensions
    // that represents image data valid for display.
    CMFormatDescriptionRef fdesc = CMSampleBufferGetFormatDescription(sampleBuffer);
    CGRect cleanAperture = CMVideoFormatDescriptionGetCleanAperture(fdesc, false /*originIsTopLeft == false*/);
	
    dispatch_async(dispatch_get_main_queue(), ^(void) {
        UIDeviceOrientation curDeviceOrientation = [[UIDevice currentDevice] orientation];
        
        [self drawFaces:features forVideoBox:cleanAperture orientation:curDeviceOrientation];
    });
}

@end
