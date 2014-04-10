//
//  CameraViewController.m
//  iSpy
//
//  Created by Paul de Lange on 8/04/2014.
//  Copyright (c) 2014 Chesterford. All rights reserved.
//

#import "CameraViewController.h"


/*
 There are two ways to do this:
 
 1. CoreImage 
    - Runs on the CPU and is slow
    + Can get eye position
    + Can get mouth position
    - Need to manually calculate angle (hasAngle always NO = bug?)
    - Need to manually track faces across frames
 
    iOS5.0+
 
 2. AVFoundation
    + Runs on the GPU and seems to be much faster
    + Easier API for developer
    + Automatically tracks faces across multiple frames
    - Can not give eye position
    - Can not get mouth position
 
    iOS6.0+
 
 
 Both methods give the face rectangle
 
 @see http://stackoverflow.com/questions/13475387/proper-usage-of-cidetectortracking
 
 @see https://github.com/unified-diff/opencv-in-your-face
 */

#define USE_CORE_IMAGE  1   //1 = use core image, 0 = use avfoundation


@import AVFoundation;

@interface CameraViewController () <
#if USE_CORE_IMAGE
AVCaptureVideoDataOutputSampleBufferDelegate
#else
AVCaptureMetadataOutputObjectsDelegate
#endif
> {
    AVCaptureDevice*                        _frontCamera;
    AVCaptureSession*                       _captureSession;
    
#if USE_CORE_IMAGE
    CIDetector*                             _faceDetector;
    
    AVCaptureVideoDataOutput*               _videoDataOutput;
    dispatch_queue_t                        _videoProcessingQueue;
#else
    AVCaptureMetadataOutput*                _metatdataOutput;
#endif
    
    __weak AVCaptureVideoPreviewLayer*      _previewLayer;
}

@property (weak, nonatomic) IBOutlet UILabel* counterLabel;

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

#if USE_CORE_IMAGE
+ (CGRect)videoPreviewBoxForGravity:(NSString *)gravity
                          frameSize:(CGSize)frameSize
                       apertureSize:(CGSize)apertureSize
{
    CGFloat apertureRatio = apertureSize.height / apertureSize.width;
    CGFloat viewRatio = frameSize.width / frameSize.height;
    
    CGSize size = CGSizeZero;
    if ([gravity isEqualToString:AVLayerVideoGravityResizeAspectFill]) {
        if (viewRatio > apertureRatio) {
            size.width = frameSize.width;
            size.height = apertureSize.width * (frameSize.width / apertureSize.height);
        } else {
            size.width = apertureSize.height * (frameSize.height / apertureSize.width);
            size.height = frameSize.height;
        }
    } else if ([gravity isEqualToString:AVLayerVideoGravityResizeAspect]) {
        if (viewRatio > apertureRatio) {
            size.width = apertureSize.height * (frameSize.height / apertureSize.width);
            size.height = frameSize.height;
        } else {
            size.width = frameSize.width;
            size.height = apertureSize.width * (frameSize.width / apertureSize.height);
        }
    } else if ([gravity isEqualToString:AVLayerVideoGravityResize]) {
        size.width = frameSize.width;
        size.height = frameSize.height;
    }
    
	CGRect videoBox;
	videoBox.size = size;
	if (size.width < frameSize.width)
		videoBox.origin.x = (frameSize.width - size.width) / 2;
	else
		videoBox.origin.x = (size.width - frameSize.width) / 2;
    
	if ( size.height < frameSize.height )
		videoBox.origin.y = (frameSize.height - size.height) / 2;
	else
		videoBox.origin.y = (size.height - frameSize.height) / 2;
    
	return videoBox;
}

- (void)drawFaces:(NSArray *)features
      forVideoBox:(CGRect)clearAperture
      orientation:(UIDeviceOrientation)orientation
       connection: (AVCaptureConnection*) connection
{
    
    static NSMutableIndexSet* countedFaces = nil;
    
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        countedFaces = [NSMutableIndexSet new];
    });
    
	NSArray *sublayers = [NSArray arrayWithArray:[_previewLayer sublayers]];
	NSInteger sublayersCount = [sublayers count], currentSublayer = 0;
	NSInteger featuresCount = [features count], currentFeature = 0;
    
	[CATransaction begin];
	[CATransaction setValue:(id)kCFBooleanTrue forKey:kCATransactionDisableActions];
    
	// hide all the face layers
	for ( CALayer *layer in sublayers ) {
		if ( [[layer name] isEqualToString:@"FaceLayer"] )
			[layer setHidden:YES];
	}
    
	if ( featuresCount == 0 ) {
		[CATransaction commit];
		return; // early bail.
	}
    
	CGSize parentFrameSize = [self.view frame].size;
	NSString *gravity = [_previewLayer videoGravity];
	BOOL isMirrored = [connection isVideoMirrored];
	CGRect previewBox = [[self class] videoPreviewBoxForGravity:gravity
                                                        frameSize:parentFrameSize
                                                     apertureSize:clearAperture.size];
    
	for ( CIFaceFeature *ff in features ) {
		// find the correct position for the square layer within the previewLayer
		// the feature box originates in the bottom left of the video frame.
		// (Bottom right if mirroring is turned on)
		CGRect faceRect = [ff bounds];
        
        if( [ff hasFaceAngle] ) {
            NSLog(@"Angle: %f", ff.faceAngle);
        }
        /*
        if( [ff hasLeftEyePosition] ) {
            NSLog(@"le: %@", NSStringFromCGPoint(ff.leftEyePosition));
        }
        
        if( [ff hasRightEyePosition] ) {
            NSLog(@"re: %@", NSStringFromCGPoint(ff.rightEyePosition));
        }
        
        if( [ff hasMouthPosition] ) {
            NSLog(@"m: %@", NSStringFromCGPoint(ff.mouthPosition));
        }*/
        
        if( [ff hasSmile] ) {
            NSLog(@"smile");
        }
        
		// flip preview width and height
		CGFloat temp = faceRect.size.width;
		faceRect.size.width = faceRect.size.height;
		faceRect.size.height = temp;
		temp = faceRect.origin.x;
		faceRect.origin.x = faceRect.origin.y;
		faceRect.origin.y = temp;
		// scale coordinates so they fit in the preview box, which may be scaled
		CGFloat widthScaleBy = previewBox.size.width / clearAperture.size.height;
		CGFloat heightScaleBy = previewBox.size.height / clearAperture.size.width;
		faceRect.size.width *= widthScaleBy;
		faceRect.size.height *= heightScaleBy;
		faceRect.origin.x *= widthScaleBy;
		faceRect.origin.y *= heightScaleBy;
        
		if ( isMirrored )
			faceRect = CGRectOffset(faceRect, previewBox.origin.x + previewBox.size.width - faceRect.size.width - (faceRect.origin.x * 2), previewBox.origin.y);
		else
			faceRect = CGRectOffset(faceRect, previewBox.origin.x, previewBox.origin.y);
        
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
        
		[featureLayer setFrame:faceRect];
        
		switch (orientation) {
			case UIDeviceOrientationPortrait:
				[featureLayer setAffineTransform:CGAffineTransformMakeRotation(0)];
				break;
			case UIDeviceOrientationPortraitUpsideDown:
				[featureLayer setAffineTransform:CGAffineTransformMakeRotation(M_PI)];
				break;
			case UIDeviceOrientationLandscapeLeft:
				[featureLayer setAffineTransform:CGAffineTransformMakeRotation(M_PI_2)];
				break;
			case UIDeviceOrientationLandscapeRight:
				[featureLayer setAffineTransform:CGAffineTransformMakeRotation(-M_PI_2)];
				break;
			case UIDeviceOrientationFaceUp:
			case UIDeviceOrientationFaceDown:
			default:
				break; // leave the layer in its last known orientation
		}
		currentFeature++;
        
        if( [ff hasTrackingID] ) {
            int faceID = ff.trackingID;
            
            if( ![countedFaces containsIndex: faceID] ) {
                NSLog(@"Counting face %d", faceID);
                
                NSParameterAssert([NSThread isMainThread]);
                
                static NSUInteger count = 0;
                
                count++;
                
                self.counterLabel.text = [@(count) stringValue];
                
                [countedFaces addIndex: faceID];
            }
            else {
                NSLog(@"Face %d tracked for %d frames", faceID, ff.trackingFrameCount);
            }
        }

	}
    
	[CATransaction commit];
}
#endif

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
    
#if USE_CORE_IMAGE
    _videoDataOutput = [AVCaptureVideoDataOutput new];
    NSDictionary* videoSettings = @{(id)kCVPixelBufferPixelFormatTypeKey : @(kCMPixelFormat_32BGRA)};
    
    [_videoDataOutput setVideoSettings: videoSettings];
    [_videoDataOutput setAlwaysDiscardsLateVideoFrames: YES];
    
    _videoProcessingQueue = dispatch_queue_create("VideoProcessingQueue", DISPATCH_QUEUE_SERIAL);
    
    [_videoDataOutput setSampleBufferDelegate: self queue: _videoProcessingQueue];
    
    NSAssert([_captureSession canAddOutput: _videoDataOutput], @"Can not add video output: %@", _videoDataOutput);
    
    [_captureSession addOutput: _videoDataOutput];
    
    NSDictionary* detectorOptions = @{
                                      CIDetectorAccuracy : CIDetectorAccuracyLow,
                                       CIDetectorTracking : @YES
                                       };
    _faceDetector = [CIDetector detectorOfType: CIDetectorTypeFace
                                       context: nil
                                       options: detectorOptions];
#else
    _metatdataOutput = [AVCaptureMetadataOutput new];
    NSAssert([_captureSession canAddOutput: _metatdataOutput], @"Can not add %@ to capture session", _metatdataOutput);
    
    [_metatdataOutput setMetadataObjectsDelegate: self queue: dispatch_get_main_queue()];
    [_captureSession addOutput: _metatdataOutput];
    NSAssert([_metatdataOutput.availableMetadataObjectTypes containsObject: AVMetadataObjectTypeFace], @"No face detection found");
    _metatdataOutput.metadataObjectTypes = @[AVMetadataObjectTypeFace];
#endif
    
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

#if USE_CORE_IMAGE
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
    NSDictionary *imageOptions = @{CIDetectorImageOrientation : @(exifOrientation) , CIDetectorEyeBlink : @YES };
    NSArray *features = [_faceDetector featuresInImage:ciImage options:imageOptions];
	
    // get the clean aperture
    // the clean aperture is a rectangle that defines the portion of the encoded pixel dimensions
    // that represents image data valid for display.
    CMFormatDescriptionRef fdesc = CMSampleBufferGetFormatDescription(sampleBuffer);
    CGRect cleanAperture = CMVideoFormatDescriptionGetCleanAperture(fdesc, false /*originIsTopLeft == false*/);
	
    dispatch_async(dispatch_get_main_queue(), ^(void) {
        UIDeviceOrientation curDeviceOrientation = [[UIDevice currentDevice] orientation];
        
        [self drawFaces:features forVideoBox:cleanAperture orientation:curDeviceOrientation connection: connection];
    });
}
#else 
#pragma mark - AVCaptureMetadataOutputObjectsDelegate
- (void)captureOutput:(AVCaptureOutput *)captureOutput didOutputMetadataObjects:(NSArray *)metadataObjects fromConnection:(AVCaptureConnection *)connection {
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
		[CATransaction commit];
		return; // early bail.
	}
    
    static NSMutableIndexSet* countedFaces = nil;
    
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        countedFaces = [NSMutableIndexSet new];
    });
    
    for ( AVMetadataObject *object in metadataObjects ) {
        if ( [[object type] isEqual:AVMetadataObjectTypeFace] ) {
            AVMetadataFaceObject* face = (AVMetadataFaceObject*)object;
            AVMetadataFaceObject * adjusted = (AVMetadataFaceObject*)[_previewLayer transformedMetadataObjectForMetadataObject:face];
            
            CGRect faceRectangle = [adjusted bounds];
            
            /*
            if( [adjusted hasRollAngle] ) {
                NSLog(@"Roll: %f", adjusted.rollAngle);
            }
            
            if( [adjusted hasYawAngle] ) {
                NSLog(@"Yaw: %f", adjusted.yawAngle);
            }*/
            
            NSParameterAssert([adjusted hasRollAngle]);
            NSParameterAssert([adjusted hasYawAngle]);
            
            if( fabs(adjusted.rollAngle) < 30 && fabs(adjusted.yawAngle) < 30 ) {
                NSInteger faceID = adjusted.faceID;
                
                if( ![countedFaces containsIndex: faceID] ) {
                    NSLog(@"Counting face %d", faceID);
                    
                    NSParameterAssert([NSThread isMainThread]);
                    
                    static NSUInteger count = 0;
                    
                    count++;
                    
                    self.counterLabel.text = [@(count) stringValue];
                    
                    [countedFaces addIndex: faceID];
                }
                else {
                    NSLog(@"Already counted face %d", faceID);
                }
            }
            
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
            
            [featureLayer setFrame:faceRectangle];
        }
    }
    
    [CATransaction commit];
}
#endif

@end
