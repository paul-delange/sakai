//
//  CameraViewController.m
//  iSpy
//
//  Created by Paul de Lange on 8/04/2014.
//  Copyright (c) 2014 Chesterford. All rights reserved.
//

#import "CameraViewController.h"


/*
 @see https://github.com/unified-diff/opencv-in-your-face
 */


#import <opencv2/opencv.hpp>
#import <opencv2/highgui/cap_ios.h>
#import <AVFoundation/AVFoundation.h>

//const int HaarOptions = CV_HAAR_FIND_BIGGEST_OBJECT | CV_HAAR_DO_ROUGH_SEARCH;

/**
 * Function to detect human face and the eyes from an image.
 *
 * @param  im    The source image
 * @param  tpl   Will be filled with the eye template, if detection success.
 * @param  rect  Will be filled with the bounding box of the eye
 * @return zero=failed, nonzero=success
 */
int detectEye(cv::CascadeClassifier* face_cascade, cv::CascadeClassifier* eye_cascade, cv::Mat& im, cv::Mat& tpl, cv::Rect& rect)
{
	std::vector<cv::Rect> faces, eyes;
	face_cascade->detectMultiScale(im, faces, 1.1, 2, 0|CV_HAAR_SCALE_IMAGE, cv::Size(30,30));
    
	for (int i = 0; i < faces.size(); i++)
	{
		cv::Mat face = im(faces[i]);
		eye_cascade->detectMultiScale(face, eyes, 1.1, 2, 0|CV_HAAR_SCALE_IMAGE, cv::Size(20,20));
        
		if (eyes.size())
		{
			rect = eyes[0] + cv::Point(faces[i].x, faces[i].y);
			tpl  = im(rect);
		}
	}
    
	return eyes.size();
}

/**
 * Perform template matching to search the user's eye in the given image.
 *
 * @param   im    The source image
 * @param   tpl   The eye template
 * @param   rect  The eye bounding box, will be updated with the new location of the eye
 */
void trackEye(cv::Mat& im, cv::Mat& tpl, cv::Rect& rect)
{
	cv::Size size(rect.width * 2, rect.height * 2);
	cv::Rect window(rect + size - cv::Point(size.width/2, size.height/2));
    
	window &= cv::Rect(0, 0, im.cols, im.rows);
    
	cv::Mat dst(window.width - tpl.rows + 1, window.height - tpl.cols + 1, CV_32FC1);
	cv::matchTemplate(im(window), tpl, dst, CV_TM_SQDIFF_NORMED);
    
	double minval, maxval;
	cv::Point minloc, maxloc;
	cv::minMaxLoc(dst, &minval, &maxval, &minloc, &maxloc);
    
	if (minval <= 0.2)
	{
		rect.x = window.x + minloc.x;
		rect.y = window.y + minloc.y;
	}
	else
		rect.x = rect.y = rect.width = rect.height = 0;
}


@interface CameraViewController () <CvVideoCameraDelegate> {
    CvVideoCamera* _videoCamera;
    cv::CascadeClassifier   faceClassifier;
    cv::CascadeClassifier   eyeClassifier;
    
    cv::Mat eye_tpl;
	cv::Rect eye_bb;
}

@property (weak, nonatomic) IBOutlet UILabel* counterLabel;

@end

@implementation CameraViewController

#pragma mark - NSObject
- (instancetype) initWithCoder:(NSCoder *)aDecoder {
    self = [super initWithCoder: aDecoder];
    if( self ) {
        NSString* classiferPath = [[NSBundle mainBundle] pathForResource: @"haarcascade_frontalface_alt2" ofType: @"xml"];
        faceClassifier.load([classiferPath UTF8String]);

        classiferPath = [[NSBundle mainBundle] pathForResource: @"haarcascade_eye" ofType: @"xml"];
        eyeClassifier.load([classiferPath UTF8String]);
    }
    
    return self;
}

#pragma mark - UIViewController
-(void) viewDidLoad {
    [super viewDidLoad];
    
    _videoCamera = [[CvVideoCamera alloc] initWithParentView: self.view];
    _videoCamera.defaultAVCaptureDevicePosition = AVCaptureDevicePositionFront;
    _videoCamera.defaultAVCaptureSessionPreset = AVCaptureSessionPreset352x288;
    _videoCamera.defaultAVCaptureVideoOrientation = AVCaptureVideoOrientationPortrait;
    _videoCamera.defaultFPS = 30;
    _videoCamera.grayscaleMode = NO;
    _videoCamera.delegate = self;
}

- (void) viewWillAppear:(BOOL)animated {
    [super viewWillAppear: animated];
    
    [_videoCamera start];
}

- (void) viewDidDisappear:(BOOL)animated {
    [super viewDidDisappear: animated];
    
    [_videoCamera stop];
}


#pragma mark - CvVideoCameraDelegate
- (void)processImage:(cv::Mat&)image {
    
    cv::Mat tmpMat;
    UIDeviceOrientation orientation = [UIDevice currentDevice].orientation;
    BOOL isInLandScapeMode = NO;
    BOOL rotation = 1;
    
    //Rotate cv::Mat to the portrait orientation
    if(orientation == UIDeviceOrientationLandscapeRight)
    {
        isInLandScapeMode = YES;
        rotation = 1;
    }
    else if(orientation == UIDeviceOrientationLandscapeLeft)
    {
        isInLandScapeMode = YES;
        rotation = 0;
    }
    else if(orientation == UIDeviceOrientationPortraitUpsideDown)
    {
        cv::transpose(image, tmpMat);
        cv::flip(tmpMat, image, rotation);
        cv::transpose(image, tmpMat);
        cv::flip(tmpMat, image, rotation);
        cvtColor(image, image, CV_BGR2BGRA);
        cvtColor(image, image, CV_BGR2RGB);
    }
    
    if(isInLandScapeMode)
    {
        cv::transpose(image, tmpMat);
        cv::flip(tmpMat, image, rotation);
        cvtColor(image, image, CV_BGR2BGRA);
        cvtColor(image, image, CV_BGR2RGB);
    }
    
    cv::Mat gray;
    cvtColor(image, gray, CV_BGR2GRAY);
    //equalizeHist(grayscaleFrame, grayscaleFrame);
    
    if (eye_bb.width == 0 && eye_bb.height == 0)
    {
        // Detection stage
        // Try to detect the face and the eye of the user
        detectEye(&faceClassifier, &eyeClassifier, gray, eye_tpl, eye_bb);
    }
    else
    {
        // Tracking stage with template matching
        trackEye(gray, eye_tpl, eye_bb);
        
        // Draw bounding rectangle for the eye
        cv::rectangle(image, eye_bb, CV_RGB(0,255,0));
    }
    
    
    if(isInLandScapeMode)
    {
        cv::transpose(image, tmpMat);
        cv::flip(tmpMat, image, !rotation);
        cvtColor(image, image, CV_BGR2RGB);
        
    }
    
    else if(orientation == UIDeviceOrientationPortraitUpsideDown)
    {
        cv::transpose(image, tmpMat);
        cv::flip(tmpMat, image, !rotation);
        cv::transpose(image, tmpMat);
        cv::flip(tmpMat, image, !rotation);
        cvtColor(image, image, CV_BGR2RGB);
    }
}

@end
