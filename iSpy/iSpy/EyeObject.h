//
//  EyeObject.h
//  iSpy
//
//  Created by Paul de Lange on 11/04/2014.
//  Copyright (c) 2014 Chesterford. All rights reserved.
//

#import <Foundation/Foundation.h>

#import <opencv2/opencv.hpp>

@interface EyeObject : NSObject

@property (assign) cv::Mat capture;
@property (assign) cv::Rect bounds;
@property (assign) NSInteger lostCount;

@end
